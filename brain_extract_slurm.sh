#!/bin/bash
#SBATCH --job-name=3dmask
#SBATCH --time=00:05:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem-per-cpu=3gb
#SBATCH --array=1-48%10
#SBATCH --chdir=/scratch/g/mygroup/mydir
set -e
set -u
SECONDS=0

module load fsl/6.0.4
module load afni
module load freesurfer
#PATH=${FSLDIR}/bin:$PATH
#. ${FSLDIR}/etc/fslconf/fsl.sh

mapfile -t subjects < list.txt
(( SLURM_ARRAY_TASK_ID <= ${#subjects[@]} )) || exit 0
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess="${sbj}_1"

files=()
for ddir in "75_AP" "75_PA" "76_AP" "76_PA"
do
        img="${sbj}/${sess}/${sbj}_3T_DWI_dir${ddir}.nii.gz"
        [ ! -f "${img}" ] && continue
        files+=("${img}")
done
[ ${#files[@]} -eq 0 ] && exit 0

echo "Running brain_extract on ${sbj}: ${sess}: $(IFS=,; echo "${files[*]}")"
python3 dtilib.py --extract "$(IFS=,; echo "${files[*]}")" --all-soft --max-procs "${SLURM_CPUS_PER_TASK}" --mask4D

# Compute execution time
printf "\nTotal execution time: %02d:%02d:%02d (hh:mm:ss)\n" $((SECONDS/3600)) $((SECONDS/60%60)) $((SECONDS%60))