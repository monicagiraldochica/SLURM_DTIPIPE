#!/bin/bash
#SBATCH --job-name=thalamicSeg
#SBATCH --time=04:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem-per-cpu=10gb
#SBATCH --partition=bigmem
#SBATCH --array=1-48%10
#SBATCH --account=account
set -e
STARTTIME=$(date +%s)

module load ants
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

scratch=scratch
subjects=($(cat $scratch/list.txt))
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess=${sbj}_1
echo "Running thalamic segmentation on ${sbj} ${sess}"
outdir=$scratch/$sbj/$sess
cd $scratch

# Transform FA to Brainnetome space
INPUT=$outdir/fa.nii.gz
REFERENCE=HCP40_MNI_1.25mm.nii.gz
OUTPUT=$outdir/fa2tom
AFFINE=${OUTPUT}Affine.txt
WARP=${OUTPUT}Warp.nii.gz
INVWARP=${OUTPUT}InverseWarp.nii.gz

cmd="ANTS 3 -m CC[${REFERENCE},${INPUT},1,5] -o ${OUTPUT}.nii.gz -r Gauss[2,0] -t SyN[0.25] -i 30x99x11 --use-Histogram-Matching"
echo $cmd
eval $cmd

cmd="WarpImageMultiTransform 3 ${INPUT} ${OUTPUT}.nii.gz -R ${REFERENCE} ${WARP} ${AFFINE}"
echo $cmd
eval $cmd

# Apply inverse transformation to each of the ROI
declare -a roi_array=("Frontal" "Motor" "Somatosensory" "Occipital" "Parietal" "Temporal")

for hem in "Left" "Right"
do
	for roi in ${roi_array[@]} "GM" "Hemisphere" "Tha_Thalamus"
	do
		MASK="${hem}${roi}.nii.gz"
		OUT_MASK="${outdir}/${MASK}"
		cmd="WarpImageMultiTransform 3 ${MASK} ${OUT_MASK} -i ${AFFINE} ${INVWARP} -R ${REFERENCE} --use-NN"

		echo $cmd
		eval $cmd &
	done
done
wait

# Create the exclusion masks
for hem in "Left" "Right"
do
        for roi in ${roi_array[@]}
	do
		[ "${hem}" == "Left" ] && avd_hem="Right" || avd_hem="Left"
		gm="${hem}GM"
		AVOID="${outdir}/${avd_hem}Hemisphere+${gm}-${roi}"
		cmd="fslmaths ${outdir}/${avd_hem}Hemisphere -add ${outdir}/${gm} -sub ${outdir}/${hem}${roi} -bin ${AVOID}"

		echo $cmd
		eval $cmd &
	done
done
wait

# Run tractography
MERGED="${outdir}/data.bedpostX_v4/merged"
MASK="${outdir}/nodif_brain_mask.nii.gz"
for hem in "Left" "Right"
do
        for roi in ${roi_array[@]}
        do
                [ "${hem}" == "Left" ] && avd_hem="Right" || avd_hem="Left"
                gm="${hem}GM"
                AVOID="${outdir}/${avd_hem}Hemisphere+${gm}-${roi}"
		SEED="${outdir}/${hem}Tha_Thalamus.nii.gz"
		TARGET="${outdir}/${hem}${roi}.nii.gz"
		output="${outdir}/${hem}Thal2${roi}"
		cmd="probtrackx2 -x ${SEED} -l --modeuler --onewaycondition -c 0.2 -S 2000 --steplength=0.5 -P 5000 --fibthresh=0.01 --distthresh=0.0 --sampvox=0.0 --forcedir --opd -s ${MERGED} -m ${MASK} --dir=${output} --avoid=${AVOID} --stop=${TARGET} --os2t --targetmasks=${TARGET}"

		echo $cmd
		eval $cmd &
	done
done
wait

# Segment the thalamus in 6 subregions per hemisphere according to its anatomical connectivity
output="${outdir}/Biggest"
mkdir $output
for hem in "Left" "Right"
do
        cmd="find_the_biggest"
	for roi in ${roi_array[@]}
	do
		cmd="${cmd} ${outdir}/${hem}Thal2${roi}/seeds_to_${hem}${roi}"
	done
	cmd="${cmd} ${output}/${hem}"
	echo $cmd
	eval $cmd &
done
wait

for hem in "Left" "Right"
do
	for ((i=1; i<=6; i+=1))
	do
		cmd="fslmaths ${output}/${hem} -thr ${i} -uthr ${i} ${output}/${hem}_${roi_array[$i-1]}"
		echo $cmd
		eval $cmd &
	done
done
wait

echo "DONE thalamicSeg"

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
