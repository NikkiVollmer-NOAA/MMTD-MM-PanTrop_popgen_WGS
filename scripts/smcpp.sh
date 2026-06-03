#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/smcpp
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --job-name=smcpp
#SBATCH --output=%x.%A.out
#SBATCH --error=%x.%A.err

# --- LOAD ENVIRONMENT & MODULES ---
source /opt/bioinformatics/mambaforge/etc/profile.d/conda.sh
conda activate smcpp-1.15.4
export PYTHONNOUSERSITE=1
module load bio/htslib

cd /scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/vcf/

# Define files and parameters
VCF="final_8_filtered_master.vcf.gz"
REF="/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta"
MU="1.5e-8"

# Create output directories
mkdir -p smc_data/ATL smc_data/GOMx smc_data/joint smc_results/ATL smc_results/GOMx smc_results/split

echo "Starting vcf2smc conversion loop..."

# Dynamically grab the 20 autosomal scaffolds
SCAFFOLDS=$(sort -k2,2nr ${REF}.fai | grep -w -v "HiC_scaffold_21" | head -n 20 | awk '{print $1}')

# Phase 1: Convert VCF to SMC format
for SCAFFOLD in $SCAFFOLDS; do
    echo "Converting $SCAFFOLD..."
    
    # 1. Atlantic only
    smc++ vcf2smc $VCF smc_data/ATL/${SCAFFOLD}.smc.gz $SCAFFOLD ATL:7Satt014,7Satt013,Satt008,7Satt015
    
    # 2. GOMx only
    smc++ vcf2smc $VCF smc_data/GOMx/${SCAFFOLD}.smc.gz $SCAFFOLD GOMx:8Satt068,515-01,8Satt196,8Satt040
    
    # 3. Joint (For split time)
    smc++ vcf2smc $VCF smc_data/joint/${SCAFFOLD}.smc.gz $SCAFFOLD ATL:7Satt014,7Satt013,Satt008,7Satt015 GOMx:8Satt068,515-01,8Satt196,8Satt040
done

echo "Conversion complete. Starting model estimations..."

# Phase 2: Estimate demographic histories (using 8 cores for speed)
smc++ estimate --cores 8 -o smc_results/ATL $MU smc_data/ATL/*.smc.gz
smc++ estimate --cores 8 -o smc_results/GOMx $MU smc_data/GOMx/*.smc.gz

echo "Estimations complete. Starting divergence split calculation..."

# Phase 3: Calculate Split Time
smc++ split -o smc_results/split smc_results/ATL/model.final.json smc_results/GOMx/model.final.json smc_data/joint/*.smc.gz

echo "Pipeline fully complete!"
