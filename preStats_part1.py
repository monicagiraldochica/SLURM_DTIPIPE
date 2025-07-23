#!/usr/bin/env python3
__author__ = "Monica Keith"
__status__ = "Production"
__purpose__ = "Pre-TBSS file manipulation step1"

import sys
import os
import datetime

if len(sys.argv)!=5:
    sys.exit("ERROR: wrong number of arguments")
    
tbss_name = sys.argv[1]
img = sys.argv[2]
scratch = sys.argv[3]
FSLSTD = sys.argv[4]

start_date = str(datetime.date.today().strftime("%Y_%m_%d"))
start_time = str(datetime.datetime.today().strftime("%H:%M:%S"))
start_dt = start_date+"_"+start_time

print(f"TBSS: {tbss_name}")
print(f"image: {img}")

rundir = f"{scratch}/{tbss_name}"
print(f"rundir: {rundir}")
os.system(f"cd {rundir}")

if img=="FA":
    print("\nCreating mean FA...")
    os.system("fslmaths all_FA -max 0 -Tmin -bin mean_FA_mask -odt char")
    os.system("fslmaths all_FA -mas mean_FA_mask all_FA")
    os.system("fslmaths all_FA -Tmean mean_FA")
    print("done")

    # The skeletonized FA represents the centres of all fibre bundles that are generally common to the subjects involved in the study.
    print("\nCreating FA sekeleton...")
    os.system("tbss_skeleton -i mean_FA -o mean_FA_skeleton")
    print("done")

elif not os.path.isfile("mean_FA.nii.gz"):
    sys.exit("ERROR: missing mean_FA")

elif not os.path.isfile("mean_FA_skeleton_mask_dst.nii.gz"):
    sys.exit("ERROR: missing FA distance map")

elif not os.path.isfile("all_FA.nii.gz"):
    sys.exit("ERROR: all_FA")

else:
    # Pojection of the alternative image into the skeletonised FA
    # default thr is 0.2, but because of the high inter-subject variability in the sample, I increased the threshold
    # Make sure to use same thr in preStats_part2 (for FA, part2 is NOT run on alternative imgs)
    thr=0.5
    print(f"\nProjecting {img} into skeletonised FA using {thr} threhold...")
    os.system(f"tbss_skeleton -i mean_FA -p {thr} mean_FA_skeleton_mask_dst {FSLSTD}/LowerCingulum_1mm all_FA all_{img}_skeletonised -a all_{img}")
    print("done")

print("\nDONE preStats_part1")

now_date = str(datetime.date.today().strftime("%Y_%m_%d"))
now_time = str(datetime.datetime.today().strftime("%H:%M:%S"))
now_dt = now_date+'_'+now_time

tdelta = str(datetime.datetime.strptime(now_dt,"%Y_%m_%d_%H:%M:%S") - datetime.datetime.strptime(start_dt,"%Y_%m_%d_%H:%M:%S"))
tdelta_array = tdelta.split(',')
if len(tdelta_array)==1:
    diff_days = 0
    diff_hours = int(tdelta_array[0].split(':')[0])
    diff_min = int(tdelta_array[0].split(':')[1])
    diff_sec = int(tdelta_array[0].split(':')[2])
else:
    diff_days = int(tdelta_array[0].split(' ')[0])
    diff_hours = int(tdelta_array[1].split(':')[0])
    diff_min = int(tdelta_array[1].split(':')[1])
    diff_sec = int(tdelta_array[1].split(':')[2])

print(f"Total execution time was {diff_hours} hrs {diff_min} mins {diff_sec} secs")
