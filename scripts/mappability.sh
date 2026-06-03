#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/psmc
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=48:00:00
#SBATCH --job-name=mappability_mask
#SBATCH --output=%x.%A.out
#SBATCH --error=%x.%A.err

# =============================================================================
# Step 1: Generate Mappability Mask for PSMC
# Reference: Stenella attenuata HiC assembly
# Method: Simulate 150bp reads tiling across reference, align back with BWA,
#         flag non-uniquely mapping regions as low mappability
# =============================================================================

# --- Paths ---
REF="/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta"
OUTDIR="/scratch2/nvollmer/psmc/mappability"
TMPDIR="/scratch2/nvollmer/psmc/mappability/tmp"

mkdir -p ${OUTDIR}
mkdir -p ${TMPDIR}

echo "================================================"
echo "Job started: $(date)"
echo "Reference: ${REF}"
echo "Output directory: ${OUTDIR}"
echo "================================================"

# --- Activate deeptools environment ---
source /opt/bioinformatics/mambaforge/etc/profile.d/conda.sh
conda activate ddocent-2.9.8

# Verify tools are available
echo "Checking tool availability..."
samtools --version | head -1
bwa 2>&1 | head -3
bedtools --version | head -1
echo ""

# =============================================================================
# 1a. Index the reference (if not already done)
#     You said BWA index is already done, but we check just in case
# =============================================================================
if [ ! -f "${REF}.bwt" ]; then
    echo "[$(date)] Indexing reference with BWA..."
    bwa index ${REF}
else
    echo "[$(date)] BWA index already exists, skipping..."
fi

if [ ! -f "${REF}.fai" ]; then
    echo "[$(date)] Indexing reference with samtools..."
    samtools faidx ${REF}
else
    echo "[$(date)] Samtools index already exists, skipping..."
fi

# =============================================================================
# 1b. Simulate 150bp reads tiling every position of the reference
#     This generates one read starting at every position
# =============================================================================
echo ""
echo "[$(date)] Simulating 150bp reads from reference..."

# Use python to tile reads across reference — works with any python3
python3 - <<'PYEOF'
import gzip, sys

ref_path = "/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta"
out_path = "/scratch2/nvollmer/psmc/mappability/tmp/simulated_reads.fq"
read_len = 150
step = 50  # step size — every 50bp is sufficient; 1bp is exhaustive but slow

seq_name = None
seq = []

def emit_reads(name, sequence, read_len, step, out):
    seq_len = len(sequence)
    for i in range(0, seq_len - read_len + 1, step):
        read = sequence[i:i+read_len]
        if 'N' in read.upper():
            continue  # skip reads that are entirely N — they'll always multi-map
        qual = 'I' * read_len  # phred 40
        out.write(f"@{name}_{i}\n{read}\n+\n{qual}\n")

with open(ref_path) as fasta, open(out_path, 'w') as fq:
    for line in fasta:
        line = line.strip()
        if line.startswith('>'):
            if seq_name is not None:
                emit_reads(seq_name, ''.join(seq), read_len, step, fq)
            seq_name = line[1:].split()[0]
            seq = []
        else:
            seq.append(line)
    if seq_name is not None:
        emit_reads(seq_name, ''.join(seq), read_len, step, fq)

print("Simulated reads written.")
PYEOF

echo "[$(date)] Simulated reads complete."
echo "Read count: $(grep -c '^@' ${TMPDIR}/simulated_reads.fq)"

# =============================================================================
# 1c. Align simulated reads back to the reference with BWA
#     Key: we want to identify which positions map UNIQUELY
#          -M flag marks shorter split hits as secondary
# =============================================================================
echo ""
echo "[$(date)] Aligning simulated reads back to reference..."

bwa mem \
    -t ${SLURM_CPUS_PER_TASK} \
    -M \
    ${REF} \
    ${TMPDIR}/simulated_reads.fq | \
