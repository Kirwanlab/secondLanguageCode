#!/bin/bash
##################################
#
# Script to import dicoms to nii format and prep for BIDS format. Also anonymizes/defaces T1 scans.
#
# Requires: dcm2niix, FreeSurfer, AFNI, and jq. (jq can be installed via homebrew)
#
# Brock Kirwan | kirwan@byu.edu
# 2/6/2019
##################################



#set up variables#
studyDir=/Volumes/Yorick/L2
rawDir=/Volumes/Yorick/MriRawData
templateDir=/Volumes/Yorick/Templates
session=ses-L2
run=01
studySub=$1

## copy over the template and mask files that you'll need
if [ ! -d ${studyDir}/code/templates ]; then
	mkdir ${studyDir}/code/templates

	cp ${templateDir}/vold2_mni/vold2_mni_head.nii.gz ${studyDir}/code/templates/.
	cp ${templateDir}/vold2_mni/vold2_mni_brain.nii.gz ${studyDir}/code/templates/.
	cp ${templateDir}/vold2_mni/priors_ACT/Template_BrainCerebellumProbabilityMask.nii.gz ${studyDir}/code/templates/.
	cp ${templateDir}/vold2_mni/priors_ACT/Template_BrainCerebellumExtractionMask.nii.gz ${studyDir}/code/templates/.
	cp ${templateDir}/vold2_mni/priors_ACT/Prior?.nii.gz ${studyDir}/code/templates/.
	cp ${templateDir}/facemask.nii.gz ${studyDir}/code/templates/.
	cp ${templateDir}/mean_reg2mean.nii.gz ${studyDir}/code/templates/.
	
fi

## import T1 from dicom, put in source folder until de-faced
echo "--CONVERT MPRAGE SUBJECT ${studySub}--"
if [ ! -f ${rawDir}/${studySub}/${session}/anat/${studySub}_run-${run}_T1w.nii.gz ]; then
    mkdir ${rawDir}/${studySub}/${session}/anat
    dcm2niix -b y -z y -o ${rawDir}/${studySub}/${session}/anat -f ${studySub}_run-${run}_T1w ${rawDir}/${studySub}/${session}/dicom/t1*
fi

## set up for freesurfer
if [ ! -f ${rawDir}/${studySub}/${session}/freesurfer/mri/orig/001.mgz ]; then
    mkdir -p ${rawDir}/${studySub}/${session}/freesurfer/mri/orig
    mri_convert ${rawDir}/${studySub}/${session}/anat/${studySub}_run-${run}_T1w.nii.gz ${rawDir}/${studySub}/${session}/freesurfer/mri/orig/001.mgz
fi

## set up file structure
mkdir -p ${studyDir}/${studySub}/{anat,func}

## deface and put in anat folder
if [ ! -f ${studyDir}/${studySub}/anat/${studySub}_run-${run}_T1w.nii.gz ]; then
    ## There are several ways to do this. The FreeSurfer program 'mri_deface' seems to work pretty well, but it fails on a few of our scans, presumably due to low gray/white contrast. This is the code for making that happen:
    ## [N.B.: This step may not work in a script because of Mac OS X SIP. You can disable this "security" feature by doing this: https://afni.nimh.nih.gov/afni/community/board/read.php?1,149775,149775]
    # mri_deface ${rawDir}/${studySub}/${session}/${studySub}_run-${run}_T1w.nii.gz /usr/local/bin/freesurfer/talairach_mixed_with_skull.gca /usr/local/bin/freesurfer/face.gca ${studyDir}/${studySub}/anat/${studySub}_run-${run}_T1w.nii.gz
    ##delete the log file (which writes out the same info every time it's successful)
    # rm ${studySub}_run-${run}_T1w.nii.log
    
    ## There is also a python tool for this called pydeface (written by Russ Poldrack), but I couldn't get it to work with all the python dependencies it has.
    ## Instead, I borrowed the mask and the mean structural files from that toolkit and I use them with AFNI tools to:
    ## 1-calculate a spatial transformation from the mean structural to the subject's struct
    ## 2-apply that transformation to the face mask
    ## 3-multiply the mask by the subject structural to zero out all the face voxels (and nothing else)
    3dAllineate -base ${rawDir}/${studySub}/${session}/anat/${studySub}_run-${run}_T1w.nii.gz -input ${studyDir}/code/templates/mean_reg2mean.nii.gz -prefix ${rawDir}/${studySub}/${session}/mean_reg2mean_aligned.nii -1Dmatrix_save ${rawDir}/${studySub}/${session}/anat/allineate_matrix 
    3dAllineate -base ${rawDir}/${studySub}/${session}/anat/${studySub}_run-${run}_T1w.nii.gz -input ${studyDir}/code/templates/facemask.nii.gz -prefix ${rawDir}/${studySub}/${session}/facemask_aligned.nii -1Dmatrix_apply ${rawDir}/${studySub}/${session}/anat/allineate_matrix.aff12.1D 
    3dcalc -a ${rawDir}/${studySub}/${session}/facemask_aligned.nii -b ${rawDir}/${studySub}/${session}/anat/${studySub}_run-${run}_T1w.nii.gz -prefix ${studyDir}/${studySub}/anat/${studySub}_run-${run}_T1w.nii.gz -expr "step(a)*b"


fi

if [ ! -f ${studyDir}/${studySub}/anat/${studySub}_run-${run}_T1w.json ]; then

    #copy over the .json file with the scan info
    cp ${rawDir}/${studySub}/${session}/anat/${studySub}_run-${run}_T1w.json ${studyDir}/${studySub}/anat/.
    
fi


## import functionals from dicom
echo "--CONVERT RESTING STATE FUNCTIONAL --"
if [ ! -f ${studyDir}/${studySub}/func/${studySub}_task-rest_run-01_bold.nii.gz ]; then
	dcm2niix -b y -z y -o ${studyDir}/${studySub}/func -f ${studySub}_task-rest_run-01_bold ${rawDir}/${studySub}/${session}/dicom/Resting_State_*/
fi

funcjson=${studyDir}/${studySub}/func/${studySub}_task-rest_run-01_bold.json
taskexist=$(cat ${funcjson} | jq '.TaskName')
if [ "$taskexist" == "null" ]; then
	jq '. |= . + {"TaskName":"rest"}' ${funcjson} > ${studyDir}/${studySub}/func/tasknameadd.json
	rm ${funcjson}
	mv ${studyDir}/${studySub}/functasknameadd.json ${funcjson}
fi

## validate the bids
docker run -ti --rm -v ${studyDir}:/data:ro bids/validator /data

