#!/bin/bash
#SBATCH --job-name=3dmask
#SBATCH --time=00:01:00
#SBATCH --account=account
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3gb
#SBATCH --array=1-48%10
#SBATCH --chdir=/scratch/g/mygroup/mydir
set -e
set -u
STARTTIME=$(date +%s)

module load python/3.9.1
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

# Each line of list.txt is of the form sbj_sess
subjects=($(cat list.txt))
sessdir=${subjects[SLURM_ARRAY_TASK_ID-1]}
IFS='_' read -a info2 <<< "${sessdir}"
sess=${info2[1]}
echo "Running 3dmask on ${sess}"

python3 3dmask_DB_parallel.py $sess $sessdir
echo "DONE 3dmask"

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
