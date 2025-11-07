#!/bin/bash
#04_launch.sh
# Created by Julianne (Yulia) Murthy on 09/15/2025
# Usage: bash 04_launch_sort.sh

# Safety error catch
set -euo pipefail

# Create paths
projPath="/projects/daylab/yulia/ATAC-Seq_T2T_Telomere"
sortedPath="$projPath/experiments/08_25_StrackerLab/align/bam/sorted"
dedupPath="$projPath/experiments/08_25_StrackerLab/align/bam/dedup"
noMitoPath="$projPath/experiments/08_25_StrackerLab/align/bam/mito_removed"
sizePath="$projPath/experiments/08_25_StrackerLab/align/bam/size_1_100bp"
jobScript="$projPath/pipeline/bash_scripts/04_postalign_dedup_noMito_size100.sh"

# Make output paths if they dont exist already
mkdir -p "$noMitoPath" "$sizePath" "$dedupPath"

# Go to the coordinate sorted BAM path 
cd $sortedPath

# Loop that strips base name from each paired file, identifies read 1 and read 2 files, submits batch job so reads run in parallel
for file in *_sorted.bam; do
  base=$(basename "$file" _sorted.bam)
  sbatch $jobScript "$sortedPath" "$base" "$dedupPath" "$noMitoPath" "$sizePath" "$file"
done
