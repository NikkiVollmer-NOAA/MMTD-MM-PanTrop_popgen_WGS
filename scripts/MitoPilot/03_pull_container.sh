#!/bin/bash
# =============================================================================
# 03_pull_container.sh
# Pre-pull the MitoPilot container into a shared cache.
# Why: the image takes ~22 min to build, longer than Nextflow's default 20 min
# singularity.pullTimeout, so the first Assemble run failed (status 143).
# Submit:  sbatch scripts/03_pull_container.sh
# =============================================================================
#SBATCH --job-name=pull_mitopilot
#SBATCH --output=pull_mitopilot_%j.out
#SBATCH -p standard
#SBATCH -c 2
#SBATCH --mem=16G
#SBATCH -t 4:00:00

MP_VERSION="1.6.0"
CACHE=/scratch2/nvollmer/singularity_cache
TMP=/scratch2/nvollmer/apptainer_tmp

source ~/.bashrc
mamba activate MitoPilot_deps
mkdir -p "$CACHE" "$TMP"

# keep big temporary build files off the node's small /tmp
export APPTAINER_TMPDIR=$TMP
export APPTAINER_CACHEDIR=$TMP

cd "$CACHE"
# File name must be exactly <user>-<image>-<tag>.img for Nextflow to find it
singularity pull macguigand-mitopilot-${MP_VERSION}.img docker://macguigand/mitopilot:${MP_VERSION}
echo "Done at $(date)"

# One-time: tell Nextflow where the cache is (picked up by every job via ~/.bashrc)
#   echo 'export NXF_SINGULARITY_CACHEDIR=/scratch2/nvollmer/singularity_cache' >> ~/.bashrc
