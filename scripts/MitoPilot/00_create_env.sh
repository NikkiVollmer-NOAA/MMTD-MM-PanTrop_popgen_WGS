#!/bin/bash
# =============================================================================
# 00_create_env.sh
# One-time setup of the MitoPilot dependency environment on NOAA SEDNA.
# Run interactively on a compute node:
#   srun -c 2 --mem=16GB -p standard --pty /bin/bash
#   bash scripts/00_create_env.sh
# =============================================================================
set -euo pipefail

# SEDNA's mamba is v2.x: the old `mamba init` no longer works.
# Run this ONCE per account, then `source ~/.bashrc`:
#   /opt/bioinformatics/mambaforge/bin/mamba shell init --shell bash
#   source ~/.bashrc

# Core environment.
# - nextflow pinned to 25.10 (Nextflow 26+ breaks the nf-sqldb plugin MitoPilot uses)
# - apptainer instead of conda-forge::singularity (that package is Singularity 2.4.6,
#   which needs root and fails with "Could not create /dev/loop0: Permission denied")
# - libxml2-devel needed to compile the R packages XML/xml2 (otherwise "cannot find -lxml2")
mamba create --name MitoPilot_deps -y \
  -c bioconda -c conda-forge \
  "nextflow=25.10" apptainer zlib r-base \
  libxml2 libxml2-devel libcurl openssl bzip2 xz pkg-config cmake make libuv

# Note: errors like
#   "libmamba Could not open lockfile '/opt/bioinformatics/mambaforge/pkgs/...'"
# are harmless (shared package cache is read-only for users).

# Check where the env landed (scripts below assume ~/.conda/envs/MitoPilot_deps)
mamba env list
