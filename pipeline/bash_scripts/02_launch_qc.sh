#!/bin/bash
#02_launch_qc.sh
# Created by Julianne (Yulia) Murthy on 09/15/2025
# This script serves to launch the FASTQC jobs in parallel on all files.
# Usage: bash 02_launch_qc.sh

# Safety error catch
set -euo pipefail

# Create paths
projPath="/projects/daylab/yulia/ATAC-Seq_T2T_Telomere"
trimmedPath="$projPath/experiments/08_25_StrackerLab/trimmed"
outputPath="$projPath/experiments/08_25_StrackerLab/qc"
jobScript="$projPath/pipeline/bash_scripts/02_run_qc.sh"

# Make output path if it doesnt exist already
mkdir -p "$outputPath"

# Go to the path 
cd "$trimmedPath"

# Loop that sends each file for FASTQC analysis using sbatch
# View results by looking at sbatch err and log files 
for file in *.fastq.gz; do
  sbatch $jobScript "$trimmedPath" "$outputPath" "$file"
done
