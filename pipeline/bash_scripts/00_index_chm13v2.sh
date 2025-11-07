#!/bin/bash
#SBATCH --job-name=Genome_Indexing
#SBATCH --time=15:00:00
#SBATCH --mem=50G
#SBATCH --partition=short
#SBATCH --cpus-per-task=10
#SBATCH --output=/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/experiments/08_25_StrackerLab/slurm_logs/%x_%j.out
#SBATCH --error=/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/experiments/08_25_StrackerLab/slurm_logs/%x_%j.err

# Created by Julianne (Yulia) Murthy on 10/15/2024
# This script indexes the chm13v2.0 fasta genome file with bowtie2. 
	# Here we use the chm13v2.0_maskedY.fa file since with short read mapping its recommended to have PARs on chrY hard masked to "N"
	# https://github.com/marbl/CHM13?tab=readme-ov-file
# Usage: sbatch 00_index_chm13v2.sh

# Safety error catch
set -euo pipefail

# Activate conda environment containing bowtie2
source /etc/profile.d/modules.sh
module load anaconda3
eval "$(conda shell.bash hook)"
conda activate atacseq_env

# Create paths
projPath="/projects/daylab/yulia/ATAC-Seq_T2T_Telomere"
genomePath="$projPath/refs/chm13v2.0"
indexPath="$projPath/refs/chm13v2.0/chm13v2_index"

# Make output path if it doesnt exist already
mkdir -p "$indexPath"

# Index genome with bowtie2 build command
bowtie2-build \
  --threads "${SLURM_CPUS_PER_TASK:-10}" \
  "$genomePath/chm13v2.0_maskedY.fa" \
  "$indexPath"
