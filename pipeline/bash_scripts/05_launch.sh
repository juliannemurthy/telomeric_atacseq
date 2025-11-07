#!/bin/bash
#05_launch.sh
# Created by Julianne (Yulia) Murthy on 09/15/2025
# Usage: bash 05_launch.sh
set -euo pipefail
proj="/projects/daylab/yulia/ATAC-Seq_T2T_Telomere"
tsvFile="$proj/pipeline/bash_scripts/05_samples.tsv"
outDir="$proj/experiments/08_25_StrackerLab/merge"
jobScript="$proj/pipeline/bash_scripts/05_merge1_100_reps.sh"
mkdir -p "$outDir"

# Define unique conditions, skipping header
	# IFS= does not trim leading or ending whitespaces while reading
	# [[ -n "$cond" ]] || continue: skips empty lines
	# < < : process substitution, out of the command is fed into the while loop
	# field separator is one or more tabs or spaces, prints column 2
	# NR>1 skips header row
	# sort -u sorts and dedups conds
while IFS= read -r cond; do
  [[ -n "$cond" ]] || continue
  sbatch "$jobScript" "$tsvFile" "$cond" "$outDir"
done < <(awk -F '[\t ]+' 'NR>1 {print $2}' "$tsvFile" | sort -u)
