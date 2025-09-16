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
. ${FSLDIR}/etc/fslconf/fsl.sh

scratch=scratch
subjects=($(cat ${scratch}/list.txt))
sbj="${subjects[SLURM_ARRAY_TASK_ID-1]}"
sess="${sbj}_1"
echo "Running denoise on ${sbj}: ${sess}"
cd "${scratch}/${sbj}/${sess}"

data=data/data.nii.gz
output=data/data_ds.nii.gz
mask=data/nodif_brain_mask.nii.gz
mask4d=data/nodif_brain_mask_4d.nii.gz
rm -rf $mask4d $output

echo "generating 4d file"
nvols=$(fslval $data dim4)
cmd="fslmerge -tr ${mask4d}"
for i in $(seq $nvols)
do
	cmd="${cmd} ${mask}"
done
eval $cmd

echo "denoising image"
DenoiseImage -d 4 -i $data -o $output -x $mask4d -v -r 1

echo "masking result"
fslmaths $output -mul $mask -thr 0.00001 $output

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