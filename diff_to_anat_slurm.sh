#!/bin/bash
#SBATCH --job-name=diff_to_anat
#SBATCH --time=00:05:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3gb
#SBATCH --array=1-48%10
#SBATCH --chdir=/scratch/g/mygroup/mydir
set -e
set -u
SECONDS=0

mapfile -t subjects < list.txt
(( SLURM_ARRAY_TASK_ID <= ${#subjects[@]} )) || exit 0
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess="${sbj}_1"
echo "Running diff_to_anat on ${sbj}: ${sess}"

maindir="${sbj}_${sess}"
surf="${maindir}/surf"
brain="${surf}"/T1w_brain.nii.gz

datadir="${maindir}/data"
data="${datadir}"/data.nii.gz
mask="${datadir}"/nodif_brain_mask.nii.gz
nodif_brain="${datadir}"/nodif_brain.nii.gz

fslmaths "${data}" -mul "${mask}" "${nodif_brain}"
flirt -in "${nodif_brain}" -ref "${brain}" -out "${surf}"/nodif_toAnat -omat "${surf}"/nodif_toAnat.mat -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12  -interp trilinear
echo "DONE diff_to_anat"

# Compute execution time
printf "\nTotal execution time: %02d:%02d:%02d (hh:mm:ss)\n" $((SECONDS/3600)) $((SECONDS/60%60)) $((SECONDS%60))