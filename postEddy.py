#!/usr/bin/env python3
__author__ = "Monica Keith"
__status__ = "Production"
__purpose__ = "Perform post eddy image manipulation"

import sys
import os
import datetime

def trimCols(col1,col2,iname,oname):
    print("Keeping columns "+str(col1)+" to "+str(col2))
    os.system("1d_tool.py -overwrite -infile "+iname+'['+str(col1)+".."+str(col2)+"] -write "+oname)
    
def final_bvecs_1(eddy,data,volsPos1,volsPos2,volsNeg1,volsNeg2):
    print("**All series are present**")
    trimCols(0,volsPos1-1,eddy+"eddy_unwarped_images.eddy_rotated_bvecs",data+"rm_pos1")
    trimCols(volsPos1,volsPos1+volsPos2-1,eddy+"eddy_unwarped_images.eddy_rotated_bvecs",data+"rm_pos2")
    trimCols(volsPos1+volsPos2,volsPos1+volsPos2+volsNeg1-1,eddy+"eddy_unwarped_images.eddy_rotated_bvecs",data+"rm_neg1")
    trimCols(volsPos1+volsPos2+volsNeg1,volsPos1+volsPos2+volsNeg1+volsNeg2-1,eddy+"eddy_unwarped_images.eddy_rotated_bvecs",data+"rm_neg2")
        
    # Average the vectors
    pos1 = open(data+"rm_pos1",'r')
    pos2 = open(data+"rm_pos2",'r')
    neg1 = open(data+"rm_neg1",'r')
    neg2 = open(data+"rm_neg2",'r')
    out = open(data+"bvecs",'w')
    for i in range(3):
        p1 = list(map(float, pos1.readline().replace('\n','').split(' ')))
        p2 = list(map(float, pos2.readline().replace('\n','').split(' ')))
        n1 = list(map(float, neg1.readline().replace('\n','').split(' ')))
        n2 = list(map(float, neg2.readline().replace('\n','').split(' ')))
        avg1 = [(g + h) / 2 for g, h in zip(p1, n1)]
        avg2 = [(g + h) / 2 for g, h in zip(p2, n2)]
        for val in avg1:
            out.write(str(val)+' ')
        for val in avg2:
            out.write(str(val)+' ')
        out.write('\n')
    out.close()
    neg2.close()
    neg1.close()
    pos2.close()
    pos1.close()
    
    # Delete temporary files
    os.remove(data+"rm_pos1")
    os.remove(data+"rm_pos2")
    os.remove(data+"rm_neg1")
    os.remove(data+"rm_neg2")

def final_bvecs_2(eddy,data,volsPos1,volsNeg1):
    print("**Only 75 series are present: average PA1 and AP1 bvecs**")
    trimCols(0,volsPos1-1,eddy+"eddy_unwarped_images.eddy_rotated_bvecs",data+"rm_pos1")
    trimCols(volsPos1,volsPos1+volsNeg1-1,eddy+"eddy_unwarped_images.eddy_rotated_bvecs",data+"rm_neg1")
        
    # Average the vectors
    pos1 = open(data+"rm_pos1",'r')
    neg1 = open(data+"rm_neg1",'r')
    out = open(data+"bvecs",'w')
    for i in range(3):
        p1 = list(map(float, pos1.readline().replace('\n','').split(' ')))
        n1 = list(map(float, neg1.readline().replace('\n','').split(' ')))
        avg1 = [(g + h) / 2 for g, h in zip(p1, n1)]
        for val in avg1:
            out.write(str(val)+' ')
        out.write('\n')
    out.close()
    neg1.close()
    pos1.close()
    
    # Delete temporary files
    os.remove(data+"rm_pos1")
    os.remove(data+"rm_neg1")
    
