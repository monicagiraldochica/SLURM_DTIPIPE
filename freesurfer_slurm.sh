#!/bin/bash
#SBATCH --job-name=freesurfer
#SBATCH --time=10:00:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=7gb
#SBATCH --array=1-48%10
set -e
set -u
STARTTIME=$(date +%s)

module load freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

scratch=scratch
cd "${scratch}"
mapfile -t subjects < list.txt
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess="${sbj}_1"
echo "Running Freesurfer on ${sbj}: ${sess}"

recon-all -sd "${sbj}_${sess}" -s "${sess}" -i T1w_brain.nii.gz -noskullstrip -all

surfdir="${sbj}_${sess}/surf"
mris_convert "${surfdir}"/lh.pial "${surfdir}"/lh.pial.surf.gii &
mris_convert "${surfdir}"/rh.pial "${surfdir}"/rh.pial.surf.gii &
mris_convert "${surfdir}"/lh.smoothwm "${surfdir}"/lh.smoothwm.surf.gii &
mris_convert "${surfdir}"/rh.smoothwm "${surfdir}"/rh.smoothwm.surf.gii

echo "DONE freesurfer"

# Compute execution time
FINISHTIME=$(date +%s)
TOTDURATION_S=$((FINISHTIME - STARTTIME))
DURATION_H=$((TOTDURATION_S / 3600))
REMAINDER_S=$((TOTDURATION_S - (3600*DURATION_H)))
DURATION_M=$((REMAINDER_S / 60))
DURATION_S=$((REMAINDER_S - (60*DURATION_M)))
DUR_H=$(printf "%02d" ${DURATION_H})
DUR_M=$(printf "%02d" ${DURATION_M})
DUR_S=$(printf "%02d" ${DURATION_S})
echo -e "\nTotal execution time was ${DUR_H} hrs ${DUR_M} mins ${DUR_S} secs"