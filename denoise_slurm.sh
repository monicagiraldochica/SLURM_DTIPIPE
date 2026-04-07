#!/bin/bash
#SBATCH --job-name=denoise
#SBATCH --time=24:00:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10gb
#SBATCH --partition=bigmem
#SBATCH --array=1-48%10
#SBATCH --chdir=/scratch/g/mygroup/mydir
set -e
set -u
SECONDS=0

module load ants
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.shc

mapfile -t subjects < list.txt
(( SLURM_ARRAY_TASK_ID <= ${#subjects[@]} )) || exit 0
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess="${sbj}_1"
echo "Running Denoise on ${sbj}: ${sess}"

datadir="${sbj}_${sess}/data"
data="${datadir}"/data.nii.gz
output="${datadir}"/data_ds.nii.gz
mask="${datadir}"/nodif_brain_mask.nii.gz
mask4d="${datadir}"/nodif_brain_mask_4d.nii.gz
rm -rf "${mask4d}" "${output}"

echo "Generating 4D file"
nvols=$(fslval $data dim4)
cmd="fslmerge -tr ${mask4d}"
for i in $(seq "${nvols}")
do
	cmd="${cmd} ${mask}"
	eval "${cmd}"
done

echo "Denoising image"
DenoiseImage -d 4 -i "${data}" -o "${output}" -x "${mask4d}" -v -r 1

echo "Masking result"
fslmaths "${output}" -mul "${mask}" -thr 0.00001 "${output}"

echo -e "\nDONE denoise"

# Compute execution time
printf "\nTotal execution time: %02d:%02d:%02d (hh:mm:ss)\n" $((SECONDS/3600)) $((SECONDS/60%60)) $((SECONDS%60))