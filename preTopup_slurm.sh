#!/bin/bash
#SBATCH --job-name=preTopup
#SBATCH --time=00:20:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=15gb
#SBATCH --partition=bigmem
set -e
set -u
STARTTIME=$(date +%s)

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

scratch=scratch
cd "${scratch}"
mapfile -t subjects < list.txt
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess="${sbj}_1"
echo "Running pre-TopUp on ${sbj}: ${sess}"

# 1. Calculate the total readout time in seconds
# Using ES=0.494 in all. This number is supposed to not matter as long as it is constant
ES=0.494
any=$(ls "${sbj}_${sess}"/preEddy/??_?.nii.gz | head -n1)
dimP=$(fslval "${any}" dim2)
nPEsteps=$((${dimP} - 1))
# Total readout time is defined as the time from the centre of the first echo to the centre of the last in seconds
ro_time=$(echo "${ES} * ${nPEsteps}" | bc -l)
ro_time=$(echo "scale=6; ${ro_time} / 1000" | bc -l)
echo "readout time: ${ro_time}"

# 2. Extract positive (PA) b0s and create index and acquisition parameters files
# topup definition of positive is given by increasing indices into the image file
echo -e "\nExtracting positive b0s..."
rm -f "${sbj}_${sess}"/preEddy/index.txt "${sbj}_${sess}"/preEddy/acqparams.txt
entry_index=1
for i in 1 2
do
	entry="${sbj}_${sess}/preEddy/PA_${i}"
	if [ -f "${entry}".nii.gz ]
	then
		echo "PA_${i}"

		# Extract first b0
		n=$(( "${i}" - 1 ))
		fslroi "${entry}" "${sbj}_${sess}/preEddy/Pos_b0_000${n}" 0 1

		# For each bval (volume), write an entry in the index file
		IFS=' ' read -a ARRAY <<< "$(cat "${entry}".bval)"
		for bval in "${ARRAY[@]}"; do echo ${entry_index} >> "${sbj}_${sess}"/preEddy/index.txt; done		
		((entry_index++))

		# Write the corresponding line for the entry in the acqparams file
		# There is a non-zero value only in the second column, indicating that phase encoding is performed in the y-direction (typically corresponding to the A<->P)
		echo 0 1 0 "${ro_time}" >> "${sbj}_${sess}"/preEddy/acqparams.txt
	fi
done

# 3. Extract the negative (AP) b0s and continue writing the index and acquisition parameters files
echo "\nExtracting negative b0s..."
for i in 1 2
do
	entry="${sbj}_${sess}/preEddy/AP_${i}"
	if [ -f "${entry}".nii.gz ]
	then
		echo "AP_${i}"

		# Extract first b0
		n=$(( $i - 1 ))
		fslroi "${entry}" "${sbj}_${sess}/preEddy/Neg_b0_000${n}" 0 1

		# For each bval (volume), write an entry in the index file
		IFS=' ' read -a ARRAY <<< "$(cat "${entry}".bval)"
		for bval in "${ARRAY[@]}"; do echo "${entry_index}" >> "${sbj}_${sess}"/preEddy/index.txt; done
		((entry_index++))

	 	# Write the corresponding line for the entry in the acqparams file
		echo 0 -1 0 "${ro_time}" >> "${sbj}_${sess}"/preEddy/acqparams.txt
	fi
done

# 4. Merge files and correct number of slices (remove one to get an even number if necessary)
rm -rf topup
mkdir topup

# Merge positive b0s and correct z dim
if [ -f preEddy/Pos_b0_0000.nii.gz ] || [ -f preEddy/Pos_b0_0001.nii.gz ] 
then
	echo -e "\nMerging positive b0s and correcting zdim..."
	fslmerge -t "${sbj}_${sess}"/topup/Pos_b0 preEddy/Pos_b0_000?.nii.gz
	dimz=$(fslval "${sbj}_${sess}"/topup/Pos_b0 dim3)
	[ $(( $dimz % 2 )) -eq 1 ] && fslroi "${sbj}_${sess}"/topup/Pos_b0 topup/Pos_b0 0 -1 0 -1 1 -1
	echo "done"
