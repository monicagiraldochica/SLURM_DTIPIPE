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
STARTTIME=$(date +%s)

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

subjects=($(cat list.txt))
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
cd $sbj

echo "Running bedpostx on ${sbj}"
bedpostx_gpu data
echo "DONE bedpostx"

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
echo "Total execution time was ${DUR_H} hrs ${DUR_M} mins ${DUR_S} secs"
