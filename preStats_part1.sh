#!/bin/bash
#SBATCH --job-name=preStats_part1
#SBATCH --time=00:05:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=3gb
#SBATCH --array=1-48%10
set -e
set -u

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

scratch=scratch
mapfile -t subjects < list.txt
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
tbss_name=tbss_name
FSLSTD=$FSLDIR/data/standard

for img in FA MD
do
	python3 preStatsPart1.py $tbss_name $img $scratch $FSLSTD &
done
wait
