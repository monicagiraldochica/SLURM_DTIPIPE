#!/bin/bash
#SBATCH --job-name=3dmask
#SBATCH --time=00:05:00
#SBATCH --account=account
#SBATCH --ntasks=12
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3gb
#SBATCH --array=1-48%10
#SBATCH --chdir=/scratch/g/mygroup/mydir
set -e
set -u
STARTTIME=$(date +%s)

module load fsl/6.0.4
module load afni
module load freesurfer
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

mapfile -t subjects < list.txt
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
echo "Running 3dmask on ${sbj}"

pid_array=()
for ddir in "75_AP" "75_PA" "76_AP" "76_PA"
do
        prefix="${sbj}_3T_DWI_dir${ddir}"
        [ ! -f "${prefix}".nii.gz ] && continue
        echo "${prefix}"

	# Extract the first volume
        fslroi "${prefix}" "${prefix}_b0" 0 -1 0 -1 0 -1 0 1

        # Extract using FSL
        bet "${prefix}_b0" "${prefix}_bet" -f 0.1 -g 0 -n -m &
	pid_array[${#pid_array[@]}]=$!

        # Extract using AFNI
        3dSkullStrip -input "${prefix}_b0" -prefix "${prefix}_skstrip".nii.gz &
	pid_array[${#pid_array[@]}]=$!

        # Extract using Freesurfer
        mri_synthstrip -i "${prefix}_b0".nii.gz -o "${prefix}_stripped".nii.gz &
	pid_array[${#pid_array[@]}]=$!
done

wait "${pid_array[@]}"
echo "DONE 3dmask"

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