#!/bin/bash
#SBATCH --job-name=topup
#SBATCH --time=02:00:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=5gb
set -e
set -u
STARTTIME=$(date +%s)

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

sbj=sbj
sess=sess
scratch=scratch/$sbj/$sess
cd $scratch/topup

topup_config_file=$FSLDIR/etc/flirtsch/b02b0.cnf
echo "Running topup on ${sbj}: ${sess}"

# imain has the first b0 of each series (4 in total if all series exist for the subject)
# Should generate these files:
# Pos_Neg_b0.topup_log
# topup_Pos_Neg_b0_fieldcoef.nii.gz: contains spline coefficients defining the field
# topup_Pos_Neg_b0_movpar.txt: each line contains the movement parameters for each volume of imain (4 lines if all series exist for the subject)
echo -e "\n1. Run topup"
topup --imain=Pos_Neg_b0 --datain=acqparams.txt --config=${topup_config_file} --out=topup_Pos_Neg_b0 -v

# Apply topup to get a hifi b0 (used to create the nodif_brain_mask)
# Only the first b0 of 75PA (positive) and the first b0 of 75AP (negative) is used
# Unless one of 75 series is missing, then should use the two 76 series
# PA is called positive because when I go from posterior of the brain to anterior of the brain the value of Y increases
# So it is acquired in the positive way of the axis
# Including both 75 and 76 would led to averaging across data acquired with different diffusion gradients which is not valid
# the hifib0 output will have one volume and the size of the series
echo -e "\n2. Define indices to apply topup"
dimt=$(cat acqparams.txt | wc -l)
if [ $dimt -eq 4 ]
then
	echo "All series present"
	index="1,3"
elif [ $dimt -eq 2 ]
then
	echo "Two series present"
	index="1,2"
elif [ $dimt -eq 3 ] && [ ! -f AP_2.nii.gz ]
then
	echo "Missing AP_2. Use 75 series."
	index="1,3"
elif [ $dimt -eq 3 ] && [ ! -f PA_2.nii.gz ]
then
	echo "Missing PA_2. Use 75 series."
        index="1,2"
elif [ $dimt -eq 3 ] && [ ! -f AP_1.nii.gz ]
then
        echo "Missing AP_1. Use 76 series."
	index="2,3"
elif [ $dimt -eq 3 ] && [ ! -f PA_1.nii.gz ]
then
        echo "Missing PA_1. Use 76 series"
	index="1,3"
else
	echo "ERROR: Number of series: ${dimt}."
	exit 1
fi
echo "Indices: ${index}"

echo -e "\n3. Apply topup"
fslroi Pos_b0 Pos_b01 0 1
fslroi Neg_b0 Neg_b01 0 1
applytopup --imain=Pos_b01,Neg_b01 --topup=topup_Pos_Neg_b0 --datain=acqparams.txt --inindex=$index --out=hifib0

echo -e "\n4. Generate nodif brain mask"
bet hifib0 nodif_brain -n -m -f 0.2
echo "DONE topup"

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
