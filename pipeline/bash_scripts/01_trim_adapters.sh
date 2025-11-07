#!/bin/bash
#SBATCH --job-name=Trim_Adapters
#SBATCH --time=2:00:00
#SBATCH --mem=8G
#SBATCH --partition=short
#SBATCH --cpus-per-task=8
#SBATCH --output=/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/experiments/08_25_StrackerLab/slurm_logs/%x_%j.out
#SBATCH --error=/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/experiments/08_25_StrackerLab/slurm_logs/%x_%j.err

# Created by Julianne (Yulia) Murthy on 09/15/2025
# This script trims adapters off paired end fastq data for ATAC-seq analysis pipeline
# Usage: bash 01_launch_trim.sh

# Safety error catch
set -euo pipefail

# Activate conda environment containing fastp
source /etc/profile.d/modules.sh
module load anaconda3
eval "$(conda shell.bash hook)"
conda activate atacseq_env

# Pass in the paths
R1="$1"
R2="$2"
name="$3"
trimmedPath="$4"

# Use fastp for adapter trimming
	# detects adapters for paired end 
fastp \
  -i "$R1" \
  -I "$R2" \
  -o "$trimmedPath/${name}_R1.trimmed.fastq.gz" \
  -O "$trimmedPath/${name}_R2.trimmed.fastq.gz" \
  --detect_adapter_for_pe \
  --thread 8 \
  --html "$trimmedPath/${name}_fastp.html"
