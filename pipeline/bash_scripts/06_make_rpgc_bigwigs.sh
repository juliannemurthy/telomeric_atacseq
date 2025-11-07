#!/bin/bash
#SBATCH --job-name=bamCoverage_RPGC
#SBATCH --time=4:00:00
#SBATCH --mem=24G
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

# Define paths
bam="$1"
outDir="$2"
effSize=3114496530  # CHM13 v2 maskedY effective genome size found with ->  grep -v '^>' chm13v2.0_maskedY.fa | tr -d '\nNn' | wc -c
base=$(basename "$bam" .bam)
bWig="$outDir/${base}.RPGC.bs1.bw"

# Run bamCoverage from deepTools with parameter options
	# normalize using reads per genomic content, tracks comparable regardless of sequencing depth
	# ^ requires effective genome size of non-N mappanle bases in reference for rpgc scaling
	# ignore reads flagged as duplicates
	# binsize 1 bp for high resolution 
	bamCoverage \
  --bam "$bam" \
  --outFileName "$bWig" \
  --outFileFormat bigwig \
  --normalizeUsing RPGC \
  --effectiveGenomeSize "$effSize" \
  --ignoreDuplicates \
  --binSize 1 \
  --numberOfProcessors "$SLURM_CPUS_PER_TASK"

