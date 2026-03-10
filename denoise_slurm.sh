#!/bin/bash
#SBATCH --job-name=denoise
#SBATCH --time=24:00:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10gb
#SBATCH --partition=bigmem
#SBATCH --array=1-48%10
set -e
set -u
STARTTIME=$(date +%s)

module load ants
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.shc

scratch=scratch
cd "${scratch}"
mapfile -t subjects < list.txt
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