#!/bin/bash
# 00_make_manifest.sh
#
# Your BAMs are final, per-individual, merged/clipped/realigned files named
# like: 1Satt003_clipped_realigned.bam  (leading digit prefix + sample ID +
# suffix). This extracts the sample ID and writes one line per sample.
#
# Output: manifest.txt
#   sample_id <TAB> bam_path
#
# Edit BAM_DIR to point at your directory of clipped_realigned BAMs. If your
# 154+9 samples are split across multiple directories, add more loops below.

BAM_DIR="/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned"
OUT="manifest.txt"

> "$OUT"
for bam in "$BAM_DIR"/*_clipped_realigned.bam; do
    fname=$(basename "$bam")
    # 1Satt003_clipped_realigned.bam -> strip leading digits, then strip suffix
    sample=$(echo "$fname" | sed -E 's/^[0-9]+//; s/_clipped_realigned\.bam$//')
    echo -e "${sample}\t${bam}" >> "$OUT"
done

sort -o "$OUT" "$OUT"

n=$(wc -l < "$OUT")
echo "Wrote $n samples to $OUT"
echo "First few lines:"
head -3 "$OUT"
echo ""
echo "Check for duplicate sample IDs (would indicate a parsing problem):"
cut -f1 "$OUT" | sort | uniq -d
echo ""
echo "IMPORTANT: set --array=[1-${n}]%25 in 02_extract_mtdna_array.slurm to match this count"
