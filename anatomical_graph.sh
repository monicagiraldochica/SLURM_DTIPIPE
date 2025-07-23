#!/bin/bash
#SBATCH --job-name="anat_graph"
#SBATCH --time=50:00:00
#SBATCH --account=jbinder
#SBATCH --mem-per-cpu=5gb
set -e
STARTTIME=$(date +%s)
module load python
pip3 install networkx

projDir=/scratch/u/mkeith/iPadStudy
cd $projDir
SUBJECTS=($(cat sbj_list.txt))
sbj=${SUBJECTS[PBS_ARRAYID-1]}

echo "Running anat_graph on ${sbj}..."
python3 disp_res.py --sbj=$sbj --sess=day1 --pipe=dsi --sbj_path=${sbj}_day1 --location=hpc
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
