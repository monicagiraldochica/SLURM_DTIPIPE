import sys
import os
import datetime

if len(sys.argv)!=2:
    sys.exit("ERROR: wrong number of arguments")

tbss_name = sys.argv[1]

start_date = str(datetime.date.today().strftime("%Y_%m_%d"))
start_time = str(datetime.datetime.today().strftime("%H:%M:%S"))
start_dt = start_date+"_"+start_time

print(f"TBSS: {tbss_name}")

rundir = f"/home/mkeith/scratch2/{tbss_name}"
print(f"rundir: {rundir}")
os.system(f"cd {rundir}")

# NOTE: PART2 IS ONLY RUN ON FA, NOT ON ALTERNATIVE IMGS

# For the ECP TBSS I was using 0.5 because of the high inter-subject variability in the sample and the threshold had to be increased. but 0.2 is the default
# If I change it, change it also in preStatsPart1.py
thr = 0.5

# Create skeleton mask using threshold to threshold areas of low mean FA and high inter-subject variability
print("\nCreating skeleton mask...")
os.system(f"fslmaths mean_FA_skeleton -thr {thr} -bin mean_FA_skeleton_mask")
print("done")

# Create skeleton distance map (for use in projection search)
print("\nCreating skeleton distance map...")
os.system(f"fslmaths mean_FA_mask -mul -1 -add 1 -add mean_FA_skeleton_mask mean_FA_skeleton_mask_dst")
os.system("distancemap -i mean_FA_skeleton_mask_dst -o mean_FA_skeleton_mask_dst")
print("done")

# Project all FA data onto skeleton
# In the projected images, each skeletton voxel takes the value from the local centre of the nearest relevant track
print("\nProjecting data...")
os.system(f"tbss_skeleton -i mean_FA -p {thr} mean_FA_skeleton_mask_dst /opt/fsl/data/standard/LowerCingulum_1mm all_FA all_FA_skeletonised")
print("done")

print("\nDONE preStats_part2")

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

print(f"Total execution time was {diff_days} days {diff_hours} hrs {diff_min} mins {diff_sec} secs")
