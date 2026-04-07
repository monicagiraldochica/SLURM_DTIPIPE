#!/bin/bash
#SBATCH --job-name=camino
#SBATCH --time=05:00:00
#SBATCH --account=account
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10gb
#SBATCH --partition=bigmem
#SBATCH --array=1-48%10
#SBATCH --chdir=/scratch/g/mygroup/mydir
set -e
set -u
SECONDS=0

module load ants
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

mapfile -t subjects < list.txt
(( SLURM_ARRAY_TASK_ID <= ${#subjects[@]} )) || exit 0
sbj=${subjects[SLURM_ARRAY_TASK_ID-1]}
sess="${sbj}_1"
echo "Running Camino on ${sbj}: ${sess}"

reference="${FSLDIR}/data/standard/FMRIB58_FA_1mm.nii.gz"

datadir="${sbj}_${sess}/data"
bvecs="${datadir}"/bvecs
bvals="${datadir}"/bvals
data="${datadir}"/data.nii.gz
mask="${datadir}"/nodif_brain_mask.nii.gz

diffDir="${datadir}"/camino
scheme="${diffDir}"/bvector.scheme
Bfloat="${diffDir}"/dwi.Bfloat

outDir="${diffDir}"/wlf
mkdir -p "${outDir}"
Bdouble="${outDir}"/dt.Bdouble
snr="${outDir}"/snr.txt
fa="${outDir}"/fa.nii.gz

ants="${outDir}"/ants
affine="${ants}"/faAffine.txt
warp="${ants}"/faWarp.nii.gz
fa_transf="${ants}"/fa.nii.gz
invwarp="${ants}"/faInverseWarp.nii.gz

inverse="${ants}"/inverse
sbj_sklt="${inverse}"/FMRIB58_FA-skeleton_1mm.nii.gz

rm -rf "${outDir}" "${scheme}" "${Bfloat}"

echo "### Running camino (weighted linear fitting) on ${sbj}: ${sess}"

echo -e "\n## Creating scheme file..."
fsl2scheme -bvecfile "${bvecs}" -bvalfile "${bvals}" > "${scheme}"

echo -e "\n## Checking DWI data type..."
dt=$(fslval "${data}" data_type)
if [ "${dt/ /}" != "FLOAT32" ]
then
	echo "Attempting to fix data type"
	fslmaths "${data}" "${data}" -odt float
	dt=$(fslval "${data}" data_type)
	[ "${dt/ /}" != "FLOAT32" ] && echo "ERROR: ${dt} data type" && exit 1
else
        echo "data type ok"
fi

echo -e "\n## Converting DWI data..."
image2voxel -4dimage "${data}" -outputfile "${Bfloat}"

echo -e "\n## Fitting the diffusion tensor to the data..."
wdtfit "${Bfloat}" "${scheme}" -bgmask "${mask}" -outputfile "${Bdouble}"

for PROG in fa md
do
	echo -e "\n## Computing ${PROG}..."
	cat "${Bdouble}" | "${PROG}" | voxel2image -outputroot "${outDir}/${PROG}" -header "${data}" &
done
wait

echo -e "\n## Transforming FA map to STD space..."
ANTS 3 -m CC["${reference}",$fa,1,5] -o "${fa_transf}" -r Gauss[2,0] -t SyN[0.25] -i 30x99x11 --use-Histogram-Matching
WarpImageMultiTransform 3 "${fa}" "${fa_transf}" -R "${reference}" "${warp}" "${affine}"

echo -e "\n## Applying inverse transformation to skeleton..."
WarpImageMultiTransform 3 "${sbj_sklt}" "${sbj_sklt}" -i "${affine}" "${invwarp}" -R "${reference}" --use-NN

echo -e "\n## Estimating snr..."
estimatesnr -inputfile "${Bfloat}" -schemefile "${scheme}" -bgmask "${sbj_sklt}" > "${snr}"

echo -e "\nDONE camino"

# Compute execution time
printf "\nTotal execution time: %02d:%02d:%02d (hh:mm:ss)\n" $((SECONDS/3600)) $((SECONDS/60%60)) $((SECONDS%60))