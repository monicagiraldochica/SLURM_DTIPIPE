#!/bin/bash
#SBATCH --job-name=3dmask
#SBATCH --time=00:05:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem-per-cpu=3gb
#SBATCH --array=1-48%10
#SBATCH --chdir=/scratch/g/mygroup/mydir
#SBATCH --begin=18:00:00 # begin job in 18hrs
#SBATCH --constraint=<req_node_features>
#SBATCH --dependency=<state:jobID>
#SBATCH --exclude=<hostNames_exclude_from_jobAlloc>
#SBATCH --input=<name> # file from which to read job input data
#SBATCH --nodelist=<names> # specific host names to include in job allocation
#SBATCH --output=<name> # store job output
#SBATCH --partition=normal
set -e
set -u
STARTTIME=$(date +%s)

echo "${SLURM_JOB_ID} ${SLURM_SUBMIT_DIR} ${SLURM_SUBMIT_HOST} ${SLURM_JOB_NODELIST} ${SLURM_ARRAY_TASK_ID}"

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