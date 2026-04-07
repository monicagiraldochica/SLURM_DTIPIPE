#!/bin/bash
#SBATCH --job-name=eddyCuda
#SBATCH --time=32:00:00
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
printf "\nTotal execution time: %02d:%02d:%02d (hh:mm:ss)\n" $((SECONDS/3600)) $((SECONDS/60%60)) $((SECONDS%60))