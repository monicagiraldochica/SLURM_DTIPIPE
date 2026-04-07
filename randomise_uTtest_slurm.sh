#!/bin/bash
#SBATCH --job-name=randomise
#SBATCH --account=account
#SBATCH --time=25:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=5gb
#SBATCH --chdir=/scratch/g/mygroup/mydir
set -e
set -u
SECONDS=0

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

img=FA

# -n 500: generate 500 permutations of the data when building the null distribution to test against. If it runs fast, I could test with more (up to 2000)
# *** FOR THE UNPAIRED TTEST THE -D OPTION ISNT NECESSARY BECAUSE THE GROUP MEAN IS ALREADY REPRESENTED BY THE TWO EVS AND MAY BE PROBLEMATIC ***
# --T2: using TFCE for the test statistic. This is cluster-based thresholding. It factors in different connectivity probabilities for the skeletonized data.
# raw test statistic: _tstat/fstat: This is the best image to get the clusters and peak information from, it can be thresholded using the significant voxels from corrp so that only significant voxels are reported
# uncorrected outputs (using Threshold-Free Cluster enhancement): _tfce_p_tstat/fstat (1-uncorrectedP)
# uncorrected outputs (using voxel-based thresholding): _vox_p_tstat/fstat (1-uncorrectedP)
# corrected outputs (using Threshold-Free Cluster enhancement): _tfce_corrp_tstat/fstat (1-FWE correctedP, Family Wise Error rate controled)
# corrected outputs (using voxel-based thresholding): _vox_corrp_tstat/fstat (1-FWE correctedP, Family Wise Error rate controled)
# For two groups no need to use f-tests
# -d: design matrix: each column contains a predictor
echo "Running randomise ${img}"
randomise -i all_"$img"_skeletonised.nii.gz -o ttest -m mean_FA_skeleton_mask.nii.gz -d design.mat -t design.con -n 500 --T2
echo "DONE randomise"

# Compute execution time
printf "\nTotal execution time: %02d:%02d:%02d (hh:mm:ss)\n" $((SECONDS/3600)) $((SECONDS/60%60)) $((SECONDS%60))