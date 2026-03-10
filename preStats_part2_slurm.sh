#!/bin/bash
#SBATCH --job-name=preStats_part2
#SBATCH --time=00:05:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3gb
#SBATCH --array=1-48%10
set -e
set -u

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

scratch=scratch
cd "${scratch}/${sbj}/${sess}"
mapfile -t subjects < list.txt
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess="${sbj}_1"
echo "Running PreStats Part2 on ${sbj}: ${sess}"

tbss_name=tbss_name
python3 preStatsPart2.py ${tbss_name}