#!/bin/bash
# =============================================================================
# 10_make_seed_file.sh
# Build a same-species GetOrganelle seed file from finished MitoPilot assemblies.
# Pilot finding: the broad Delphinidae seed DB + k-mers up to 115 left 7Satt012
# as low-coverage NUMT-like fragments; a same-species seed + k <= 85 gave a
# circular mitogenome at ~440x. One seed per species avoids favouring either.
# Batch 1 seeds: S. attenuata 515-01 (16,386 bp), S. longirostris 1Slon001 (16,387 bp)
# For batch 2: add an S. frontalis seed from the first good frontalis assembly.
# =============================================================================
set -euo pipefail
PILOT=/scratch2/nvollmer/MitoPilot/Stenella_test/out
OUT=/scratch2/nvollmer/MitoPilot/refdb/conspecific_seeds/Stenella_batch1_seeds.fasta
mkdir -p "$(dirname "$OUT")"

{
  echo ">Stenella_attenuata_515-01"
  grep -v ">" "$PILOT/515-01/assemble/default/515-01_assembly_1.fasta"
  echo ">Stenella_longirostris_1Slon001"
  grep -v ">" "$(find "$PILOT/1Slon001/assemble" -name '*.fasta' | head -1)"
} > "$OUT"

# Check: two sequences, ~16.4 kb each
awk '/^>/{if(l)print n": "l" bp"; n=$0; l=0; next}{l+=length($0)}END{print n": "l" bp"}' "$OUT"
