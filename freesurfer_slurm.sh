#!/bin/bash
#SBATCH --job-name=freesurfer
#SBATCH --time=10:00:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=7gb
#SBATCH --array=1-48%10
#SBATCH --chdir=/scratch/g/mygroup/mydir
set -e
set -u
SECONDS=0

module load freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

mapfile -t subjects < list.txt
(( SLURM_ARRAY_TASK_ID <= ${#subjects[@]} )) || exit 0
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
printf "\nTotal execution time: %02d:%02d:%02d (hh:mm:ss)\n" $((SECONDS/3600)) $((SECONDS/60%60)) $((SECONDS%60))