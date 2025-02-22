#!/bin/bash
#SBATCH --job-name=rkeras_test
#SBATCH --partition=dgx12cluster
#SBATCH --account=dctv_dgx
#SBATCH --output=output_%j.txt
#SBATCH --error=errors_%j.txt
#SBATCH --mail-user=corrado.lanera@unipd.it
#SBATCH --mail-type=ALL
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --gres=gpu:2
#SBATCH --mem=1G
#SBATCH --time=00:05

# Load necessary modules
module load go/1.22.7
module load singularity/4.2.0
module load slurm/slurm/23.02.7

echo "Running on $SLURM_NTASKS task(s) with GPUs: $SLURM_JOB_GPUS"
echo "CUDA_VISIBLE_DEVICES = $CUDA_VISIBLE_DEVICES"
echo "Singularity path: $(which singularity)"

# Change to the directory from where the job was submitted
cd "$SLURM_SUBMIT_DIR"

# Use the environment variable SIF_FILE if provided; otherwise default to proj_latest.sif.
SIF=${SIF_FILE:-"/mnt/projects/dctv/dgx/u0043/proj/proj_latest.sif"}

# Run the container using singularity with GPU support
srun /cm/shared/apps/singularity/4.2.0/bin/singularity exec --nv "$SIF" Rscript run.R

