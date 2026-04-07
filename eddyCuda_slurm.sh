#!/bin/bash
#SBATCH --job-name=eddyCuda
#SBATCH --time=65:00:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=7gb
#SBATCH --gres=gpu:v100:1
#SBATCH --partition=gpu
#SBATCH --chdir=/scratch/g/mygroup/mydir
set -e
set -u
SECONDS=0

module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh
module load readline/6.2.p5

mapfile -t subjects < list.txt
(( SLURM_ARRAY_TASK_ID <= ${#subjects[@]} )) || exit 0
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess="${sbj}_1"
echo "Running EddyCuda on ${sbj}: ${sess}"

eddydir="${sbj}_${sess}/eddy"
imain="${eddydir}"/Pos_Neg
index="${eddydir}"/index.txt
acqp="${eddydir}"/acqparams.txt
bvecs="${eddydir}"/Pos_Neg.bvec
bvals="${eddydir}"/Pos_Neg.bval
specFile="${eddydir}"/slspecFile.txt
out="${eddydir}"/eddy_unwarped_images

topupdir="${sbj}_${sess}/topup"
mask="${topupdir}"/nodif_brain_mask
topup="${topupdir}"/topup_Pos_Neg_b0

eddy_cuda --imain="${imain}" --mask="${mask}" --index="${index}" --acqp="${acqp}" --bvecs="${bvecs}" --bvals="${bvals}" --topup="${topup}" --out="${out}" --fwhm=10,8,6,4,2,0,0,0,0 --repol --resamp=lsr --fep --ol_nstd=3 --ol_type=both --slspec="${specFile}" --mporder=12 --very_verbose --s2v_niter=10 --cnr_maps --niter=9 --s2v_lambda=10 --nvoxhp=2000 --ol_pos
echo "DONE eddyCuda"

# Compute execution time
printf "\nTotal execution time: %02d:%02d:%02d (hh:mm:ss)\n" $((SECONDS/3600)) $((SECONDS/60%60)) $((SECONDS%60))