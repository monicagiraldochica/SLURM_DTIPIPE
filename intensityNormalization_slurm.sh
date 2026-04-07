#!/bin/bash
#SBATCH --job-name=innorm
#SBATCH --time=00:20:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=5gb
#SBATCH --array=1-48%10
#SBATCH --chdir=/scratch/g/mygroup/mydir
set -e
set -u
SECONDS=0

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

mapfile -t subjects < list.txt
(( SLURM_ARRAY_TASK_ID <= ${#subjects[@]} )) || exit 0
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess="${sbj}_1"
echo "Running Intensity Normalization on ${sbj}: ${sess}"

mkdir -p preEddy
declare -A dic=(["75_AP"]="AP_1" ["76_AP"]="AP_2" ["75_PA"]="PA_1" ["76_PA"]="PA_2")

echo -e "\nCopying preEddy files"
for ddir in "75_AP" "75_PA" "76_AP" "76_PA"
do
        inprefix="${sbj}_${sess}/${sbj}_3T_DWI_dir${ddir}"
        [ ! -f "${inprefix}".nii.gz ] && continue
        echo "${dic[$ddir]}"
        outprefix="${sbj}_${sess}/preEddy/${dic[$ddir]}"
        for suffix in ".nii.gz" ".bval" ".bvec"
        do
                cp "${inprefix}${suffix}" "${outprefix}${suffix}"
        done
done

echo -e "\nFor each series, get the mean b0 and rescale to match the first series baseline"
num_entry=0
for entry in "${sbj}_${sess}"/preEddy/PA_1 "${sbj}_${sess}"/preEddy/PA_2 "${sbj}_${sess}"/preEddy/AP_1 "${sbj}_${sess}"/preEddy/AP_2
do
        [ ! -f "${entry}".nii.gz ] && continue
        echo "${entry}"

        # Get the mean value of each volume
        mean="${entry}_mean"
        fslmaths "${entry}" -Xmean -Ymean -Zmean "${mean}"

        # Extract all b0s for the series
        bvals=$(cat "${entry}".bval)
        i=0
        for bval in ${bvals}
        do
                n=$(zeropad $i 4)
                [ "${bval}" -eq 0 ] && fslroi "${mean}" "${entry}_b0_${n}" ${i} 1
                i=$(( "${i}" + 1 ))
        done

        # Merge B0s
        fslmerge -t "${mean}" "${entry}"_b0_????.nii.gz

        # This is the mean baseline b0 intensity for the series
        fslmaths "${mean}" -Tmean "${mean}"
        imrm "${entry}"_b0_????.nii.gz

        # Do not rescale the first series, just save the scaling value
        # For the rest, replace the original dataseries with the rescaled one
        if [ "${num_entry}" -eq 0 ]
        then
                # First series, do not rescale
                resc=$(fslmeants -i "${mean}")
        else
                # Rescale
                sc=$(fslmeants -i "${mean}")
                fslmaths "${entry}" -mul "${resc}" -div "${sc}" "${entry}"
        fi

        # Make sure no negatives crept in
        fslmaths "${entry}" -thr 0.00001 "${entry}"

        imrm "${mean}"
        num_entry=$(( "${num_entry}" + 1 ))
done
echo "DONE innorm"

# Compute execution time
printf "\nTotal execution time: %02d:%02d:%02d (hh:mm:ss)\n" $((SECONDS/3600)) $((SECONDS/60%60)) $((SECONDS%60))