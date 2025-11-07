#!/bin/bash
#SBATCH --nodes=1
#SBATCH --job-name=Align_Bowtie2
#SBATCH --time=12:00:00
#SBATCH --mem=60G
#SBATCH --cpus-per-task=24
#SBATCH --partition=short
#SBATCH --output=/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/experiments/08_25_StrackerLab/slurm_logs/%x_%j.out
#SBATCH --error=/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/experiments/08_25_StrackerLab/slurm_logs/%x_%j.err

# Created by Julianne (Yulia) Murthy on 09/15/2025
# This script aligns the ATAC-seq fastq data to the chm13v2 index
# Usage: bash 03_launch_align.sh

# Safety error catch
set -euo pipefail

# Activate conda environment containing bowtie2
source /etc/profile.d/modules.sh
module load anaconda3
eval "$(conda shell.bash hook)"
conda activate atacseq_env

# Pass in the paths
indexPath="/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/refs/chm13v2.0/chm13v2_index/chm13v2_index"
R1=$1
R2=$2
base=$3
alignedPath=$4

# Run bowtie2 with specific parameters as listed in Lynskey et al
# pipe to samtools sort to create sorted bam files
# "with a mismatch parameter allowance of 1bp to account for telomeric repeat variants"
bowtie2 \
  -x "$indexPath" \
  -1 "$R1" -2 "$R2" \
  --dovetail -N 1 -I 10 -X 1000 --no-unal \
  -p "$SLURM_CPUS_PER_TASK" \
| samtools sort \
    -@ "$SLURM_CPUS_PER_TASK" -O BAM \
    -o "$alignedPath/bam/sorted/${base}.sorted.bam"
