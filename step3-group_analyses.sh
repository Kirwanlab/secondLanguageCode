#!/bin/bash

##################################
#
#   This script will do the following functions:
#
#   1) create a mean functional connectivity map and threshold it
#
#   2) pull mean connectivity scores for above-threshold clusters
#
#   3) run an MVM exploratory analysis on whole brain data
#
#   4) again, threshold resulting map and pull mean connectivity scores.
#
# Requires: AFNI 
#
# Brock Kirwan | kirwan@byu.edu
# 2/6/2019
##################################




################################
### Set Variables
################################
studyDir=/Volumes/Yorick/L2
outDir=${studyDir}/derivatives/grpAnalysis

cd $outDir

################################
## Analysis of the functional connectivity within DMN:
################################

# average together all the correlation maps
corrMaps=`ls ${studyDir}/derivatives/sub-*/Corr_retrosplenial_Z+tlrc.HEAD`
3dmerge -prefix mean_retrosplenial $corrMaps

#threshold at p<.01 (two-tailed). With 92 subjects (df=90), an r-value of 2.68 yields a p-value of .009799
3dclust -1Dformat -nosum -1dindex 0 -1tindex 0 -2thresh -0.268 0.268 -dxyz=1 -savemask Corr_retr_z.268_p01_k118_mask 1.01 118 mean_retrosplenial+tlrc.HEAD
#This should yield 5 regions of interest (ROIs) comprising the DMN in this sample

#pull statistics within each ROI from each subject with something like this:
3dROIstats -mask Corr_retr_z.268_p01_k118_mask+tlrc -mask_f2short -1DRformat $corrMaps > Corr_retr_z.268_p01_k118_mask.txt
#Then you can use your favorite statistical analysis package to do stats on the connectivity scores in each ROI. We used SPSS, but the txt file should import into R nicely.



################################
## Exploratory whole-brain analysis for functional connectivity that varied as a function of L2 proficiency
################################

3dMVM  -prefix MVM_Corr_retro_prof1 -jobs 12 -mask ${templateDir}/vold2_mni_brain_mask+tlrc \
	-bsVars "Prof" \
	-qVars "Prof" \
	-dataTable  \
	Subj	Prof	InputFile \
	sub-2975	5	../sub-975/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3225	8	../sub-3225/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3789	10	../sub-3789/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3861	6	../sub-3861/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3876	5	../sub-3876/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3877	7	../sub-3877/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3878	10	../sub-3878/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3879	5	../sub-3879/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3880	6	../sub-3880/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3883	10	../sub-3883/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3884	5	../sub-3884/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3885	8	../sub-3885/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3891	10	../sub-3891/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3892	9	../sub-3892/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3894	7	../sub-3894/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3895	8	../sub-3895/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3896	9	../sub-3896/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3898	6	../sub-3898/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3899	6	../sub-3899/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3900	9	../sub-3900/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3901	8	../sub-3901/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3903	8	../sub-3903/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3906	8	../sub-3906/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3907	9	../sub-3907/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3908	9	../sub-3908/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3909	9	../sub-3909/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3910	5	../sub-3910/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3911	9	../sub-3911/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3912	9	../sub-3912/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3913	8	../sub-3913/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3917	8	../sub-3917/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3918	2	../sub-3918/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3919	8	../sub-3919/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3920	3	../sub-3920/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3921	9	../sub-3921/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3925	6	../sub-3925/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3927	5	../sub-3927/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3929	8	../sub-3929/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3930	9	../sub-3930/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3932	9	../sub-3932/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3936	10	../sub-3936/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3941	9	../sub-3941/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3942	9	../sub-3942/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3944	7	../sub-3944/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3946	9	../sub-3946/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3947	8	../sub-3947/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3948	8	../sub-3948/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3949	9	../sub-3949/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3952	10	../sub-3952/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3953	10	../sub-3953/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3955	10	../sub-3955/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3956	10	../sub-3956/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3957	8	../sub-3957/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3962	8	../sub-3962/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3963	9	../sub-3963/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3965	5	../sub-3965/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3966	10	../sub-3966/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3967	9	../sub-3967/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3968	10	../sub-3968/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-3969	9	../sub-3969/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-4015	8	../sub-4015/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-4127	8	../sub-4127/Corr_retrosplenial_Z+tlrc.HEAD \
	sub-4128	7	../sub-4128/Corr_retrosplenial_Z+tlrc.HEAD 

#threshold the resulting stats file:
 3dclust -1Dformat -nosum -1dindex 1 -1tindex 1 -2thresh -5.708 5.708 -dxyz=1 -savemask MVM_ME_Prof_p.02_k31_mask 1.01 30 MVM_Corr_retro_prof1+tlrc.HEAD

#pull connectivity scores from the ROI
3dROIstats -mask MVM_Corr_retro_prof1+tlrc -mask_f2short -1DRformat $corrMaps > MVM_Corr_retro_prof1+tlrc.txt

