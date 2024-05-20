#!/bin/bash
#SBATCH --job-name=dtifitQC
#SBATCH --time=00:05:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4gb
set -e
STARTTIME=$(date +%s)

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

sbj=sbj
sess=sess
scratch=scratch/$sbj/$sess
cd $scratch
mkdir -p dtifit

echo "Running dtifitQC on ${sbj}: ${sess}"
for ddir in "75_AP" "75_PA" "76_AP" "76_PA"
do
        prefix="${sbj}_3T_DWI_dir${ddir}"
        [ ! -f $prefix.nii.gz ] && continue
        echo $prefix
	output="dtifit/dti_${ddir}"
	dtifit --data=$prefix --out=$output --mask=${prefix}_bet_mask --bvecs=$prefix.bvec --bvals=$prefix.bval
done
echo "DONE dtifitQC"

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
