#!/bin/bash
#SBATCH --job-name=3dmask
#SBATCH --time=00:05:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3gb
set -e
set -u
STARTTIME=$(date +%s)

echo "Starting job at $(date)"
echo "Job name: ${SLURM_JOB_NAME}, Job ID: ${SLURM_JOB_ID}"
echo "I have ${SLURM_CPUS_ON_NODE} CPUs on compute node $(hostname -s)"

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

sbj=sbj
sess=sess
cd scratch/$sbj/$sess

echo "Running 3dmask on ${sbj}: ${sess}"
for ddir in "75_AP" "75_PA" "76_AP" "76_PA"
do
	prefix="${sbj}_3T_DWI_dir${ddir}"
	[ ! -f $prefix.nii.gz ] && continue
	echo $prefix

	# Extract the first volume
	fslroi $prefix ${prefix}_b0 0 -1 0 -1 0 -1 0 1

	# Extract using FSL
	bet ${prefix}_b0 ${prefix}_bet -f 0.1 -g 0 -n -m

	# Extract using AFNI
	3dSkullStrip -input ${prefix}_b0 -prefix ${prefix}_skstrip
done

echo "DONE 3dmask"
echo "Ending job at $(date)"

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
