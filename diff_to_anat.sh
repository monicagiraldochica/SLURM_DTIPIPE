#!/bin/bash
#SBATCH --job-name=diff_to_anat
#SBATCH --time=00:05:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3gb
#SBATCH --array=1-48%10
set -e
set -u
STARTTIME=$(date +%s)

scratch=scratch
subjects=($(cat $scratch/list.txt))
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess=${sbj}_1
echo "Running diff_to_anat on ${sbj}: ${sess}"
cd $scratch/$sbj/$ses

brain=surf/T1w_brain.nii.gz
data=data/data.nii.gz
mask=data/nodif_brain_mask.nii.gz
nodif_brain=data/nodif_brain.nii.gz

fslmaths $data -mul $mask $nodif_brain

flirt -in $nodif_brain -ref $brain -out surf/nodif_toAnat -omat surf/nodif_toAnat.mat -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12  -interp trilinear

echo "DONE diff_to_anat"

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
