#!/bin/bash
#SBATCH --job-name=eddyCuda
#SBATCH --time=65:00:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=7gb
#SBATCH --gres=gpu:v100:1
#SBATCH --partition=gpu

set -e
set -u
STARTTIME=$(date +%s)

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh
module load readline/6.2.p5

sbj=sbj
sess=sess
scratch="scratch/${sbj}/${sess}"
imain=eddy/Pos_Neg
index=eddy/index.txt
acqp=eddy/acqparams.txt
bvecs=eddy/Pos_Neg.bvec
bvals=eddy/Pos_Neg.bval
specFile=eddy/slspecFile.txt
out=eddy/eddy_unwarped_images
mask=topup/nodif_brain_mask
topup=topup/topup_Pos_Neg_b0

cd $scratch
echo "Running eddyCuda on ${sbj}: ${sess}"
eddy_cuda --imain="${imain}" --mask="${mask}" --index="${index}" --acqp="${acqp}" --bvecs="${bvecs}" --bvals="${bvals}" --topup="${topup}" --out="${out}" --fwhm=10,8,6,4,2,0,0,0,0 --repol --resamp=lsr --fep --ol_nstd=3 --ol_type=both --slspec="${specFile}" --mporder=12 --very_verbose --s2v_niter=10 --cnr_maps --niter=9 --s2v_lambda=10 --nvoxhp=2000 --ol_pos
echo "DONE eddyCuda"

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
