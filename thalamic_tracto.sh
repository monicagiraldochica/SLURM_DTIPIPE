#!/bin/bash
#BATCH --job-name=thalamicTracto
#SBATCH --time=15:00:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem-per-cpu=25gb
#SBATCH --partition=bigmem
#SBATCH --array=2-48%10
#SBATCH --chdir=/scratch/g/mygroup/mydir

set -e
set -u
STARTTIME=$(date +%s)

module load ants
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

mapfile -t subjects < list.txt
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess="${sbj}_1"
outdir="${sbj}/${sess}"

echo -e "Running thalamic tractography on ${sbj} ${sess}\n"
cd "$outdir"

REFERENCE=fa.nii.gz
AFFINE=fa2tomAffine.txt
INVWARP=fa2tomInverseWarp.nii.gz
ATLAS=BN_Atlas_274_combined.nii.gz
SBJ_ATLAS=BN_Atlas_274_combined.nii.gz
RH=RightHemisphere.nii.gz
SBJ_RH=RightHemisphere.nii.gz
RGM=RightGM.nii.gz
SBJ_RGM=RightGM.nii.gz
LH=LeftHemisphere.nii.gz
SBJ_LH=LeftHemisphere.nii.gz
LGM=LeftGM.nii.gz
SBJ_LGM=LeftGM.nii.gz

# Transform masks for exclusion and atlas to subject space
declare -A dic_transf=(["${ATLAS}"]="${SBJ_ATLAS}"
			["${RH}"]="${SBJ_RH}"
			["${RGM}"]="${SBJ_RGM}"
			["${LH}"]="${SBJ_LH}"
			["${LGM}"]="${SBJ_LGM}")
for orig in "${!dic_transf[@]}"; do
	target=${dic_transf[$orig]}
	if [ ! -f "$target" ]; then
		cmd="WarpImageMultiTransform 3 ${orig} ${target} -i ${AFFINE} ${INVWARP} -R ${REFERENCE} --use-NN"
		echo "$cmd"
		eval "$cmd" &
	fi
done
wait

# Create the ROI
if [ ! -f LeftPreFrontalCortex.nii.gz ] || [ ! -f RightPreFrontalCortex.nii.gz ] || [ ! -f LeftPreFrontalThalamus.nii.gz ] || [ ! -f RightPreFrontalThalamus.nii.gz ]
then
	declare -A dic_vals=(["LeftAnteriorCingulate"]="179,187"
			     ["RightAnteriorCingulate"]="180,188"
			     ["LeftRegion2"]="41,43,45,47,49,51"
			     ["RightRegion2"]="42,44,46,48,50,52"
			     ["LeftRegion3"]="29,31,33,35,37,39"
			     ["RightRegion3"]="30,32,34,36,38,40"
			     ["LeftMiddleFrontal"]="15,17,19,21,23,25,27"
			     ["RightMiddleFrontal"]="16,18,20,22,24,26,28"
			     ["LeftSuperiorFrontal"]="1,3,5,7,9,11,13"
			     ["RightSuperiorFrontal"]="2,4,6,8,10,12,14"
			     ["LeftMedialPreFrontalThalamus"]="231"
			     ["RightMedialPreFrontalThalamus"]="232"
			     ["LeftLateralPreFrontalThalamus"]="245"
			     ["RightLateralPreFrontalThalamus"]="246")

	for roi in "${!dic_vals[@]}"; do
		IFS=',' read -a -r array <<< "${dic_vals[$roi]}"

		for val in "${array[@]}"; do
			output="tmp${roi}_${val}.nii.gz"

			if [ ! -f "${output}" ]; then
				cmd="fslmaths ${SBJ_ATLAS} -thr ${val} -uthr ${val} ${output}"
				echo "$cmd"
				eval "$cmd" &
			fi
		done
	done
	wait

	for roi in "${!dic_vals[@]}"; do
		if [ ! -f "$roi".nii.gz ]; then
			cmd="fslmaths"

			for subroi in tmp"$roi"*; do
				cmd="${cmd} ${subroi} -add"
			done
			cmd="${cmd::-5} -bin ${roi}"

			echo "$cmd"
			eval "$cmd" &
		fi
	done
	wait

	Lcmd_cortex="fslmaths"
	Rcmd_cortex="fslmaths"
	Lcmd_thal="fslmaths"
	Rcmd_thal="fslmaths"
	for roi in "${!dic_vals[@]}"; do
		[[ $roi == Left* ]] && [[ $roi != *Thalamus ]] && Lcmd_cortex="${Lcmd_cortex} ${roi} -add"
		[[ $roi == Right* ]] && [[ $roi != *Thalamus ]] && Rcmd_cortex="${Rcmd_cortex} ${roi} -add"
		[[ $roi == Left* ]] && [[ $roi == *Thalamus ]] && Lcmd_thal="${Lcmd_thal} ${roi} -add"
	        [[ $roi == Right* ]] && [[ $roi == *Thalamus ]] && Rcmd_thal="${Rcmd_thal} ${roi} -add"
	done

	Lcmd_cortex="${Lcmd_cortex::-5} -bin LeftPreFrontalCortex"
	Rcmd_cortex="${Rcmd_cortex::-5} -bin RightPreFrontalCortex"
	Lcmd_thal="${Lcmd_thal::-5} -bin LeftPreFrontalThalamus"
	Rcmd_thal="${Rcmd_thal::-5} -bin RightPreFrontalThalamus"
	for cmd in "$Lcmd_cortex" "$Rcmd_cortex" "$Lcmd_thal" "$Rcmd_thal"; do
		IFS=' ' read -a -r array <<< "$cmd"
		outroi="${array[-1]}.nii.gz"
		[ ! -f "$outroi" ] && echo "$cmd" && eval "$cmd" &
	done
	wait
