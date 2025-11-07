#!/bin/bash
#08_launch.sh
# Created by Julianne (Yulia) Murthy on 09/15/2025
# Usage: bash 08_launch.sh
set -euo pipefail

# The paths 
proj="/projects/daylab/yulia/ATAC-Seq_T2T_Telomere"
mats="$proj/experiments/08_25_StrackerLab/matrices/per_condition"
outSorted="$proj/experiments/08_25_StrackerLab/matrices/sorted_across_all"
outBed="$proj/experiments/08_25_StrackerLab/matrices/control_sorted_regions.bed"
outHeatmap="$proj/experiments/08_25_StrackerLab/heatmaps/TSS_pm2kb"
jobScript="$proj/pipeline/bash_scripts/08_lock_region_order_plot.sh"
mkdir -p "$outSorted" "$outHeatmap"

# choose the control matrix filename (adjust if name differs)
control_mat="$mats/ctrl_frag1_100_merged.RPGC.bs1.TSSpm2kb.bs20.matrix.gz"

sbatch "$jobScript" "$control_mat" "$mats" "$outBed" "$outSorted" "$outHeatmap"
