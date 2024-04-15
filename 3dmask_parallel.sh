#!/bin/bash
#SBATCH --job-name=3dmask
#SBATCH --time=00:01:00
#SBATCH --account=jbinder
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3gb
set -e
STARTTIME=$(date +%s)

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

sbj=EC1116
sess=EC1116_1
scratch=/scratch/g/jbinder/mkeith/ECP/$sbj/$sess
cd $scratch

echo "Running 3dmask on ${sbj}: ${sess}"
for ddir in "75_AP" "75_PA" "76_AP" "76_PA"
do
	prefix="${sbj}_3T_DWI_dir${ddir}"
	[ ! -f $prefix.nii.gz ] && continue
	echo $prefix &&
	fslroi $prefix ${prefix}_b0 0 -1 0 -1 0 -1 0 1 &&
	bet ${prefix}_b0 ${prefix}_bet -f 0.1 -g 0 -n -m &
done

wait
echo "DONE 3dmask"

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
