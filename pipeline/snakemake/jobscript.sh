#!/bin/bash
set -euo pipefail

source /etc/profile.d/modules.sh || true
module load anaconda3 || true
eval "$(conda shell.bash hook)"
conda activate atacseq_env

{exec_job}
