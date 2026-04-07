#!/bin/bash
#SBATCH --job-name=dtifitQC
#SBATCH --time=00:05:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4gb
#SBATCH --array=1-48%10
#SBATCH --chdir=/scratch/g/mygroup/mydir
set -e
set -u
SECONDS=0

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

mapfile -t subjects < list.txt
(( SLURM_ARRAY_TASK_ID <= ${#subjects[@]} )) || exit 0
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess="${sbj}_1"
echo "Running dtifitQC on ${sbj}: ${sess}"

for ddir in "75_AP" "75_PA" "76_AP" "76_PA"
do
        prefix="${sbj}_${sess}/${sbj}_3T_DWI_dir${ddir}"
        [ ! -f "${prefix}".nii.gz ] && continue
        echo "${prefix}"
        output="${sbj}_${sess}/dtifit/dti_${ddir}"
        dtifit --data="${prefix}" --out="${output}" --mask="${prefix}_bet_mask" --bvecs="${prefix}.bvec" --bvals="${prefix}.bval"
done
echo "DONE dtifitQC"

# Compute execution time
printf "\nTotal execution time: %02d:%02d:%02d (hh:mm:ss)\n" $((SECONDS/3600)) $((SECONDS/60%60)) $((SECONDS%60))