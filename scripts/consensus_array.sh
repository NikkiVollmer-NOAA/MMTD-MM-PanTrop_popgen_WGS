#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/psmc
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=1-00:00:00
#SBATCH --job-name=consensus
#SBATCH --output=%x.%A_%a.out
#SBATCH --error=%x.%A_%a.err
#SBATCH --array=0-7

# =============================================================================
# Step 5: Per-individual consensus FASTQ generation
# Runs as a job array — one job per individual simultaneously
# Runtime estimate: 4-12 hours per individual
# =============================================================================

# --- Sample information ---
# Array index maps to: sample name, min depth, max depth, population
SAMPLES=(7Satt014  7Satt013  Satt008  7Satt015  8Satt068  515-01   8Satt196  8Satt040)
MIN_DP=(  14        13        10       8         11        10       10        9       )
MAX_DP=(  83        80        61       47        65        62       59        55      )
POPS=(    ATL       ATL       ATL      ATL       GOM       GOM      GOM       GOM     )

# Get values for this array task
SAMPLE=${SAMPLES[$SLURM_ARRAY_TASK_ID]}
MIN=${MIN_DP[$SLURM_ARRAY_TASK_ID]}
MAX=${MAX_DP[$SLURM_ARRAY_TASK_ID]}
POP=${POPS[$SLURM_ARRAY_TASK_ID]}

# --- Paths ---
REF="/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta"
BAMDIR="/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned"
BAM="${BAMDIR}/${SAMPLE}_clipped_realigned.bam"
REGIONS="/scratch2/nvollmer/psmc/masks/callable_regions_500bp.bed"
OUTDIR="/scratch2/nvollmer/psmc/consensus"
mkdir -p ${OUTDIR}

echo "================================================"
echo "Job started:  $(date)"
echo "Sample:       ${SAMPLE}"
echo "Population:   ${POP}"
echo "Min depth:    ${MIN}x"
echo "Max depth:    ${MAX}x"
echo "BAM:          ${BAM}"
echo "================================================"

source /opt/bioinformatics/mambaforge/etc/profile.d/conda.sh
conda activate ddocent-2.9.8
module load bio/psmc/0.6.5
module load bio/bcftools/1.21
module load bio/samtools/1.23

# Verify inputs
if [ ! -f "${BAM}" ]; then
    echo "ERROR: BAM file not found: ${BAM}"
    exit 1
fi
if [ ! -f "${REGIONS}" ]; then
    echo "ERROR: Callable regions BED not found: ${REGIONS}"
    echo "Make sure Step 4 (merge_masks) completed successfully."
    exit 1
fi

# Find vcfutils.pl (bundled with bcftools/samtools)
VCFUTILS="/opt/bioinformatics/bio/bcftools/bcftools-1.21/bin/vcfutils.pl"
echo "Using vcfutils.pl: ${VCFUTILS}"

# =============================================================================
# Generate diploid consensus FASTQ
# Pipeline:
#   bcftools mpileup — pileup at callable sites only (-R flag)
#   bcftools call -c — consensus genotype calling
#   vcfutils.pl vcf2fq — convert to FASTQ, masking low/high coverage sites
# =============================================================================
echo ""
echo "[$(date)] Generating consensus FASTQ..."

bcftools mpileup \
    -Q 30 \
    -q 30 \
    -R ${REGIONS} \
    -f ${REF} \
    ${BAM} | \
bcftools call -c | \
perl ${VCFUTILS} vcf2fq \
    -d ${MIN} \
    -D ${MAX} \
    -Q 30 \
    > ${OUTDIR}/${SAMPLE}_consensus.fq

echo "[$(date)] Consensus FASTQ complete."

# Check output is not empty
if [ ! -s "${OUTDIR}/${SAMPLE}_consensus.fq" ]; then
    echo "ERROR: Consensus FASTQ is empty."
    exit 1
fi

# =============================================================================
# Convert to PSMC input format (psmcfa)
# Each position is encoded as T (homozygous) or K (heterozygous)
# in 100bp windows
# =============================================================================
echo ""
echo "[$(date)] Converting to PSMC input format..."

fq2psmcfa -q 30 \
    ${OUTDIR}/${SAMPLE}_consensus.fq \
    > ${OUTDIR}/${SAMPLE}.psmcfa

# Quick sanity check on psmcfa
TOTAL_WINDOWS=$(grep -v "^>" ${OUTDIR}/${SAMPLE}.psmcfa | tr -d '\n' | wc -c)
HET_WINDOWS=$(grep -v "^>" ${OUTDIR}/${SAMPLE}.psmcfa | tr -d '\n' | tr -cd 'K' | wc -c)
HET_RATE=$(echo "scale=4; ${HET_WINDOWS}/${TOTAL_WINDOWS}" | bc)

echo ""
echo "================================================"
echo "CONSENSUS SUMMARY: ${SAMPLE}"
echo "================================================"
echo "Total 100bp windows:     ${TOTAL_WINDOWS}"
echo "Heterozygous windows:    ${HET_WINDOWS}"
echo "Heterozygosity rate:     ${HET_RATE}"
echo "Output psmcfa:           ${OUTDIR}/${SAMPLE}.psmcfa"
echo ""
echo "Expected heterozygosity for delphinids: ~0.0005 - 0.003"
if (( $(echo "${HET_RATE} < 0.0001" | bc -l) )); then
    echo "WARNING: Heterozygosity seems very low — check your consensus calling."
fi
if (( $(echo "${HET_RATE} > 0.005" | bc -l) )); then
    echo "WARNING: Heterozygosity seems high — possible residual repeat contamination."
fi

echo ""
echo "Job finished: $(date)"
echo "================================================"