fi

# Create exclusion masks
for roi in "LeftPreFrontalCortex" "RightPreFrontalCortex" "LeftAnteriorCingulate" "RightAnteriorCingulate" "LeftRegion2" "RightRegion2" "LeftRegion3" "RightRegion3" "LeftMiddleFrontal" "RightMiddleFrontal" "LeftSuperiorFrontal" "RightSuperiorFrontal"; do
	excl="${roi}_excl"
	if [ ! -f $excl.nii.gz ]; then
		[[ $roi == Left* ]] && cmd="fslmaths RightHemisphere -add LeftGM -sub ${roi} -bin ${excl}" || cmd="fslmaths LeftHemisphere -add RightGM -sub ${roi} -bin ${excl}"
		echo "$cmd"
		eval "$cmd" &
	fi
done
wait

# Run tractography
MERGED="data.bedpostX/merged"
MASK="data.bedpostX/nodif_brain_mask.nii.gz"
for hem in "Left" "Right"
do
        for seed_roi in "PreFrontalThalamus" "MedialPreFrontalThalamus" "LateralPreFrontalThalamus"
        do
		for target_roi in "PreFrontalCortex" "AnteriorCingulate" "Region2" "Region3" "MiddleFrontal" "SuperiorFrontal"
		do
			SEED="${hem}${seed_roi}.nii.gz"
			TARGET="${hem}${target_roi}.nii.gz"
			AVOID="${hem}${target_roi}_excl.nii.gz"
			output="${hem}_${seed_roi}2${target_roi}"
			[ -d $output ] && [ -f $output/fdt_paths.nii.gz ] && [ -f $output/waytotal ] && continue
			rm -rf $output
			cmd="probtrackx2 -x ${SEED} -l --modeuler --onewaycondition -c 0.2 -S 2000 --steplength=0.5 -P 5000 --fibthresh=0.01 --distthresh=0.0 --sampvox=0.0 --forcedir --opd -s ${MERGED} -m ${MASK} --dir=${output} --stop=${TARGET} --targetmasks=${TARGET} --avoid=${AVOID}"

			echo $cmd
			eval $cmd &
		done
	done
done
wait

rm -f tmp*
echo "DONE thalamicTracto"

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