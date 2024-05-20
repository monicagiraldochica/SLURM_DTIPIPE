#!/bin/bash
#SBATCH --job-name=randomise
#SBATCH --account=account
#SBATCH --time=25:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=5gb
set -e
STARTTIME=$(date +%s)

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

img=FA
outDir=TBSS
cd scratch/$outDir

# This Tests if ANY of the levels is significantly different. To identify which level, one has to perform multiple t-tests.
# -n 500: generate 500 permutations of the data when building the null distribution to test against. If it runs fast could, I test with more (up to 2000)
# The k dummy variables also model the grand mean, so randomise command should be used without the -D flag
# --T2: using TFCE for the test statistic. This is cluster-based thresholding. It factors in different connectivity probabilities for the skeletonized data.
# raw test statistic: _tstat/fstat # This is the best image to get the clusters and peak information from, it can be thresholded using the significant voxels from corrp so that only significant voxels are reported
# uncorrected outputs (using Threshold-Free Cluster enhancement): _tfce_p_tstat/fstat (1-uncorrectedP)
# uncorrected outputs (using voxel-based thresholding): _vox_p_tstat/fstat (1-uncorrectedP)
# corrected outputs (using Threshold-Free Cluster enhancement): _tfce_corrp_tstat/fstat (1-FWE correctedP, Family Wise Error rate controled)
# corrected outputs (using voxel-based thresholding): _vox_corrp_tstat/fstat (1-FWE correctedP, Family Wise Error rate controled)
# -d: design matrix: each column contains a predictor
# -f: F-test file: the f-tests are added on any contrasts that span the groups EVs to control for multiple tests. f-test is used to determine significance while t-contrast is used to determine directionality
echo "Running randomise ${img}"
randomise -i all_${img}_skeletonised.nii.gz -o ftest -m mean_FA_skeleton_mask.nii.gz -d design.mat -t design.con -f design.fts -n 500 --T2
echo "DONE randomise"

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
echo "Total execution time was ${DUR_H} hrs ${DUR_M} mins ${DUR_S} secs"
