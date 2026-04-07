#!/bin/bash
#SBATCH --job-name=anat_graph
#SBATCH --time=50:00:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=5gb
#SBATCH --array=1-48%10
#SBATCH --chdir=/scratch/g/mygroup/mydir
set -e
set -u
SECONDS=0

module load python

mapfile -t subjects < list.txt
(( SLURM_ARRAY_TASK_ID <= ${#subjects[@]} )) || exit 0
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess="${sbj}_1"

echo "Running anat_graph on ${sbj}: ${sess}"
python3 disp_res.py --sbj="${sbj}" --sess=day1 --pipe=dsi --sbj_path="${sbj}_${sess}_anat_graph" --location=hpc
echo "DONE anat_graph"

# Compute execution time
printf "\nTotal execution time: %02d:%02d:%02d (hh:mm:ss)\n" $((SECONDS/3600)) $((SECONDS/60%60)) $((SECONDS%60))