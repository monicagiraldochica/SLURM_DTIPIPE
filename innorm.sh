#!/bin/bash
#SBATCH --job-name=innorm
#SBATCH --time=00:20:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=5gb
set -e
STARTTIME=$(date +%s)

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

sbj=sbj
sess=sess
scratch=scratch/$sbj/$sess
cd $scratch
mkdir -p preEddy

echo "Running innorm on ${sbj}: ${sess}"
declare -A dic=(["75_AP"]="AP_1" ["76_AP"]="AP_2" ["75_PA"]="PA_1" ["76_PA"]="PA_2")

echo -e "\nCopying preEddy files"
for ddir in "75_AP" "75_PA" "76_AP" "76_PA"
do
        inprefix="${sbj}_3T_DWI_dir${ddir}"
        [ ! -f $inprefix.nii.gz ] && continue
	echo ${dic[$ddir]}
	outprefix=preEddy/${dic[$ddir]}
	for suffix in ".nii.gz" ".bval" ".bvec"
	do
		cp ${inprefix}${suffix} ${outprefix}${suffix}
	done
done

echo -e "\nFor each series, get the mean b0 and rescale to match the first series baseline"
num_entry=0
for entry in preEddy/PA_1 preEddy/PA_2 preEddy/AP_1 preEddy/AP_2
do
	[ ! -f $entry.nii.gz ] && continue
	echo $entry

	# Get the mean value of each volume
	mean=${entry}_mean
	fslmaths $entry -Xmean -Ymean -Zmean $mean

	# Extract all b0s for the series
	bvals=$(cat $entry.bval)
	i=0
	for bval in ${bvals}
	do
		n=$(zeropad $i 4)
		[ $bval -eq 0 ] && fslroi ${mean} ${entry}_b0_${n} ${i} 1
		i=$(( $i + 1 ))
	done

	# Merge B0s
	fslmerge -t $mean ${entry}_b0_????.nii.gz

	# This is the mean baseline b0 intensity for the series
	fslmaths $mean -Tmean $mean
	imrm ${entry}_b0_????.nii.gz

	# Do not rescale the first series, just save the scaling value
	# For the rest, replace the original dataseries with the rescaled one
	if [ $num_entry -eq 0 ]
	then
		# First series, do not rescale
		resc=$(fslmeants -i $mean)
	else
		# Rescale
		sc=$(fslmeants -i $mean)
		fslmaths $entry -mul $resc -div $sc $entry
	fi

	# Make sure no negatives crept in
	fslmaths $entry -thr 0.00001 $entry
	
	imrm $mean
	num_entry=$(( $num_entry + 1 ))
done
echo "DONE innorm"

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
