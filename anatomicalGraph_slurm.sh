#!/bin/bash
#SBATCH --job-name=anat_graph
#SBATCH --time=50:00:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=5gb
#SBATCH --array=1-48%10
set -e
set -u
STARTTIME=$(date +%s)

module load python

scratch=scratch
cd "${scratch}"
mapfile -t subjects < list.txt
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess="${sbj}_1"

echo "Running anat_graph on ${sbj}: ${sess}"
python3 disp_res.py --sbj="${sbj}" --sess=day1 --pipe=dsi --sbj_path="${sbj}_${sess}_anat_graph" --location=hpc
echo "DONE anat_graph"

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