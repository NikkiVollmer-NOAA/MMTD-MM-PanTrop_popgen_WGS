#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/array_jobs
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=30G
#SBATCH --time=2:00:00
#SBATCH --job-name=mtdna_extract
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err
#SBATCH --array=[1-154]%25
#
# 02_extract_mtdna_array.slurm
#
# IMPORTANT: set --array=[1-N]%25 above to match the sample count printed
# by 00_make_manifest.sh (N = number of UNIQUE SAMPLES, not lane-BAMs).
#
# For each sample (all lanes combined):
#   1. Pull unmapped / mate-unmapped reads from every lane-BAM for that
#      sample (candidates for true mtDNA reads — NUMT-derived reads should
#      already be correctly mapped to their nuclear locus in these BAMs)
#   2. Merge candidates across lanes, convert to FASTQ
#   3. Map candidates to the EU557096.1 mitogenome with bwa-mem2
#   4. Sort, index, and report mean depth / mapped read count as QC

module load bio/samtools/1.19
module load aligners/bwa-mem2/2.2.1
set -euo pipefail

MANIFEST=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/mitogenomes/manifest.txt
MITO_REF=/scratch2/nvollmer/refseq/mitoref/mito_EU557096.fasta
OUTDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/mitogenomes/mito_bams
FQDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/mitogenomes/mito_fastqs
STATSDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/mitogenomes/stats
mkdir -p "$OUTDIR" "$FQDIR" "$STATSDIR"

# Get this array task's sample (1-indexed line of manifest)
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$MANIFEST")
SAMPLE=$(echo "$LINE" | cut -f1)
BAM_LIST=$(echo "$LINE" | cut -f2)   # comma-separated lane BAMs

echo "=== Processing $SAMPLE ==="
echo "Lane BAMs: $BAM_LIST"

TMPDIR_SAMPLE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_SAMPLE"' EXIT

# Step 1: extract candidate reads from every lane BAM for this sample
i=0
CAND_BAMS=()
IFS=',' read -ra LANE_BAMS <<< "$BAM_LIST"
for bam in "${LANE_BAMS[@]}"; do
    i=$((i+1))
    samtools view -b -f 12 -@ "${SLURM_CPUS_PER_TASK}" "$bam" > "${TMPDIR_SAMPLE}/both_unmapped.${i}.bam"
    samtools view -b -f 4 -F 264 -@ "${SLURM_CPUS_PER_TASK}" "$bam" > "${TMPDIR_SAMPLE}/read1_unmapped.${i}.bam"
    samtools view -b -f 8 -F 260 -@ "${SLURM_CPUS_PER_TASK}" "$bam" > "${TMPDIR_SAMPLE}/read2_unmapped.${i}.bam"
    CAND_BAMS+=("${TMPDIR_SAMPLE}/both_unmapped.${i}.bam" "${TMPDIR_SAMPLE}/read1_unmapped.${i}.bam" "${TMPDIR_SAMPLE}/read2_unmapped.${i}.bam")
done

# Step 2: merge candidates across all lanes, then to FASTQ
samtools merge -f "${TMPDIR_SAMPLE}/candidates.bam" "${CAND_BAMS[@]}"
samtools sort -n -@ "${SLURM_CPUS_PER_TASK}" -o "${TMPDIR_SAMPLE}/candidates.nsorted.bam" "${TMPDIR_SAMPLE}/candidates.bam"
samtools fastq \
    -1 "${FQDIR}/${SAMPLE}.cand_R1.fastq.gz" \
    -2 "${FQDIR}/${SAMPLE}.cand_R2.fastq.gz" \
    -0 /dev/null -s /dev/null -n \
    "${TMPDIR_SAMPLE}/candidates.nsorted.bam"

# Step 3: map merged candidates to mitogenome reference
rg="@RG\tID:${SAMPLE}\tPL:Illumina\tPU:x\tLB:${SAMPLE}\tSM:${SAMPLE}"
bwa-mem2 mem -t "${SLURM_CPUS_PER_TASK}" -R "$rg" "$MITO_REF" \
    "${FQDIR}/${SAMPLE}.cand_R1.fastq.gz" \
    "${FQDIR}/${SAMPLE}.cand_R2.fastq.gz" \
    | samtools sort -@ "${SLURM_CPUS_PER_TASK}" -O BAM -o "${OUTDIR}/${SAMPLE}.mito.bam" -

samtools index "${OUTDIR}/${SAMPLE}.mito.bam"

# Step 4: QC
DEPTH=$(samtools depth -a "${OUTDIR}/${SAMPLE}.mito.bam" | awk '{sum+=$3; n++} END {if (n>0) print sum/n; else print 0}')
NREADS=$(samtools view -c -F 4 "${OUTDIR}/${SAMPLE}.mito.bam")
echo -e "${SAMPLE}\t${NREADS}\t${DEPTH}" > "${STATSDIR}/${SAMPLE}.stats.tsv"

echo "=== Done: $SAMPLE | mapped reads: $NREADS | mean depth: $DEPTH ==="
