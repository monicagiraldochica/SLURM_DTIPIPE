#!/usr/bin/env python3
__author__ = "Monica Keith"
__status__ = "Development"
__purpose__ = "Analyze DTI data"

import subprocess
import os
import argparse
import multiprocessing
import sys

# Force each process to one thread for a more efficient use of CPUs
env = os.environ.copy()
env["OMP_NUM_THREADS"] = "1"
env["MKL_NUM_THREADS"] = "1"
env["OPENBLAS_NUM_THREADS"] = "1"

def runBashCommand(command: list):
    return subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, env=env)

def runPipeline(commands: list):
    for command in commands:
        proc = runBashCommand(command)
        out, err = proc.communicate()
        if proc.returncode!=0:
            print(f"Process failed (PID {proc.pid})\nCommand: {proc.args}\nOutput: {out}\nError: {err}")

def runPipelineParallel(target, *args):
    p = multiprocessing.Process(target=target, args=args)
    p.start()
    return p

def extractVolume(prefix: str, vol: int):
    return runBashCommand(["fslroi", prefix, f"{prefix}_b0", "0", "-1", "0", "-1", "0", "-1", str(vol), "1"])

def getVols(nifti: str):
    proc = runBashCommand(["fslval", nifti, "dim4"])
    stdout, stderr = proc.communicate()
    if proc.returncode!=0:
        print(f"ERROR: could not read the number of volumes.\nCommand: {proc.args}\nOutput: {stdout}\nError: {stderr}")
        return 0
    
    out = stdout.strip()
    try:
        return int(out)
    except ValueError:
        print(f"ERROR: non-integer value from fslval: {out}")
        return 0

def brainExtractNIFTI(brain_path: str, *, run_all: bool=False, fsl: bool=False, afni: bool=False, freesurfer: bool=False, skip4Dmasking: bool=True):
    orig_prefix = brain_path.removesuffix(".nii.gz").removesuffix(".nii")

    # Get number of volumes
    n_vols = getVols(f"{orig_prefix}.nii.gz")
    if n_vols==0:
        return []
    
    # Extract first volume if it's 4D file
    if n_vols>1:        
        proc = extractVolume(orig_prefix, 0)
        stdout, stderr = proc.communicate()
        if proc.returncode!=0:
            print(f"ERROR: fslroi failed, could not brain extract.\nCommand: {proc.args}\nOutput: {stdout}\nError: {stderr}")
            return []
        prefix = f"{orig_prefix}_b0"
    else:
        prefix = orig_prefix

    # Create brain extract processes
    procs = []
    if run_all or fsl:
        cmd1 = ["bet", prefix, f"{prefix}_bet", "-f", "0.1", "-g", "0", "-m"]
        if n_vols==1 or skip4Dmasking:
            procs.append(runBashCommand(cmd1))
        else:
            cmd2 = ["fslmaths", f"{prefix}_bet_mask", "-bin", "-mul", brain_path, f"{orig_prefix}_bet"]
            procs.append(runPipelineParallel(runPipeline, [cmd1, cmd2]))

    if run_all or afni:
        cmd1 = ["3dSkullStrip", "-overwrite", "-input", f"{prefix}.nii.gz", "-prefix", f"{prefix}_sklstrip.nii.gz"]
        cmd2 = ["3dcalc", "-a", f"{prefix}_sklstrip.nii.gz", "-expr", "step(a)", "-prefix", f"{prefix}_sklstrip_mask.nii.gz"]
        cmd3 = ["3dcalc", "-a", brain_path, "-b", f"{prefix}_sklstrip_mask.nii.gz", "-expr", "step(b)*a", "-prefix", f"{orig_prefix}_sklstrip_mask.nii.gz"]
        if n_vols==1 or skip4Dmasking:
            procs.append(runPipelineParallel(runPipeline, [cmd1, cmd2]))
        else:
            procs.append(runPipelineParallel(runPipeline, [cmd1, cmd2, cmd3]))

    if run_all or freesurfer:
        cmd1 = ["mri_synthstrip", "-i", f"{prefix}.nii.gz", "-o", f"{prefix}_free.nii.gz", "-m", f"{prefix}_free_mask.nii.gz"]
        if n_vols==1 or skip4Dmasking:
            procs.append(runBashCommand(cmd1))
        else:
            cmd2 = ["mri_mask", brain_path, f"{prefix}_free_mask.nii.gz", f"{orig_prefix}_free_mask.nii.gz"]
            procs.append(runPipelineParallel(runPipeline, [cmd1, cmd2]))
    
    return procs