samtools view -bS -@ 4 | \
samtools sort -@ 4 -T ${TMPDIR}/sort_tmp \
    -o ${TMPDIR}/simulated_aligned.bam

samtools index ${TMPDIR}/simulated_aligned.bam

echo "[$(date)] Alignment complete."
samtools flagstat ${TMPDIR}/simulated_aligned.bam

# =============================================================================
# 1d. Extract UNIQUELY mapping regions
#     Reads with mapping quality >= 30 are considered uniquely mapped
#     (multi-mappers get MAPQ=0 from BWA)
#     We convert these to a BED file of GOOD regions
# =============================================================================
echo ""
echo "[$(date)] Extracting uniquely mapping regions (MAPQ >= 30)..."

# Get genome file (chromosome sizes) for bedtools
samtools view -H ${TMPDIR}/simulated_aligned.bam | \
    grep "^@SQ" | \
    awk '{gsub("SN:",""); gsub("LN:",""); print $2"\t"$3}' \
    > ${OUTDIR}/genome.txt

echo "Chromosome sizes written to ${OUTDIR}/genome.txt"
head -5 ${OUTDIR}/genome.txt

# Extract uniquely mapping reads and convert to BED
samtools view -q 30 -b ${TMPDIR}/simulated_aligned.bam | \
bedtools genomecov \
    -ibam stdin \
    -bg \
    -g ${OUTDIR}/genome.txt | \
awk '$4 > 0' \
    > ${OUTDIR}/uniquely_mapped_coverage.bed

echo "[$(date)] Coverage BED written."

# =============================================================================
# 1e. Convert coverage to mappability BED
#     Merge nearby covered regions (within 150bp = 1 read length)
#     to fill small gaps from our step size
# =============================================================================
echo ""
echo "[$(date)] Merging regions and creating mappability mask..."

bedtools merge \
    -i ${OUTDIR}/uniquely_mapped_coverage.bed \
    -d 150 \
    > ${OUTDIR}/mappable_regions_raw.bed

# Filter: keep only regions >= 500bp (removes tiny islands)
awk '($3 - $2) >= 500' ${OUTDIR}/mappable_regions_raw.bed \
    > ${OUTDIR}/mappable_regions.bed

# Create the INVERSE — regions to EXCLUDE (low mappability)
bedtools complement \
    -i ${OUTDIR}/mappable_regions.bed \
    -g ${OUTDIR}/genome.txt \
    > ${OUTDIR}/low_mappability_mask.bed

# =============================================================================
# 1f. Summary statistics
# =============================================================================
echo ""
echo "================================================"
echo "MAPPABILITY MASK SUMMARY"
echo "================================================"

GENOME_SIZE=$(awk '{sum += $2} END {print sum}' ${OUTDIR}/genome.txt)
MAPPABLE_SIZE=$(awk '{sum += $3-$2} END {print sum}' ${OUTDIR}/mappable_regions.bed)
MASKED_SIZE=$(awk '{sum += $3-$2} END {print sum}' ${OUTDIR}/low_mappability_mask.bed)

echo "Total genome size:     ${GENOME_SIZE} bp"
echo "Mappable regions:      ${MAPPABLE_SIZE} bp"
echo "Low-mappability masked: ${MASKED_SIZE} bp"
echo "Percent mappable:      $(echo "scale=1; ${MAPPABLE_SIZE}*100/${GENOME_SIZE}" | bc)%"
echo ""
echo "Output files:"
echo "  Regions to USE:    ${OUTDIR}/mappable_regions.bed"
echo "  Regions to MASK:   ${OUTDIR}/low_mappability_mask.bed"
echo "  Genome sizes:      ${OUTDIR}/genome.txt"
echo ""
echo "Job finished: $(date)"
echo "================================================"

# =============================================================================
# NEXT STEP: Once this completes successfully, run Step 2 (RepeatMasker)
# Check your output with:
#   head ${OUTDIR}/mappable_regions.bed
#   wc -l ${OUTDIR}/mappable_regions.bed
# =============================================================================
