#!/bin/bash
###################################
#
#   This script will do the following functions:
#
#   1) motion correct, volreg T2*
#
#   2) censor motion
#
#   3) skull-strip, create brain mask
#
#   4) clean up temporary files
#
# Requires: AFNI, ANTs
#
# Brock Kirwan | kirwan@byu.edu
# 2/6/2019
##################################


################################
### Set Variables
################################

studyDir=/Volumes/Yorick/L2
templateDir=${studyDir}/code/templates
studySub=$1
subjDir=${studyDir}/derivatives/${studySub}

cd $subjDir


################################
### Step one: volreg
################################

# I align the struct after skull-stripping,
if [ ! -f RestingState_volreg+orig.HEAD ]; then
    3dvolreg -base ${studyDir}/${studySub}/func/${studySub}_task-rest_run-01_bold.nii'[412]' -prefix RestingState_volreg -1Dfile motion.txt ${studyDir}/${studySub}/func/${studySub}_task-rest_run-01_bold.nii
fi



################################
### Step two: censor motion files
################################

if [ ! -f motion_censor_vector.txt ]; then

    #create a separate censor file for each task/run
    1d_tool.py -infile motion.txt -set_nruns 1 -show_censor_count -censor_prev_TR -censor_motion 0.6 motion_censor_vector.txt
fi

################################
### Step three: brain mask
################################

if [ ! -f ${subjDir}ExtractedBrain0N4.nii.gz ]; then

	antsCorticalThickness.sh \
	-d 3 \
	-a ${studyDir}/${studySub}/anat/${studySub}_run-01_T1w.nii.gz  \
	-e ${templateDir}/vold2_mni_head.nii.gz \
	-t ${templateDir}/vold2_mni_brain.nii.gz \
	-m ${templateDir}/Template_BrainCerebellumProbabilityMask.nii.gz \
	-f ${templateDir}/Template_BrainCerebellumExtractionMask.nii.gz \
	-p ${templateDir}/Prior%d.nii.gz \
	-q 0 \
	-o ${subjDir}

fi

# rotate
if [ ! -f struct_rotated_brain_mask_resampled+orig.BRIK ]; then

cp ${subjDir}/ExtractedBrain0N4.nii.gz struct_brain.nii.gz
3dcopy struct_brain.nii.gz struct_brain+orig #do you have to go to afni format for this to work?
3dWarp -oblique_parent ${studyDir}/${studySub}/func/${studySub}_task-rest_run-01_bold.nii -prefix struct_rotated_brain struct_brain+orig
3dcopy struct_rotated_brain+orig struct_rotated_brain.nii.gz

# resample, binarize
3dfractionize -template ${studyDir}/${studySub}/func/${studySub}_task-rest_run-01_bold.nii -prefix struct_rotated_brain_resampled -input struct_rotated_brain+orig
3dcalc -a struct_rotated_brain_resampled+orig -prefix struct_rotated_brain_mask_resampled -expr "step(a)"

fi




################################
### Step five: clean files
################################


# clean functional
if [ -f RestingState.nii ]; then
	rm RestingState.nii
fi


# clean struct
if [ -f struct_brain+orig.HEAD ]; then
	rm struct_brain+orig*
	rm struct_rotated_brain+orig*
	rm struct_rotated_brain_resampled+orig*
fi


# clean skull strip
if [ ! -d skull_strip ]; then
	mkdir skull_strip
fi

if [[ -f ss_* ]]; then
	mv ${subjDir}* skull_strip/.
fi








