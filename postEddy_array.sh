#!/bin/bash
#SBATCH --job-name=postEddy
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=5gb
#SBATCH --array=1-48%10
#SBATCH --account=account
set -e

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

scratch=scratch
subjects=($(cat $scratch/list.txt))
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess=${sbj}_1
echo "Running postEddy on ${sbj}: ${sess}"
cd $scratch

python3 postEddy.py $sbj $sess $step
