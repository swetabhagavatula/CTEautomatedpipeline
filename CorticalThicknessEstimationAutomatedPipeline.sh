#! /bin/sh

ANTDIR=/usr/local/ANTs/
PATH=${ANTDIR}/bin:${PATH}
export ANTDIR PATH
ANTSPATH=/usr/local/ANTs/bin/
export ANTSPATH

filename=IND
brainTemp=/ifshome/aumartinez/requiredStartingFiles/brain_filled.nii
brainTempMask=/ifshome/aumartinez/requiredStartingFiles/brain_filled_mask.nii.gz
atlas=/ifshome/aumartinez/requiredStartingFiles/atlas_update2018.clean.nii
corticalLabels=/ifshome/aumartinez/requiredStartingFiles/cortical_labels.csv
tissueRelabels=/ifshome/aumartinez/requiredStartingFiles/relabel_n4.csv

process=/ifs/loni/postdocs/rcabeen/collab/epibios/rodent/process/Melbourne-P1/day150
sourcepath=/ifs/loni/faculty/dduncan/abennett/CTE_final/Melbourne-P1/day150
qitpath=/ifshome/rcabeen/bin

cd /ifs/loni/faculty/dduncan/abennett/CTE_final/Melbourne-P1/day150/${filename}

antsBrainExtraction.sh -d 3 -a ${process}/${filename}/native.mge/param/fit/mge_mean.nii.gz -e ${brainTemp} -m ${brainTempMask} -o ${sourcepath}/${filename}/bet_mean.nii

${qitpath}/qit --verbose MaskErode --input ${sourcepath}/${filename}/bet_mean.niiBrainExtractionMask.nii.gz --num 3 --output ${sourcepath}/${filename}/maskerodemge.nii.gz

N4BiasFieldCorrection -d 3 -i ${sourcepath}/${filename}/bet_mean.niiBrainExtractionBrain.nii.gz -o ${sourcepath}/${filename}/bcorr_mge_mean.nii.gz

antsAtroposN4.sh -d 3 -a ${sourcepath}/${filename}/bcorr_mge_mean.nii.gz -c 4 -x ${sourcepath}/${filename}/maskerodemge.nii.gz -b Plato[1, 0.5, 1, 1] -o ${sourcepath}/${filename}/segmentation.nii.gz

mv ${sourcepath}/${filename}/tmp*/tmpSegmentation.nii.gz ${sourcepath}/${filename}/segmentation.nii.gz

${qitpath}/qit MaskRelabel --mask ${sourcepath}/${filename}/segmentation.nii.gz --mapping ${tissueRelabels} --outputMask ${sourcepath}/${filename}/relabeledSegmentation.nii.gz

${qitpath}/qit MaskBinarize --input ${process}/${filename}/native.dwi/lesion/lesion.nii.gz --output ${sourcepath}/${filename}/lesionBinary.nii.gz

antsRegistrationSyNQuick.sh -d 3 -f ${process}/${filename}/native.dwi/mask/brain.nii.gz -m ${sourcepath}/${filename}/relabeledSegmentation.nii.gz -o ${sourcepath}/${filename}/regDWI.nii.gz

antsApplyTransforms -d 3 -i ${sourcepath}/${filename}/lesionBinary.nii.gz -r ${sourcepath}/${filename}/relabeledSegmentation.nii.gz -o ${sourcepath}/${filename}/transLesion.nii.gz -n NearestNeighbor -t ${sourcepath}/${filename}/regDWI.nii.gz1InverseWarp.nii.gz -t [${sourcepath}/${filename}/regDWI.nii.gz0GenericAffine.mat , 1]

${qitpath}/qit MaskSet --input ${sourcepath}/${filename}/relabeledSegmentation.nii.gz --mask ${sourcepath}/${filename}/transLesion.nii.gz --label 5 --output ${sourcepath}/${filename}/relabeledLesionSegmentation.nii.gz 

antsRegistrationSyNQuick.sh -d 3 -f ${brainTemp} -m ${sourcepath}/${filename}/bet_mean.niiBrainExtractionBrain.nii.gz -o ${sourcepath}/${filename}/regBrain.nii.gz

antsApplyTransforms -d 3 -i ${atlas} -r ${sourcepath}/${filename}/bet_mean.niiBrainExtractionBrain.nii.gz -o ${sourcepath}/${filename}/trans_atlas.nii -n NearestNeighbor -t [${sourcepath}/${filename}/regBrain.nii.gz0GenericAffine.mat , 1] -t ${sourcepath}/${filename}/regBrain.nii.gz1InverseWarp.nii.gz

${qitpath}/qit MaskExtract --input ${sourcepath}/${filename}/trans_atlas.nii --label 2,3,4,8,9,10,14,15,16,17,18,19,22,24,25,37,40,42,43,44,45,47,48,49,50,51,52,54,55,56,57,58,59,60,61,62,63,64,65,66,67,74,77,78,79,80,81,82,83,87,88,89,93,94,95,99,100,101,102,103,104,107,109,110,122,125,127,128,129,130,132,133,134,135,136,137,139,140,141,142,143,144,145,146,147,148,149,150,151,152,159,162,163,164,165,166,167,168 --output ${sourcepath}/${filename}/cortical_mask.nii.gz

${qitpath}/qit VolumeMask --input ${sourcepath}/${filename}/relabeledLesionSegmentation.nii.gz --mask ${sourcepath}/${filename}/cortical_mask.nii.gz --output ${sourcepath}/${filename}/cortical_multi.nii.gz 

KellyKapowski -d 3 -s ${sourcepath}/${filename}/cortical_multi.nii.gz -o ${sourcepath}/${filename}/CTE.nii

${qitpath}/qit MaskRegionsMeasure --regions ${sourcepath}/${filename}/trans_atlas.nii --lookup ${corticalLabels} --volume thickness=${sourcepath}/${filename}/CTE.nii --output ${sourcepath}/${filename}/${filename}_thickness_stats
