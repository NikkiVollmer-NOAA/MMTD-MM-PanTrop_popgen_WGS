#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/psmc
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=2:00:00
#SBATCH --job-name=merge_masks
#SBATCH --output=%x.%A.out
#SBATCH --error=%x.%A.err

# =============================================================================
# Step 4: Merge mappability mask + repeat mask into final callable regions
# IMPORTANT: Run this only after BOTH jobs 01 and 03 have completed
# Runtime: ~10-20 minutes
# =============================================================================

REF="/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta"
MAPDIR="/scratch2/nvollmer/psmc/mappability"
REPDIR="/scratch2/nvollmer/psmc/repeats"
OUTDIR="/scratch2/nvollmer/psmc/masks"
mkdir -p ${OUTDIR}

echo "================================================"
echo "Job started: $(date)"
echo "================================================"

source /opt/bioinformatics/mambaforge/etc/profile.d/conda.sh
conda activate ddocent-2.9.8

# Check inputs exist
for f in ${MAPDIR}/mappable_regions.bed ${REPDIR}/repeats_combined.bed; do
    if [ ! -f "${f}" ]; then
        echo "ERROR: Missing input file: ${f}"
        echo "Make sure both Step 1 (mappability) and Step 3 (repeatmasker) completed successfully."
        exit 1
    fi
done

echo "Inputs confirmed:"
echo "  Mappable regions: $(wc -l < ${MAPDIR}/mappable_regions.bed) intervals"
echo "  Repeat regions:   $(wc -l < ${REPDIR}/repeats_combined.bed) intervals"
echo ""

# =============================================================================
# Subtract repeats from mappable regions
# Result: regions that are BOTH uniquely mappable AND non-repetitive
# =============================================================================
echo "[$(date)] Subtracting repeats from mappable regions..."

bedtools subtract \
    -a ${MAPDIR}/mappable_regions.bed \
    -b ${REPDIR}/repeats_combined.bed \
    > ${OUTDIR}/callable_raw.bed

# Filter: keep only intervals >= 100kb
# Shorter intervals cause PSMC's HMM to reset too frequently
echo "[$(date)] Filtering for intervals >= 100kb..."

awk '($3 - $2) >= 100000' ${OUTDIR}/callable_raw.bed \
    > ${OUTDIR}/callable_regions_100kb.bed

# =============================================================================
# Summary
# =============================================================================
GENOME_SIZE=$(awk '{sum += $2} END {print sum}' ${REF}.fai)
RAW_SIZE=$(awk '{sum += $3-$2} END {print sum}' ${OUTDIR}/callable_raw.bed)
FINAL_SIZE=$(awk '{sum += $3-$2} END {print sum}' ${OUTDIR}/callable_regions_100kb.bed)
FINAL_COUNT=$(wc -l < ${OUTDIR}/callable_regions_100kb.bed)

echo ""
echo "================================================"
echo "MASK MERGING SUMMARY"
echo "================================================"
echo "Genome size:                   ${GENOME_SIZE} bp"
echo "Callable before size filter:   ${RAW_SIZE} bp ($(echo "scale=1; ${RAW_SIZE}*100/${GENOME_SIZE}" | bc)%)"
echo "Callable after 100kb filter:   ${FINAL_SIZE} bp ($(echo "scale=1; ${FINAL_SIZE}*100/${GENOME_SIZE}" | bc)%)"
echo "Number of callable intervals:  ${FINAL_COUNT}"
echo ""
echo "Output: ${OUTDIR}/callable_regions_100kb.bed"
echo ""

# =============================================================================
# IMPORTANT CHECK:
# At least 50% of the genome should remain callable for reliable PSMC.
# If the percentage is below 40%, the reference may be too fragmented
# and you should consider using a different/better reference genome.
# =============================================================================

PCT=$(echo "scale=2; ${FINAL_SIZE}*100/${GENOME_SIZE}" | bc)
echo "Percent callable genome: ${PCT}%"
if (( $(echo "${PCT} < 40" | bc -l) )); then
    echo ""
    echo "WARNING: Less than 40% of the genome is callable."
    echo "PSMC results may be unreliable. Consider:"
    echo "  1. Reviewing your mappability mask stringency"
    echo "  2. Using a higher-quality reference genome"
fi

echo ""
echo "Job finished: $(date)"
echo "================================================"
