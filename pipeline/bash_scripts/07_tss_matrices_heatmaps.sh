#!/bin/bash
#SBATCH --job-name=matrix_TSS
#SBATCH --time=2:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=8
#SBATCH --partition=short
#SBATCH --output=/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/experiments/08_25_StrackerLab/slurm_logs/%x_%j.out
#SBATCH --error=/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/experiments/08_25_StrackerLab/slurm_logs/%x_%j.err

# Created by Julianne (Yulia) Murthy on 09/15/2025

# Safety error catch
set -euo pipefail

# Activate conda environment
source /etc/profile.d/modules.sh
module load anaconda3
eval "$(conda shell.bash hook)"
conda activate atacseq_env

bWig="$1"
tssFile="$2"
outMatrix="$3" 
outHeatmap="$4"
base=$(basename "$bWig" .bw)
mat="$outMatrix/${base}.TSSpm2kb.bs20.matrix.gz"

# compute matrix reference point mode, each region in the annotation file is anchored at a single point, being the TSS
# takes window 2kb upstream and 2kb downstream of the TSS
# bin size 20 bp. each region becomes 4000/20 = 200 bins/columns. each matrix cell is mean bigwig value over the bin
# missing data as zero treats bins with no coverage as 0 not NA
# output matrix has header with sample names, params, a litof regions, numberic matrix where rows are regions and columns are bins
computeMatrix reference-point \
  --referencePoint TSS \
  -b 2000 -a 2000 -bs 20 \
  --missingDataAsZero \
  -R "$tssFile" -S "$bWig" \
  --numberOfProcessors "$SLURM_CPUS_PER_TASK" \
  -o "$mat"

# quick heatmap where rows = regions, columns= bins, color= average signal per bin
plotHeatmap -m "$mat" \
-o "$outHeatmap/${base}.heatmap.pdf" \
--colorMap RdBu \
--plotType lines --averageTypeSummaryPlot mean \
--refPointLabel TSS --startLabel '-2 kb' --endLabel '+2 kb' \
--samplesLabel "$base" \
--zMin 0 --zMax 40 \
--dpi 300 \
--heatmapHeight 12 \
--heatmapWidth 6

echo "[OK] $mat"
