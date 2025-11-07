#!/bin/bash
#SBATCH --job-name=lock_order_plot
#SBATCH --time=2:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=8
#SBATCH --partition=short
#SBATCH --output=/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/experiments/08_25_StrackerLab/slurm_logs/%x_%j.out
#SBATCH --error=/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/experiments/08_25_StrackerLab/slurm_logs/%x_%j.err

# Created by Julianne (Yulia) Murthy on 09/15/2025
# Purpose: need to loc row order so heatmaps are visually comparable. because in the previous plots each of the row numbers may not be the same gene
	#  Avoid this by choosing a reference sample - the control. Sort once descending by signal in control and save the sorted region order, then apply the same row order to the other sample matrix. now row 1 can be the same TSS as row 1 in the other sample

# Safety error catch
set -euo pipefail

# Activate conda environment
source /etc/profile.d/modules.sh
module load anaconda3
eval "$(conda shell.bash hook)"
conda activate atacseq_env

control_mat="$1"  # the control matrix .gz file
matsDir="$2"      # directory with the matrices
sortedBed="$3"    # output the BED of regions in control's sort order
sortedDir="$4"    # output dir for sorted matrices
heatmapDir="$5"   # output dir for final heatmaps

mkdir -p "$(dirname "$sortedBed")" "$sortedDir" "$heatmapDir"
preview="$sortedDir/control_sort_preview.pdf"

# Export region order from control with descending signal
plotHeatmap -m "$control_mat" --sortRegions descend \
--outFileSortedRegions "$sortedBed" \
-o "$preview"  # only want the BED here

# Resort every matrix to the control order
for mat in "$matsDir"/*.matrix.gz; do
  base=$(basename "$mat" .matrix.gz)
  outMat="$sortedDir/${base}.sortedToControl.matrix.gz"
  computeMatrixOperations sort -R "$sortedBed" -m "$mat" -o "$outMat" 
  
  # Finalized heatmaps with identical locked row order
  plotHeatmap \
  -m "$outMat" \
  -o "$heatmapDir/${base}.sortedToControl.heatmap.pdf" \
  --colorMap RdBu \
  --plotType lines --averageTypeSummaryPlot mean \
  --refPointLabel TSS --startLabel '-2 kb' --endLabel '+2 kb' \
  --samplesLabel "$base" \
  --zMin 0 --zMax 40 \
  --dpi 300 \
  --heatmapHeight 12 \
  --heatmapWidth 6 
  
done

echo "[OK] Sorted bed: $sortedBed"
