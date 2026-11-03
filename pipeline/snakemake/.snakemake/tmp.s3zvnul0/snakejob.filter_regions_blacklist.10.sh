#!/bin/bash
set -euo pipefail

source /etc/profile.d/modules.sh || true
module load anaconda3 || true
eval "$(conda shell.bash hook)"
conda activate atacseq_env

cd /projects/daylab/yulia/ATAC-Seq_T2T_Telomere/pipeline/snakemake && /home/murthy.j/.conda/envs/snakemake/bin/python3.10 -m snakemake --snakefile '/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/pipeline/snakemake/snakefile_atacseq.py' --target-jobs 'filter_regions_blacklist:region=HA-PARP3_HA_HQ' --allowed-rules 'filter_regions_blacklist' --cores 'all' --attempt 1 --force-use-threads  --resources 'mem_mb=1000' 'mem_mib=954' 'disk_mb=1000' 'disk_mib=954' --wait-for-files '/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/pipeline/snakemake/.snakemake/tmp.s3zvnul0' '/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/refs/PARP3/HA-PARP3_HA_HQ.bed' '/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/refs/hg38blacklist_ENCFF023CZC.bed' --force --keep-target-files --keep-remote --max-inventory-time 0 --nocolor --notemp --no-hooks --nolock --ignore-incomplete --rerun-triggers 'code' 'params' 'software-env' 'mtime' 'input' --skip-script-cleanup  --conda-frontend 'mamba' --wrapper-prefix 'https://github.com/snakemake/snakemake-wrappers/raw/' --configfiles '/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/pipeline/snakemake/config.yaml' --printshellcmds  --latency-wait 120 --scheduler 'ilp' --scheduler-solver-path '/home/murthy.j/.conda/envs/snakemake/bin' --default-resources 'mem_mb=max(2*input.size_mb, 1000)' 'disk_mb=max(2*input.size_mb, 1000)' 'tmpdir=system_tmpdir' --mode 2 && touch '/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/pipeline/snakemake/.snakemake/tmp.s3zvnul0/10.jobfinished' || (touch '/projects/daylab/yulia/ATAC-Seq_T2T_Telomere/pipeline/snakemake/.snakemake/tmp.s3zvnul0/10.jobfailed'; exit 1)

