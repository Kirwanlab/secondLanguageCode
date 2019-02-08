#!/bin/bash

##################################
#
#   This script will do the following functions:
#
#   1) calculate ants transform
#
#   2) apply ants xform to functional data
#
#   3) identify drift, etc and create a "clean" dataset w/o it
#
#   4) perform correlation analysis on cleaned dataset
#
# Requires: AFNI, ANTs, antifyFunctional.sh (found in the same folder as this script)
#
# Brock Kirwan | kirwan@byu.edu
# 2/6/2019
##################################




################################
### Set Variables
################################

studyDir=/Volumes/Yorick/L2
workDir=${studyDir}/derivatives
templateDir=${studyDir}/code/templates
subjID=$1
subjDir=${workDir}/${subjID}
antifyPath=${studyDir}/code


################################
### Step zero: cd into subject directory
################################

cd $subjDir


################################
### Step one: ants
################################

if [ ! -f struct_rotated_brainWarp.nii ]; then
	ants.sh 3 ${templateDir}/vold2_mni_brain.nii.gz struct_rotated_brain.nii.gz
fi


################################
### Step two: Antify
################################

if [ ! -f struct_rotated_braindeformed.nii.gz ]; then
	WarpImageMultiTransform 3 struct_rotated_brain.nii.gz struct_rotated_braindeformed.nii.gz struct_rotated_brainWarp.nii struct_rotated_brainAffine.txt -R ${templateDir}/vold2_mni_brain.nii.gz
fi

if [ ! -f RestingState_volreg_ANTS_resampled+tlrc.HEAD ]; then
	${antifyPath}/antifyFunctional.sh struct_rotated_brain ${templateDir}/vold2_mni_brain.nii.gz RestingState_volreg+orig
fi


################################
### Step three: 3dDeconvolve to identify drift, head motion, etc.
################################

if [ ! -f resting_cleaned+tlrc.HEAD ]; then

	3dDeconvolve -input RestingState_volreg_ANTS_resampled+tlrc \
	-polort 2 \
	-num_stimts 6 \
	-stim_file  1 "motion_1[0]" -stim_label 1 "Roll"  -stim_base 1 \
	-stim_file  2 "motion_1[1]" -stim_label 2 "Pitch" -stim_base 2 \
	-stim_file  3 "motion_1[2]" -stim_label 3 "Yaw"   -stim_base 3 \
	-stim_file  4 "motion_1[3]" -stim_label 4 "dS"    -stim_base 4 \
	-stim_file  5 "motion_1[4]" -stim_label 5 "dL"    -stim_base 5 \
	-stim_file  6 "motion_1[5]" -stim_label 6 "dP"    -stim_base 6 \
	-cbucket resting_cbucket \
	-x1D resting_xmatrix

	#calculate the effects of no interest
	3dSynthesize -cbucket resting_cbucket+tlrc -matrix resting_xmatrix.xmat.1D -select all -prefix restingEffectsOfNoInterest

	#take out effects of no interest
	3dcalc -a RestingState_volreg_ANTS_resampled+tlrc -b restingEffectsOfNoInterest+tlrc -expr "a-b" -prefix resting_cleaned
fi

################################
### Step four: Correlation analysis
################################

#I want a mask in ANTs space
if [ ! -f struct_rotated_brain_mask_ANTS_binary+tlrc.HEAD ]; then

	${antifyPath}/antifyFunctional.sh struct_rotated_brain ${templateDir}/vold2_mni_brain.nii.gz struct_rotated_brain_mask_resampled+orig

	#binarize that
	3dcalc -a struct_rotated_brain_mask_resampled_ANTS_resampled+tlrc -prefix struct_rotated_brain_mask_ANTS_binary -expr "step(a-.5)"

fi


#mask the functional dataset
if [ ! -f resting_cleaned_retrosplenial_vect.1D ]; then
	3dROIstats -quiet -mask ${templateDir}/retrosplenial_resampled+tlrc resting_cleaned+tlrc > resting_cleaned_retrosplenial_vect.1D
fi

#calculate the correlations (3dTcorr1D method):
if [ ! -f Corr_retrosplenial+tlrc.HEAD ]; then
	3dTcorr1D -mask struct_rotated_brain_mask_ANTS_binary+tlrc -prefix Corr_retrosplenial resting_cleaned+tlrc resting_cleaned_retrosplenial_vect.1D
fi


#Z-transform the correlation coefficients
if [ ! -f Corr_retrosplenial_Z+tlrc.HEAD ]; then
	3dcalc -a Corr_retrosplenial+tlrc -expr 'log((1+a)/(1-a))/2' -prefix Corr_retrosplenial_Z
fi

