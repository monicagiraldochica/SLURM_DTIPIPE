#!/bin/bash
#SBATCH --job-name=finaldtifit
#SBATCH --time=00:05:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3gb
#SBATCH --array=1-48%10
#SBATCH --partition=bigmem
#SBATCH --chdir=/scratch/g/mygroup/mydir
set -e
set -u
SECONDS=0

module load ants
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

mapfile -t subjects < list.txt
(( SLURM_ARRAY_TASK_ID <= ${#subjects[@]} )) || exit 0
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess="${sbj}_1"
echo "Running final_dtifit on ${sbj}: ${sess}"

datadir="${sbj}_${sess}/data"
bvecs="${datadir}"/bvecs
bvals="${datadir}"/bvals
data="${datadir}"/data.nii.gz
mask="${datadir}"/nodif_brain_mask.nii.gz
diffDir="${datadir}"/dtifit

dtifit --data="${data}" --out="${diffDir}"/dti --mask="${mask}" --bvecs="${bvecs}" --bvals="${bvals}" --wls
echo -e "\nDONE finaldtifit"

# Compute execution time
printf "\nTotal execution time: %02d:%02d:%02d (hh:mm:ss)\n" $((SECONDS/3600)) $((SECONDS/60%60)) $((SECONDS%60))