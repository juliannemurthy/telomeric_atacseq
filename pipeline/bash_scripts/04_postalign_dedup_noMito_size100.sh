#!/bin/bash
#SBATCH --nodes=1
#SBATCH --job-name=postalign_dedup_noMito_size100.sh
#SBATCH --time=12:00:00
#SBATCH --mem=60G
#SBATCH --cpus-per-task=12
#SBATCH --partition=short
#SBATCH --output=/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/experiments/08_25_StrackerLab/slurm_logs/%x_%j.out
#SBATCH --error=/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/experiments/08_25_StrackerLab/slurm_logs/%x_%j.err

# Created by Julianne (Yulia) Murthy on 09/15/2025
# This script filters out PCR duplicates with Picard, removes mitochondrial reads, and selects 1-100 bp fragments 
# Usage: bash 04_launch_sort.sh

# Safety error catch
set -euo pipefail

# Activate conda environment
source /etc/profile.d/modules.sh
module load anaconda3
eval "$(conda shell.bash hook)"
conda activate atacseq_env

# Pass in the paths
inPath=$1 # directory with original sorted bams post-alignment
base=$2
dedupPath=$3
noMitoPath=$4
sizePath=$5
inFile=$6
tmp="$noMitoPath/tmp"
mkdir -p "$tmp"

# Add RGs (one-time per BAM)
picard AddOrReplaceReadGroups \
  -I "$inPath/$inFile" \
  -O "$dedupPath/${base}.rg.bam" \
  -RGID "$base" -RGLB "lib1" -RGPL "ILLUMINA" -RGPU "$base" -RGSM "$base" \
 

# Mark and remove PCR duplicates with Picard using coordinate sorted BAMs
 picard MarkDuplicates -I "$dedupPath/${base}.rg.bam" \
 -O "$dedupPath/${base}_dedup.bam" \
 -M "$dedupPath/${base}.picard.metrics.txt" \
 -REMOVE_DUPLICATES true \
 -ASSUME_SORTED true

# Remove mitochondrial reads by stripping lines with the mito contig safely
	# samtools view -h streams BAM as SAM text, with headers
	# awk recieves SAM line and prints headers unchanged, lines that start with @ (^@). The third column ($3) is reference name (RNAME) column -> keep only mapped reads ($3!="*") & drop any reads which RNAME matches regex in re:'^chrM$' ($3 !~ re)
	# regular expression matches exactly chrM notation. ^ and $ hold down the match so substrings won't be triggered. Covers mitochondrial contig names
	# samtools sort the noMito bams by coordinate
samtools view -@ "$SLURM_CPUS_PER_TASK" -h "$dedupPath/${base}_dedup.bam" \
| awk -v re="^chrM$" 'BEGIN{OFS="\t"} /^@/ {print; next} { if ($3!="*" && $3 !~ re) print }' \
| samtools sort -@ "$SLURM_CPUS_PER_TASK" -O BAM -T "$tmp/${base}" -o "$noMitoPath/${base}_noMito.bam"
samtools index -@ "$SLURM_CPUS_PER_TASK" "$noMitoPath/${base}_noMito.bam"

# Select 1-100 bp fragments with samtools and sort it with samtools
	# require flag 3 -f: read is paired, read is properly paired 1+2=3
	# exclude flag -F 3852 if present: read unmapped (4), mate unmapped (8), secondary alignment (256), qc fail (512), duplicate (1024), supplementary alignment (2048). 
	# Flags exclude sum: 4+8+256+512+1024+2048 = 3852
	# select TLEN $9, keep fragments 1-100 bp
samtools view -@ "$SLURM_CPUS_PER_TASK" -h -f 3 -F 3852 "$noMitoPath/${base}_noMito.bam" \
| awk 'BEGIN{OFS="\t"} /^@/ {print; next} {t=$9; if(t<0) t=-t; if(t>=1 && t<=100) print}' \
| samtools sort -@ "$SLURM_CPUS_PER_TASK" -O BAM -o "$sizePath/${base}_frag1_100.bam" -
samtools index -@ "$SLURM_CPUS_PER_TASK" "$sizePath/${base}_frag1_100.bam"

