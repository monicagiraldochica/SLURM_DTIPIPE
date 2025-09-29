#!/bin/bash
#SBATCH --job-name=finaldtifit
#SBATCH --time=00:05:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3gb
#SBATCH --array=1-48%10
#SBATCH --partition=bigmem
set -e
set -u
STARTTIME=$(date +%s)

module load ants
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

scratch=scratch
mapfile -t subjects < list.txt
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess="${sbj}_1"
bvecs=data/bvecs
bvals=data/bvals
data=data/data.nii.gz
mask=data/nodif_brain_mask.nii.gz
diffDir=data/dtifit

echo "Running finaldtifit on ${sbj}: ${sess}"
cd "${scratch}/${sbj}/${sess}"

dtifit --data=$data --out=$diffDir/dti --mask=$mask --bvecs=$bvecs --bvals=$bvals --wls
echo -e "\nDONE finaldtifit"

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
