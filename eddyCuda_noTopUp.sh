#!/bin/bash
#SBATCH --job-name=eddyCuda
#SBATCH --time=32:00:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=7gb
#SBATCH --gres=gpu:v100:1
#SBATCH --partition=gpu
set -e
STARTTIME=$(date +%s)

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh
module load readline/6.2.p5

sbj=sbj
sess=sess
scratch=scratch/$sbj/$sess
cd $scratch

imain=eddy/Pos_Neg
index=eddy/index.txt
acqp=eddy/acqparams.txt
bvecs=eddy/Pos_Neg.bvec
bvals=eddy/Pos_Neg.bval
out=eddy/eddy_unwarped_images
mask=topup/nodif_brain_mask

echo "Running eddyCuda on ${sbj}: ${sess}"

# Create index file
rm -f $index $acqp
nvols=$(fslval $imain dim4)
for ((i=1; i<=$nvols; i+=1)); do echo 1 >> $index; done

# Create acqp file
echo "0 -1 0 .125970" >> $acqp

# Run eddy
eddy_cuda --imain=$imain --mask=$mask --index=$index --acqp=$acqp --bvecs=$bvecs --bvals=$bvals --out=$out --fwhm=10,8,6,4,2,0,0,0,0 --repol --resamp=jac --fep --ol_type=sw --mporder=12 --very_verbose --cnr_maps --niter=9 --ol_pos

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
