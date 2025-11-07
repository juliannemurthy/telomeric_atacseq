#!/bin/bash
#03_launch_align.sh
# Created by Julianne (Yulia) Murthy on 09/15/2025
# Usage: bash 03_launch_align.sh

# Safety error catch
set -euo pipefail

# Create paths
projPath="/projects/daylab/yulia/ATAC-Seq_T2T_Telomere"
trimmedPath="$projPath/experiments/08_25_StrackerLab/trimmed"
alignedPath="$projPath/experiments/08_25_StrackerLab/align"
jobScript="$projPath/pipeline/bash_scripts/03_align_bowtie2.sh"

# Make output path if it doesnt exist already
mkdir -p "$alignedPath"

# Go to the trimmed fastq path 
cd $trimmedPath

# Loop that strips base name from each paired file, identifies read 1 and read 2 files, submits batch job so reads run in parallel
for R1 in *_R1.trimmed.fastq.gz; do
  base=$(basename "$R1" _R1.trimmed.fastq.gz)
  R2="${base}_R2.trimmed.fastq.gz"
  sbatch $jobScript "$trimmedPath/$R1" "$trimmedPath/$R2" "$base" "$alignedPath"
done
