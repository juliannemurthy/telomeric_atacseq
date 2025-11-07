#!/bin/bash
#SBATCH --nodes=1
#SBATCH --job-name=Run_QC
#SBATCH --time=10:00:00
#SBATCH --mem=10G
#SBATCH --partition=short
#SBATCH --output=/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/experiments/08_25_StrackerLab/slurm_logs/%x_%j.out
#SBATCH --error=/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/experiments/08_25_StrackerLab/slurm_logs/%x_%j.err

# Created by Julianne (Yulia) Murthy on 09/15/2025
# This script runs FastQC
# Usage: bash 02_launch_qc.sh

# Safety error catch
set -euo pipefail

# Activate conda environment
source /etc/profile.d/modules.sh
module load fastqc/0.12.1 OpenJDK/22.0.2 perl/5.40.0

# Load in paths
inputPath=$1
outputPath=$2
inputFile=$3
	
# Run FASTQC, it will output results to output path 
# Check the quality by clicking on the output html in OOD. 
fastqc -o $outputPath -f fastq $inputPath/$inputFile
