# Diffusion Tensor Imaging (DTI) Processing Pipeline

This repository contains scripts used to preprocess and analyze Diffusion Tensor Imaging (DTI) data.  

Some scripts are designed to run in the Terminal, while others (the ones ending in `_slurm`) are meant to be submitted as **SLURM batch jobs** on an HPC cluster.

The purpose of this repo is to keep your DTI workflow organized and provide ready‑to‑use examples for both local and cluster‑based processing

## Repository Structure

### **1. Standard terminal scripts**
These scripts run on any regular Linux/macOS terminal.

They are typically used for:
- Preparing input folders  
- Running preprocessing steps  
- Tensor fitting  
- Generating scalar maps  
- Organizing outputs  

Run them with:

```bash
bash scriptname.sh
``

### **2. SLURM batch scripts (_slurm)**
Scripts ending in _slurm are intended for HPC clusters that use the SLURM scheduler.

These scripts include #SBATCH directives and are submitted with:
```bash
sbatch scriptname_slurm.sh
```

They are typically used for:
- Large datasets
- Parallel processing
- High‑memory or multi‑CPU tasks
- Running multiple subjects efficiently

Your specific environment may vary, but common dependencies include:
- FSL (e.g., eddy, bet, dtifit)
- MRtrix3
- Python 3

## How to Use This Repository

### 1. Clone the repo
```bash
git clone https://github.com/monicagiraldochica/SLURM_DTIPIPE
cd SLURM_DTIPIPE
```

### 2. Run local scripts
- Make sure paths match your environment.
- Run them directly in your terminal.

### 3. Run SLURM scripts
- Update SLURM settings (--time, --cpus-per-task, --mem, --partition, email, etc.).
- Submit jobs with:
```bash
sbatch scriptname_slurm.sh
```

## Purpose of This Repository
This repo serves as:

- A place to store and organize DTI pipeline scripts
- A practical reference for running DTI steps on SLURM HPC clusters
- A collection of reusable commands that can be adapted for new datasets

It is not intended to be a full automated framework—just a set of reliable scripts you can reuse and modify as needed.

## Notes
- Some scripts may need custom paths depending on your cluster layout.
- SLURM resources should be tuned to your dataset size.
- If your cluster uses environment modules, load them before running scripts, e.g.:
```bash
module load FSL
module load mrtri
```
