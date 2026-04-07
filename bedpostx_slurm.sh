#!/bin/bash
#SBATCH --job-name=bedpostx
#SBATCH --ntasks=3
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=7gb
#SBATCH --partition=gpu
#SBATCH --gres=gpu:v100:1
#SBATCH --time=168:00:00
#SBATCH --account=account
#SBATCH --array=1-48%10
#SBATCH --chdir=/scratch/g/mygroup/mydir
set -e
set -u
SECONDS=0

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

mapfile -t subjects < list.txt
(( SLURM_ARRAY_TASK_ID <= ${#subjects[@]} )) || exit 0
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess="${sbj}_1"

echo "Running BedpostX on ${sbj}: ${sess}"
bedpostx_gpu "${sbj}_${sess}/data"
echo "DONE bedpostx"

# Compute execution time
printf "\nTotal execution time: %02d:%02d:%02d (hh:mm:ss)\n" $((SECONDS/3600)) $((SECONDS/60%60)) $((SECONDS%60))