fi

# Merge negative b0s and correct z dim
if [ -f preEddy/Neg_b0_0000.nii.gz ] || [ -f preEddy/Neg_b0_0001.nii.gz ]
then
	echo -e "\nMerging negative b0s and correcting zdim..."
        fslmerge -t "${sbj}_${sess}"/topup/Neg_b0 preEddy/Neg_b0_000?.nii.gz
	dimz=$(fslval "${sbj}_${sess}"/topup/Neg_b0 dim3)
	[ $(( $dimz % 2 )) -eq 1 ] && fslroi "${sbj}_${sess}"/topup/Neg_b0 topup/Neg_b0 0 -1 0 -1 1 -1
	echo "done"
fi

# Merge positive & negative b0s
if [ -f topup/Pos_b0.nii.gz ] && [ -f topup/Neg_b0.nii.gz ]
then
	echo -e "\nMerging positive and negative b0s..."
	fslmerge -t "${sbj}_${sess}"/topup/Pos_Neg_b0 topup/Pos_b0 topup/Neg_b0
elif [ -f topup/Pos_b0.nii.gz ]
then
	echo -e "\nNo negative b0s, copying the positive as Pos_Neg_b0..."
	cp "${sbj}_${sess}"/topup/Pos_b0.nii.gz "${sbj}_${sess}"/topup/Pos_Neg_b0.nii.gz
elif [ -f topup/Neg_b0.nii.gz ]
then
	echo -e "\nNo positive b0s, copying the negative as Pos_Neg_b0..."
	cp "${sbj}_${sess}"/topup/Neg_b0.nii.gz "${sbj}_${sess}"/topup/Pos_Neg_b0.nii.gz
fi

# Merge positive files and correct z dim
rm -rf eddy
mkdir eddy

if [ -f preEddy/PA_1.nii.gz ] || [ -f preEddy/PA_2.nii.gz ]
then
	echo -e "\nMerging positive files and correcting zdim..."

	fslmerge -t "${sbj}_${sess}"/eddy/Pos preEddy/PA_?.nii.gz
	dimz=$(fslval "${sbj}_${sess}"/eddy/Pos dim3)
	[ $(( $dimz % 2 )) -eq 1 ] && fslroi "${sbj}_${sess}"/eddy/Pos eddy/Pos 0 -1 0 -1 1 -1

	if [ -f preEddy/PA_1.nii.gz ] && [ -f preEddy/PA_2.nii.gz ]
	then
		paste -d ' ' "${sbj}_${sess}"/preEddy/PA_1.bval "${sbj}_${sess}"/preEddy/PA_2.bval >> "${sbj}_${sess}"/eddy/Pos.bval
		paste -d ' ' "${sbj}_${sess}"/preEddy/PA_1.bvec "${sbj}_${sess}"/preEddy/PA_2.bvec >> "${sbj}_${sess}"/eddy/Pos.bvec
	elif [ -f preEddy/PA_1.nii.gz ]
	then
		cp "${sbj}_${sess}"/preEddy/PA_1.bval "${sbj}_${sess}"/eddy/Pos.bval
		cp "${sbj}_${sess}"/preEddy/PA_1.bvec "${sbj}_${sess}"/eddy/Pos.bvec
	else
		cp "${sbj}_${sess}"/preEddy/PA_2.bval "${sbj}_${sess}"/eddy/Pos.bval
		cp "${sbj}_${sess}"/preEddy/PA_2.bvec "${sbj}_${sess}"/eddy/Pos.bvec
	fi
fi