def is_finished(p: subprocess.Popen | multiprocessing.Process):
    if isinstance(p, subprocess.Popen):
        return p.poll() is not None
    
    return not p.is_alive()

def wait(p: subprocess.Popen | multiprocessing.Process):
    if isinstance(p, subprocess.Popen):
        stdout, stderr = p.communicate()
        if p.returncode!=0:
            print(f"Process failed (PID {p.pid})\nCommand: {p.args}\nOutput: {stdout}\nError: {stderr}")

    else:
        p.join()

def throttle(procs, max_procs):
    if max_procs<=0:
        return
    
    while len(procs)>=max_procs:
        for p in procs:
            if is_finished(p):
                wait(p)
                procs.remove(p)
                return
            
        # Nothing finished yet, block on the first one
        wait(procs[0])
        procs.pop(0)

def read_args():
    parser = argparse.ArgumentParser(description="Diffusion Imaging pipeline")

    parser.add_argument("--extract", type=str, help="Comma-separated list of NIFTI files to brain extract")
    parser.add_argument("--mask4D", action="store_true", help="Apply mask to each of the volumes in the 4D file")

    parser.add_argument("--all-soft", action="store_true", help="Use FSL, AFNI and FreeSurfer")
    parser.add_argument("--fsl", action="store_true", help="Use FSL")
    parser.add_argument("--afni", action="store_true", help="Use AFNI")
    parser.add_argument("--freesurfer", action="store_true", help="Use FreeSurfer")

    parser.add_argument("--max-procs", type=int, default=1, help="Max number of simultaneous processes (0=unlimited)")

    return parser.parse_args()

def checkPythonVers(req_major: int=0, req_minor: int=0, req_micro: int=0, exact_vers: bool=False):
    python_info = sys.version_info
    major = python_info.major or 0
    minor = python_info.minor or 0
    micro = python_info.micro or 0
    print(f"Python version: {major}.{minor}.{micro}")
 
    if (not exact_vers) and (major<req_major or (major==req_major and minor<req_minor) or (major==req_major and minor==req_minor and micro<req_micro)):
        return False, major, minor, micro
    if exact_vers and (major!=req_major or minor!=req_minor or micro!=req_micro):
        return False, major, minor, micro
    return True, major, minor, micro

def main():
    #if not checkPythonVers(3, 12, 10)[0]:
    #    print("ERROR: This program needs python/3.12.10")
    #    sys.exit(1)

    args = read_args()
    all_soft = args.all_soft
    fsl = args.fsl
    afni = args.afni
    freesurfer = args.freesurfer
    mask4D = args.mask4D

    print(getVols("/scratch/g/rccadmin/mkeith/niftis/EC1113_3T_DWI_dir76_AP.nii.gz"))
    proc = runBashCommand(["bash", "-lc", "module list"])
    stdout, stderr = proc.communicate()
    print(f"stdout:{stdout}*")
    print(f"stderr:{stderr}*")
    print(f"code:{proc.returncode}*")

    #ml_list = runBashCommand(["fslstats", "-h"])
    #print(f"*{ml_list}*")

    #if all_soft or fsl:
    #    print(f"fsl_vers: {fsl_vers}")

    #if all_soft or afni:
    #    print(f"afni_vers: {afni_vers}")

    #if all_soft or freesurfer:\
    #    print(f"freesurfer_vers: {freesurfer_vers}")
    sys.exit(0)

    if args.extract:
        brains = [b.strip() for b in args.extract.split(",") if b.strip()]
        
        procs = []
        for brain in brains:
            if not os.path.isfile(brain):
                continue
            new_procs = brainExtractNIFTI(brain, run_all=all_soft, fsl=fsl, afni=afni, freesurfer=freesurfer, skip4Dmasking=(not mask4D))

            for p in new_procs:
                throttle(procs, args.max_procs)
                procs.append(p)

        # Wait for all processes to finish
        for proc in procs:
            wait(proc)

if __name__ == "__main__":
	main()