def final_bvecs_3(eddy,data,volsPos2,volsNeg2):
    print("**Only 76 series are present: average PA2 and AP2 bvecs**")
    trimCols(0,volsPos2-1,eddy+"eddy_unwarped_images.eddy_rotated_bvecs",data+"rm_pos2")
    trimCols(volsPos2,volsPos2+volsNeg2-1,eddy+"eddy_unwarped_images.eddy_rotated_bvecs",data+"rm_neg2")
        
    # Average the vectors
    pos2 = open(data+"rm_pos2",'r')
    neg2 = open(data+"rm_neg2",'r')
    out = open(data+"bvecs",'w')
    for i in range(3):
        p2 = list(map(float, pos2.readline().replace('\n','').split(' ')))
        n2 = list(map(float, neg2.readline().replace('\n','').split(' ')))
        avg2 = [(g + h) / 2 for g, h in zip(p2, n2)]
        for val in avg2:
            out.write(str(val)+' ')
        out.write('\n')
    out.close()
    neg2.close()
    pos2.close()
    
    # Delete temporary files
    os.remove(data+"rm_pos2")
    os.remove(data+"rm_neg2")
    
def nvols(filepath):
    if os.path.isfile(filepath):
        return int(os.popen("fslval "+filepath+" dim4").read().replace('\n','').replace(' ',''))
    else:
        return 0
         
