#!/bin/bash
#06_launch.sh
# Created by Julianne (Yulia) Murthy on 09/15/2025
# Usage: bash 06_launch.sh
set -euo pipefail

# Define file paths
proj="/projects/daylab/yulia/ATAC-Seq_T2T_Telomere"
inPath="$proj/experiments/08_25_StrackerLab/merge"
outPath="$proj/experiments/08_25_StrackerLab/signal_bigwig_RPGC"
jobScript="$proj/pipeline/bash_scripts/06_make_rpgc_bigwigs.sh"
mkdir -p "$outPath"

# Launch script for each bam
for bam in "$inPath"/*.bam; do
  sbatch "$jobScript" "$bam" "$outPath"
done
