#!/bin/bash
# =============================================================================
# 06_make_mapping.sh
# Build MitoPilot mapping files (ID,Taxon,R1,R2) from Illumina-named FASTQs:
#   <ID>_S##_L00#_R1_001.fastq.gz
# Uses ONE lane per individual (default L001): one lane of WGS gives far more
# mito coverage than needed, and MitoPilot takes one R1/R2 pair per sample.
# Usage: bash scripts/06_make_mapping.sh [FASTQ_DIR] [LANE]
# =============================================================================
set -euo pipefail

FASTQ_DIR=${1:-/scratch2/nvollmer/analysis/NOA015}
LANE=${2:-L001}
OUTDIR=/scratch2/nvollmer/MitoPilot/mapping
OUT=$OUTDIR/Stenella_all.csv
TEST=$OUTDIR/Stenella_test.csv

mkdir -p "$OUTDIR"
cd "$FASTQ_DIR"

echo "ID,Taxon,R1,R2" > "$OUT"
for r1 in *_${LANE}_R1_001.fastq.gz; do
  id=${r1%%_S[0-9]*}
  r2=${r1/_R1_001/_R2_001}
  if [[ $id == *Slon* ]]; then
    tax="Stenella longirostris"     # 1Slon001 (mother) and 1Slon001f (fetus)
  else
    tax="Stenella attenuata"
  fi
  if [[ -f $r2 ]]; then
    echo "$id,$tax,$r1,$r2" >> "$OUT"
  else
    echo "WARNING: no R2 found for $r1" >&2
  fi
done

# Small test set: mother/fetus pair (should share a mitogenome) + 2 S. attenuata
head -1 "$OUT" > "$TEST"
grep -E "^(1Slon001|1Slon001f|7Satt012|515-01)," "$OUT" >> "$TEST"

wc -l "$OUT" "$TEST"
cat "$TEST"
