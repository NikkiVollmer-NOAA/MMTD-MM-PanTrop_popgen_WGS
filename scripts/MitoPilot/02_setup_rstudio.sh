#!/bin/bash
# =============================================================================
# 02_setup_rstudio.sh
# One-time setup of RStudio Server (via Apptainer) for the MitoPilot GUI on SEDNA.
# Run on a compute node with MitoPilot_deps active.
# =============================================================================
set -euo pipefail

R_VERSION="4.6.2"   # must match the R version in MitoPilot_deps (R.version.string)

mkdir -p ~/rstudio ~/bin
cd ~/rstudio

# Pull the RStudio image (Apptainer provides the `singularity` command)
singularity pull rstudio_${R_VERSION}.sif docker://rocker/rstudio:${R_VERSION}

# RStudio server scratch dirs + sqlite config
mkdir -p run var-lib-rstudio-server
printf 'provider=sqlite\ndirectory=/var/lib/rstudio-server\n' > database.conf

# Install the launcher
cp "$(dirname "$0")/start-rstudio-server-MitoPilot" ~/bin/
sed -i "s/^Rstudio_version=.*/Rstudio_version=\"${R_VERSION}\"/" ~/bin/start-rstudio-server-MitoPilot
chmod 755 ~/bin/start-rstudio-server-MitoPilot

# Let RStudio sessions find nextflow / java / singularity from the conda env
# (RStudio resets PATH inside the container)
grep -q "MitoPilot_deps/bin" ~/.Renviron 2>/dev/null || \
  echo "PATH=\${PATH}:${HOME}/.conda/envs/MitoPilot_deps/bin" >> ~/.Renviron

ls -l ~/rstudio ~/bin/start-rstudio-server-MitoPilot
