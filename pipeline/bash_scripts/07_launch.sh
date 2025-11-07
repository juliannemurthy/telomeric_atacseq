#!/bin/bash
#07_launch.sh
# Created by Julianne (Yulia) Murthy on 09/15/2025
# Usage: bash 07_launch.sh
set -euo pipefail
proj="/projects/daylab/yulia/ATAC-Seq_T2T_Telomere"
bWigDir="$proj/experiments/08_25_StrackerLab/signal_bigwig_RPGC"
tssFile="$proj/refs/hs1.ncbiRefSeq_transcriptonly.gtf"
outMatrix="$proj/experiments/08_25_StrackerLab/matrices/per_condition"
outHeatmap="$proj/experiments/08_25_StrackerLab/heatmaps/TSS_pm2kb"
jobScript="$proj/pipeline/bash_scripts/07_tss_matrices_heatmaps.sh"
mkdir -p "$outMatrix" "$outHeatmap"

for bWig in "$bWigDir"/*.bw; do
  sbatch "$jobScript" "$bWig" "$tssFile" "$outMatrix" "$outHeatmap"
done