def run(sbj,sess,step):
    start_time = str(datetime.datetime.today().strftime("%H:%M:%S"))
    print("postEddy start")
    
    sbjDir = f"{sbj}/{sess}/"
    eddy = sbjDir+"eddy/"
    data = sbjDir+"data/"
    topup = sbjDir+"topup/"
    preddy = sbjDir+"preEddy/"
    
    os.system("rm -rf "+data) 
    os.mkdir(data)
        
    ### Get the number of volumes for each series ###
    print("\n1. Getting the number of volumes for each series...")
    volsPos1 = int(nvols(preddy+"PA_1.nii.gz"))
    volsPos2 = int(nvols(preddy+"PA_2.nii.gz"))
    volsNeg1 = int(nvols(preddy+"AP_1.nii.gz"))
    volsNeg2 = int(nvols(preddy+"AP_2.nii.gz"))
    print("75PA,76PA,75AP,76AP: "+str(volsPos1)+','+str(volsPos2)+','+str(volsNeg1)+','+str(volsNeg2))
    
    #### Trim the bvals ####
    print("\n2. Creating final bvals...")
    # All series are present
    if volsPos1>0 and volsPos2>0 and volsNeg1>0 and volsNeg2>0:
        trimCols(0,volsPos1+volsPos2-1,eddy+"Pos_Neg.bval",data+"bvals")
    elif volsPos1>0 and volsNeg1>0:
        # Only 75 series are present
        if volsPos2==0 and volsNeg2==0:
            trimCols(0,volsPos1-1,eddy+"Pos_Neg.bval",data+"bvals")
        # Not all images are paired
        else:
            print("Not all images are paired")
            os.system("cp "+eddy+"Pos_Neg.bval "+data+"bvals")
    elif volsPos2>0 and volsNeg2>0:
        # Only 76 series are present
        if volsPos1==0 and volsNeg1==0:
            trimCols(0,volsPos2-1,eddy+"Pos_Neg.bval",data+"bvals")
        # Not all images are paired
        else:
            print("Not all images are paired")
            os.system("cp "+eddy+"Pos_Neg.bval "+data+"bvals")
    # There is only one series
    else:
        print("There is only one series")
        if volsPos1>0:
            bvals = eddy+sbj+"_3T_DWI_dir75_PA.bval"
        elif volsPos2>0:
            bvals = eddy+sbj+"_3T_DWI_dir76_PA.bval"
        elif volsNeg1>0:
            bvals = eddy+sbj+"_3T_DWI_dir75_AP.bval"
        else:
            bvals = eddy+sbj+"_3T_DWI_dir76_AP.bval"
        os.system("cp "+bvals+" "+data+"bvals")
    if not os.path.isfile(data+"bvals"):
        sys.exit("ERROR: bvals not created")
    
    ### Get the average of the rotated bvecs ####
    # Separate the bvecs for each series
    print("\n3. Creating final bvecs...")
    
    # All series are present
    if volsPos1>0 and volsPos2>0 and volsNeg1>0 and volsNeg2>0:
        final_bvecs_1(eddy,data,volsPos1,volsPos2,volsNeg1,volsNeg2)
    elif volsPos1>0 and volsNeg1>0:
        # Only 75 series are present
        if volsPos2==0 and volsNeg2==0:
            final_bvecs_2(eddy,data,volsPos1,volsNeg1)
        # Not all images are paired
        else:
            print("Not all images are paired")
            os.system("cp "+eddy+"eddy_unwarped_images.eddy_rotated_bvecs "+data+"bvecs")
    elif volsPos2>0 and volsNeg2>0:
        # Only 76 series are present
        if volsPos1==0 and volsNeg1==0:
            final_bvecs_3(eddy,data,volsPos2,volsNeg2)
        # Not all images are paired
        else:
            print("Not all images are paired")
            os.system("cp "+eddy+"eddy_unwarped_images.eddy_rotated_bvecs "+data+"bvecs")
    # Images are not paired
    else:
        print("There is only one series")
        os.system("cp "+eddy+"eddy_unwarped_images.eddy_rotated_bvecs "+data+"bvecs")
    if not os.path.isfile(data+"bvecs"):
        sys.exit("ERROR: bvecs not created")
    
    #### Remove negative intensity values (caused by spline interpolation) from final data ####
    print("\n4. Removing negative intensity values..")
    os.system("fslmaths "+eddy+"eddy_unwarped_images -thr 0 "+data+"data")
    # brain mask will not exist for 1 series because no topup was run
    print("Creating masked file...")
    if os.path.isfile(topup+"nodif_brain_mask.nii.gz"):
        os.system("cp "+topup+"nodif_brain_mask.nii.gz "+data)
    else:
        if volsPos1>0:
            mask = eddy+sbj+"_3T_DWI_dir75_PA_bet_mask.nii.gz"
        elif volsPos2>0:
            mask = eddy+sbj+"_3T_DWI_dir76_PA_bet_mask.nii.gz"
        elif volsNeg1>0:
            mask = eddy+sbj+"_3T_DWI_dir75_AP_bet_mask.nii.gz"
        else:
            mask = eddy+sbj+"_3T_DWI_dir76_AP_bet_mask.nii.gz"
        os.system("cp "+mask+" "+data+"nodif_brain_mask.nii.gz")
    os.system("fslmaths "+data+"data -mul "+data+"nodif_brain_mask "+data+"nodif_brain")
    if not os.path.isfile(data+"nodif_brain.nii.gz"):
        sys.exit("ERROR: nodif_brain not created")

    # Separate 1st b0 from data for transformation purposes
    os.system(f"fslroi {data}data {data}data_b0 0 1")
    
    print("\nDONE "+step)
    end_time = str(datetime.datetime.today().strftime("%H:%M:%S"))
    tdelta = str(datetime.datetime.strptime(end_time,"%H:%M:%S") - datetime.datetime.strptime(start_time,"%H:%M:%S")).split(':')
    hr = tdelta[0]
    if hr=='0':
        hr = "00"
    mn = tdelta[1]
    if mn =='0':
        mn = "00"
    sc = tdelta[2]
    if sc=='0':
        sc = "00"
    print("\nTotal execution time was "+hr+" hrs "+mn+" mins "+sc+" secs")

def main():
    if len(sys.argv)!=4:
        sys.exit("ERROR: wrong number of arguments")
    sbj = sys.argv[1]
    sess = sys.argv[2]
    step = sys.argv[3]
    run(sbj,sess,step)

if __name__ == "__main__":
        main()
