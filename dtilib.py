#!/usr/bin/env python3
__author__ = "Monica Keith"

import subprocess
import os
import argparse
import multiprocessing

# force each process to one thread for a more efficient use of CPUs
env = os.environ.copy()
env["OMP_NUM_THREADS"] = "1"
env["MKL_NUM_THREADS"] = "1"
env["OPENBLAS_NUM_THREADS"] = "1"

def runBashCommand(command: list):
    return subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, env=env)

#######
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

def brainExtract2(prefix: str, *, run_all=False, fsl=False, afni=False, freesurfer=False):
    prefix = prefix.removesuffix(".nii.gz").removesuffix(".nii")
    proc = extractVolume(prefix, 0)
    stdout, stderr = proc.communicate()
    if proc.returncode!=0:
        raise RuntimeError(f"fslroi failed.\nOutput: {stdout}\nError: {stderr}")

    procs = []
    if run_all or fsl:
        procs.append(runBashCommand(["bet", f"{prefix}_b0", f"{prefix}_bet", "-f", "0.1", "-g", "0", "-m"]))
    if run_all or afni:
        cmd1 = ["3dSkullStrip", "-input", f"{prefix}_b0", "-prefix", f"{prefix}_sklstrip.nii.gz"]
        cmd2 = ["3dcalc", "-a", f"{prefix}_sklstrip.nii.gz", "-expr", "step(a)", "-prefix", f"{prefix}_sklstrip_mask.nii.gz"]
        procs.append(runPipelineParallel(runPipeline,[cmd1, cmd2]))
    if run_all or freesurfer:
        procs.append(runBashCommand(["mri_synthstrip", "-i", f"{prefix}_b0.nii.gz", "-o", f"{prefix}_free.nii.gz"]))
    
    return procs
#######

def extractVolume(prefix: str, vol: int):
    return runBashCommand(["fslroi", prefix, f"{prefix}_b0", "0", "-1", "0", "-1", "0", "-1", str(vol), "1"])

# All parameters after * must be passed as keyword arguments
def brainExtract(prefix: str, *, run_all=False, fsl=False, afni=False, freesurfer=False):
    prefix = prefix.removesuffix(".nii.gz").removesuffix(".nii")
    proc = extractVolume(prefix, 0)
    stdout, stderr = proc.communicate()
    if proc.returncode!=0:
        raise RuntimeError(f"fslroi failed.\nOutput: {stdout}\nError: {stderr}")

    procs = []
    if run_all or fsl:
        procs.append(runBashCommand(["bet", f"{prefix}_b0", f"{prefix}_bet", "-f", "0.1", "-g", "0", "-m"]))
    if run_all or afni:
        #cmd2 = ["3dcalc", "-a", f"{prefix}_sklstrip.nii.gz", "-expr", "step(a)", "-prefix", f"{prefix}_sklstrip_mask.nii.gz"]
        procs.append(runBashCommand(["3dSkullStrip", "-overwrite", "-input", f"{prefix}_b0.nii.gz", "-prefix", f"{prefix}_sklstrip.nii.gz"]))
    if run_all or freesurfer:
        procs.append(runBashCommand(["mri_synthstrip", "-i", f"{prefix}_b0.nii.gz", "-o", f"{prefix}_free.nii.gz"]))
    
    return procs

def read_args():
    parser = argparse.ArgumentParser(description="Diffusion Imaging pipeline")

    parser.add_argument("--extract", type=str, help="Comma-separated list of NIFTI files to brain extract")

    parser.add_argument("--all-soft", action="store_true", help="Use all available software")
    parser.add_argument("--fsl", action="store_true", help="Use FSL if available")
    parser.add_argument("--afni", action="store_true", help="Use AFNI if available")
    parser.add_argument("--freesurfer", action="store_true", help="Use FreeSurfer if available")

    parser.add_argument("--max-procs", type=int, default=1, help="Max number of simultaneous processes (0=unlimited)")

    return parser.parse_args()

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

def main():
    args = read_args()

    if args.extract:
        brains = [b.strip() for b in args.extract.split(",") if b.strip()]
        
        procs = []
        for brain in brains:
            if not os.path.isfile(brain):
                continue
            new_procs = brainExtract2(brain, run_all=args.all_soft, fsl=args.fsl, afni=args.afni, freesurfer=args.freesurfer)

            for p in new_procs:
                throttle(procs, args.max_procs)
                procs.append(p)

        # Wait for all processes to finish
        for proc in procs:
            wait(proc)

if __name__ == "__main__":
	main()