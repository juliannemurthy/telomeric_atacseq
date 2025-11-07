#!/bin/bash
#SBATCH --job-name=merge1_100_reps
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

# Input file paths
tsvFile="$1"   # the samples.tsv file with all the file paths/names
condName="$2"  # The condition name
outDir="$3"   # output dir
mkdir -p "$outDir"

# collect BAMs for this condition (column 3)
	# iterates on each BAM path, skips empty lines, appends to bash array
	# condName conditions is passed into awk , ensures no header and column 2 filtering, print bam path for those rows
bams=()
while IFS= read -r bam; do
  [[ -n "$bam" ]] || continue
  bams+=("$bam")
done < <(awk -F '[\t ]+' -v c="$condName" 'NR>1 && $2==c {print $3}' "$tsvFile")

# Define merged outfiles
merged="$outDir/${condName}_frag1_100_merged.bam"

# -c: Combine @RG headers with colliding IDs [alter IDs to be distinct]
# -p: Combine @PG headers with colliding IDs [alter IDs to be distinct]
# -f: Overwrite the output BAM if exists
samtools merge -@ "$SLURM_CPUS_PER_TASK" -c -p -f "$merged" "${bams[@]}"
samtools index -@ "$SLURM_CPUS_PER_TASK" "$merged"
