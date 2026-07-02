#!/bin/bash
# 00b_make_sex_table.sh
#
# Filters final_sex_audit.txt (191 lines: header + 190 samples) down to just
# the samples in manifest.txt (the 154 GOMx+ATL individuals), producing
# sample_sex.txt for use in the sex-biased dispersal analysis later.
#
# Run this AFTER 00_make_manifest.sh.

set -euo pipefail

SEXFILE="/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/final_sex_audit.txt"
MANIFEST="manifest.txt"
OUT="sample_sex.txt"

echo -e "sample\tsex" > "$OUT"

missing=0
while IFS=$'\t' read -r sample bam; do
    # look up this sample in the sex audit file (Sample column includes .bam)
    hit=$(awk -F'\t' -v s="${sample}.bam" '$1==s {print $4}' "$SEXFILE")
    if [[ -z "$hit" ]]; then
        echo "NO SEX RECORD FOUND: $sample"
        missing=$((missing+1))
    else
        echo -e "${sample}\t${hit}" >> "$OUT"
    fi
done < "$MANIFEST"

echo ""
echo "$missing sample(s) in manifest.txt with no matching sex record"
echo ""
echo "Sex breakdown of the 154:"
tail -n +2 "$OUT" | cut -f2 | sort | uniq -c


