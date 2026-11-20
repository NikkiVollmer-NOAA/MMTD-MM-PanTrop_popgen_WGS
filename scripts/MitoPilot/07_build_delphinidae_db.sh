#!/bin/bash
# =============================================================================
# 07_build_delphinidae_db.sh
# Build GetOrganelle seed + label databases for Delphinidae from GenBank using
# MitoPilot's GenBankDownloadUtil.sh / parseGB.py.
# MitoPilot ships fish databases only, so cetaceans need custom ones.
#
# One-time setup (login or compute node):
#   mamba create -n gbdb -c conda-forge -c bioconda entrez-direct biopython python wget -y
#   mkdir -p /scratch2/nvollmer/MitoPilot/refdb/delphinidae
#   cd /scratch2/nvollmer/MitoPilot/refdb/delphinidae
#   wget https://raw.githubusercontent.com/smithsonian/MitoPilot/refs/heads/main/ref_dbs/getOrganelle/GenBankDownload/GenBankDownloadUtil.sh
#   wget https://raw.githubusercontent.com/smithsonian/MitoPilot/refs/heads/main/ref_dbs/getOrganelle/GenBankDownload/parseGB.py
# Submit:
#   sbatch scripts/07_build_delphinidae_db.sh
#
# Outputs used:
#   seed DB  = multigene.dedup.fasta  (optionally + selected nogene.dedup.fasta)
#   label DB = singlegene.dedup.fasta
# Why Delphinidae rather than Stenella: Stenella is not monophyletic (mixed with
# Delphinus/Tursiops/Sousa/Lagenodelphis); seeds only recruit reads, the
# assembly itself is built from the sample's reads; broader references help
# with the variable control region; few complete Stenella mitogenomes exist.
# =============================================================================
#SBATCH --job-name=delph_db
#SBATCH --output=delph_db_%j.out
#SBATCH -p standard
#SBATCH -c 4
#SBATCH --mem=32G
#SBATCH -t 12:00:00

source ~/.bashrc
mamba activate gbdb
cd /scratch2/nvollmer/MitoPilot/refdb/delphinidae

bash GenBankDownloadUtil.sh '"Delphinidae"[Organism] AND "mitochondrion"[Filter]'
echo "Done at $(date)"

# Check:
#   grep -c ">" multigene.dedup.fasta singlegene.dedup.fasta nogene.dedup.fasta
