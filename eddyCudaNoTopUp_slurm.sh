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
set -u
STARTTIME=$(date +%s)

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh
module load readline/6.2.p5

scratch=scratch
cd "${scratch}"
mapfile -t subjects < list.txt
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess="${sbj}_1"
echo "Running eddyCuda (with no TopUp) on ${sbj}: ${sess}"

eddydir="${sbj}_${sess}/eddy"
imain="${eddydir}"/Pos_Neg
index="${eddydir}"/index.txt
acqp="${eddydir}"/acqparams.txt
bvecs="${eddydir}"/Pos_Neg.bvec
bvals="${eddydir}"/Pos_Neg.bval
out="${eddydir}"/eddy_unwarped_images

mask="${sbj}_${sess}"/topup/nodif_brain_mask

# Create index file
rm -f "${index}" "${acqp}"
nvols=$(fslval "${imain}" dim4)
for ((i=1; i<=nvols; i+=1)); do echo 1 >> "${index}"; done

# Create acqp file
echo "0 -1 0 .125970" >> $acqp

# Run eddy
eddy_cuda --imain="${imain}" --mask="${mask}" --index="${index}" --acqp="${acqp}" --bvecs="${bvecs}" --bvals="${bvals}" --out="${out}" --fwhm=10,8,6,4,2,0,0,0,0 --repol --resamp=jac --fep --ol_type=sw --mporder=12 --very_verbose --cnr_maps --niter=9 --ol_pos
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
