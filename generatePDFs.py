#!/usr/bin/env python3
# -*- coding: utf-8 -*-
__author__ = "Monica Keith"
__status__ = "Production"
__purpose__ = "Generate PDFs with QC"

import sys
import mrilib
import fileslib
import os

def generateAxialPDF(brain,masks,pdf_out):
    print("\nGenerating axial PDF (this will take a while)...")
    if len(masks)==1:
        mrilib.fsleyesPDF_maskN(brain,masks,pdf_out,False,colors_opt=["red-yellow"])
    else:
        mrilib.fsleyesPDF_maskN(brain,masks,pdf_out,False)
    
    if os.path.isfile(pdf_out):
        print("done: "+pdf_out)
        return pdf_out
    return ""
    
def generateCoronalPDF(brain,masks,pdf_out):
    print("\nGenerating coronal PDF (this will take a while)...")
    mrilib.fsleyesPDF_probtrackX_3(brain,masks[1:],pdf_out,masks[0])
    
    if os.path.isfile(pdf_out):
        print("done: "+pdf_out)
        return pdf_out
    return ""
    
def generateSagittalPDF(brain,masks,pdf_out):
    print("\nGenerating sagittal PDF (this will take a while)...")
    mrilib.fsleyesPDF_probtrackX_2(brain,masks[1:],pdf_out,masks[0])
    
    if os.path.isfile(pdf_out):
        print("done: "+pdf_out)
        return pdf_out
    return ""
    
def mergePDF(views_pdfs,pdf_out):
    print("\nMerging PDFs...")
    fileslib.mergeVerticalImgsPDF(views_pdfs,pdf_out,True)
    
    if os.path.isfile(pdf_out):
        print("done: "+pdf_out)
        return pdf_out
    return ""
    
def main():
    axial = ""
    coronal = ""
    sagittal = ""
    brain = ""
    masks = []
    merged_pdf = ""
    views_pdfs = []
    
    for i in range(1,len(sys.argv)):
        arg = sys.argv[i]
        if arg.startswith("--axial="):
            axial = arg.replace("--axial=","")
            views_pdfs+=[axial]
        elif arg.startswith("--coronal="):
            coronal = arg.replace("--coronal=","")
            views_pdfs+=[coronal]
        elif arg.startswith("--sagittal="):
            sagittal = arg.replace("--sagittal=","")
            views_pdfs+=[sagittal]
        elif arg.startswith("--brain="):
            brain = arg.replace("--brain=","")
        elif arg.startswith("--masks="):
            masks = arg.replace("--masks=","").split(",")
        elif arg.startswith("--merged_pdf="):
            merged_pdf = arg.replace("--merged_pdf=","")
    
    if len(views_pdfs)==0:
        sys.exit("You have to select at least one view")
    if brain=="":
        sys.exit("You must input a brain")
    
    dic = {}
    n = 0
    if axial!="":
        if generateAxialPDF(brain,masks,axial)=="":
            sys.exit("Error generating axial view")
        dic[n] = "axial"
        n+=fileslib.getNumPages(axial)
    
    if coronal!="":
        if generateCoronalPDF(brain,masks,coronal)=="":
            sys.exit("Error generating coronal view")
        dic[n] = "coronal"
        n+=fileslib.getNumPages(coronal)
    
    if sagittal!="":
        if generateSagittalPDF(brain,masks,sagittal)=="":
            sys.exit("Error generating sagittal view")
        dic[n] = "sagittal"
        n+=fileslib.getNumPages(sagittal)
    
    if merged_pdf!="":
        if mergePDF(views_pdfs,merged_pdf)=="":
            sys.exit("Error merging PDFs")
            
        merged_pdf_tmp = merged_pdf.replace(".pdf","_tmp.pdf")
        os.system("mv "+merged_pdf+" "+merged_pdf_tmp)
        fileslib.addSimpleOutline(merged_pdf_tmp,merged_pdf,dic,True)

if __name__ == "__main__":
    main()