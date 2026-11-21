#!/bin/bash
# =============================================================================
# 08_finalize_ref_dbs.sh
# Make the final GetOrganelle seed and label databases from the
# GenBankDownloadUtil.sh output (scripts/07_build_delphinidae_db.sh).
#   seedDB.fasta  = multigene.dedup.fasta records >= 15 kb (near-complete mitogenomes)
#   labelDB.fasta = singlegene.dedup.fasta without "no_product" records
# Usage: bash scripts/08_finalize_ref_dbs.sh [DB_DIR] [MIN_SEED_LEN]
# =============================================================================
set -euo pipefail
DB_DIR=${1:-/scratch2/nvollmer/MitoPilot/refdb/delphinidae}
MIN_LEN=${2:-15000}
cd "$DB_DIR"

# Seed DB: keep only long (near-complete) mitogenomes
awk -v min="$MIN_LEN" 'BEGIN{RS=">"; ORS=""} NR>1 {
  split($0, a, "\n"); seq=""; for(i=2;i<=length(a);i++) seq=seq a[i];
  if(length(seq)>=min) print ">"$0 }' multigene.dedup.fasta > seedDB.fasta

# Label DB: drop poorly annotated "no_product" records
awk 'BEGIN{RS=">"; ORS=""} NR>1 && $0 !~ /^no_product/ {print ">"$0}' \
  singlegene.dedup.fasta > labelDB.fasta

# Checks (Delphinidae, Nov 2026: seed 846, label 6128, no_product 0)
grep -c ">" seedDB.fasta labelDB.fasta
echo "no_product left in labelDB: $(grep -c 'no_product' labelDB.fasta || true)"
echo "Stenella species in multigene records:"
grep ">" multigene.dedup.fasta | grep -o -i "Stenella [a-z]*" | sort | uniq -c
