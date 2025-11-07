#!/bin/bash
#01_launch_trim.sh
# Usage: bash 01_launch_trim.sh

set -euo pipefail

projPath="/projects/daylab/yulia/ATAC-Seq_T2T_Telomere"
fastqPath="$projPath/experiments/08_25_StrackerLab/raw_fastq"
jobScript="$projPath/pipeline/bash_scripts/01_trim_adapters.sh"
trimmedPath="$projPath/experiments/08_25_StrackerLab/trimmed"

# Make output path if it doesnt exist already
mkdir -p "$trimmedPath"  

# Go to fastq path
cd "$fastqPath"

# Loop over all the files in the folder defined in your fastqPath
for file in *_R1_001.fastq.gz
do
    # Define the output prefix; -F is where the sample name will be cut
    outname=$(basename "$file" _R1_001.fastq.gz)

    # Define the read suffixes
    read1=${outname}_R1_001.fastq.gz
    read2=${outname}_R2_001.fastq.gz

		# Submit in the script
    sbatch $jobScript \
     "$read1" "$read2" "$outname" "$trimmedPath"
done
