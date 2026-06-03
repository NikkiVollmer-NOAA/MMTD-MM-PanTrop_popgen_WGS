#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/psmc
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=2-00:00:00
#SBATCH --job-name=repeatmasker
#SBATCH --output=%x.%A.out
#SBATCH --error=%x.%A.err

# =============================================================================
# Step 3: Repeat Masking using cetacean Dfam database
# Runtime estimate: 12-36 hours on 16 CPUs for a ~2.5Gb genome
# =============================================================================

REF="/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta"
OUTDIR="/scratch2/nvollmer/psmc/repeats"
mkdir -p ${OUTDIR}

echo "================================================"
echo "Job started: $(date)"
echo "================================================"

source /opt/bioinformatics/mambaforge/etc/profile.d/conda.sh
conda activate repeatmodeler-2.0.3

RepeatMasker \
    -species cetacea \
    -pa $(( ${SLURM_CPUS_PER_TASK} / 4 )) \
    -dir ${OUTDIR} \
    -gff \
    -nolow \
    -xsmall \
    ${REF}

# Check output exists
REF_BASENAME=$(basename ${REF})
if [ ! -f "${OUTDIR}/${REF_BASENAME}.out" ]; then
    echo "ERROR: RepeatMasker did not produce expected output."
    exit 1
fi

# Convert to BED (RepeatMasker uses 1-based coords, BED is 0-based)
conda activate ddocent-2.9.8

awk 'NR>3 && NF>0 {print $5"\t"($6-1)"\t"$7}' \
    ${OUTDIR}/${REF_BASENAME}.out | \
    bedtools sort | \
    bedtools merge \
    > ${OUTDIR}/repeats_combined.bed

# Summary
GENOME_SIZE=$(awk '{sum += $2} END {print sum}' ${REF}.fai)
REPEAT_SIZE=$(awk '{sum += $3-$2} END {print sum}' ${OUTDIR}/repeats_combined.bed)

echo ""
echo "================================================"
echo "REPEAT MASKING SUMMARY"
echo "================================================"
echo "Genome size:      ${GENOME_SIZE} bp"
echo "Repeat content:   ${REPEAT_SIZE} bp"
echo "Percent repeats:  $(echo "scale=1; ${REPEAT_SIZE}*100/${GENOME_SIZE}" | bc)%"
echo "Output BED:       ${OUTDIR}/repeats_combined.bed"
echo "Job finished: $(date)"
echo "================================================"