# Merge negative files and correct z dim
if [ -f preEddy/AP_1.nii.gz ] || [ -f preEddy/AP_2.nii.gz ]
then
	echo -e "\nMerging negative files and correcting zdim..."

        fslmerge -t "${sbj}_${sess}"/eddy/Neg preEddy/AP_?.nii.gz
	dimz=$(fslval "${sbj}_${sess}"/eddy/Neg dim3)
	[ $(( $dimz % 2 )) -eq 1 ] && fslroi "${sbj}_${sess}"/eddy/Neg eddy/Neg 0 -1 0 -1 1 -1

	if [ -f preEddy/AP_1.nii.gz ] && [ -f preEddy/AP_2.nii.gz ]
	then
		paste -d ' ' "${sbj}_${sess}"/preEddy/AP_1.bval "${sbj}_${sess}"/preEddy/AP_2.bval >> "${sbj}_${sess}"/eddy/Neg.bval
		paste -d ' ' "${sbj}_${sess}"/preEddy/AP_1.bvec "${sbj}_${sess}"/preEddy/AP_2.bvec >> "${sbj}_${sess}"/eddy/Neg.bvec
	elif [ -f preEddy/AP_1.nii.gz ]
	then
		cp "${sbj}_${sess}"/preEddy/AP_1.bval "${sbj}_${sess}"/eddy/Neg.bval
		cp "${sbj}_${sess}"/preEddy/AP_1.bvec "${sbj}_${sess}"/eddy/Neg.bvec
	else
		cp "${sbj}_${sess}"/preEddy/AP_2.bval "${sbj}_${sess}"/eddy/Neg.bval
		cp "${sbj}_${sess}"/preEddy/AP_2.bvec "${sbj}_${sess}"/eddy/Neg.bvec
	fi
fi

# Merge positive and negative files
if [ -f eddy/Pos.nii.gz ] && [ -f eddy/Neg.nii.gz ]
then
	echo -e "\nMerging positive and negative files..."
	fslmerge -t "${sbj}_${sess}"/eddy/Pos_Neg "${sbj}_${sess}"/eddy/Pos eddy/Neg
	paste -d ' ' "${sbj}_${sess}"/eddy/Pos.bval "${sbj}_${sess}"/eddy/Neg.bval >> "${sbj}_${sess}"/eddy/Pos_Neg.bval
	paste -d ' ' "${sbj}_${sess}"/eddy/Pos.bvec "${sbj}_${sess}"/eddy/Neg.bvec >> "${sbj}_${sess}"/eddy/Pos_Neg.bvec
elif [ -f eddy/Pos.nii.gz ]
then
	echo -e "\nCopying positive files as Pos_Neg (negative series missing)..."
	cp "${sbj}_${sess}"/eddy/Pos.nii.gz "${sbj}_${sess}"/eddy/Pos_Neg.nii.gz
	cp "${sbj}_${sess}"/eddy/Pos.bval "${sbj}_${sess}"/eddy/Pos_Neg.bval
	cp "${sbj}_${sess}"/eddy/Pos.bvec "${sbj}_${sess}"/eddy/Pos_Neg.bvec
elif [ -f eddy/Neg.nii.gz ]
then
	echo -e "\nCopying negative files as Pos_Neg (positive series missing)..."
	cp "${sbj}_${sess}"/eddy/Neg.nii.gz "${sbj}_${sess}"/eddy/Pos_Neg.nii.gz
	cp "${sbj}_${sess}"/eddy/Neg.bval "${sbj}_${sess}"/eddy/Pos_Neg.bval
	cp "${sbj}_${sess}"/eddy/Neg.bvec "${sbj}_${sess}"/eddy/Pos_Neg.bvec
fi

mv "${sbj}_${sess}"/preEddy/index.txt "${sbj}_${sess}"/preEddy/acqparams.txt eddy/
cp "${sbj}_${sess}"/eddy/acqparams.txt "${sbj}_${sess}"/topup/
echo "DONE preTopup"

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