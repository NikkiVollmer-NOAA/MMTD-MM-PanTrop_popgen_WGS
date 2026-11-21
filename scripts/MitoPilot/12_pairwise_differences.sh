#!/bin/bash
# =============================================================================
# 12_pairwise_differences.sh
# Count base differences between one sample's ANNOTATED mitogenome and every
# other sample in a MitoPilot project, and summarize (min / median / max).
# Annotated sequences are rotated to start at trnF, so they line up directly.
# Do NOT use raw assemblies (out/<ID>/assemble): different start positions give
# ~12,000 spurious "differences".
# Samples with a different length are skipped (an indel shifts all later positions;
# align them, e.g. with MAFFT, for a proper comparison).
#
# Usage: bash scripts/12_pairwise_differences.sh PROJECT_DIR SAMPLE_ID [EXCLUDE_REGEX]
# Example (batch 1): 515-01 median 9 differences; 32Satt004 median 175 (divergent lineage)
#   bash scripts/12_pairwise_differences.sh /scratch2/nvollmer/MitoPilot/Stenella_batch1 32Satt004 Slon
# Add LIST=1 to also print the 5 closest samples:
#   LIST=1 bash scripts/12_pairwise_differences.sh <project> 32Satt004 Slon
# =============================================================================
set -uo pipefail
PROJECT=${1:?Usage: $0 PROJECT_DIR SAMPLE_ID [EXCLUDE_REGEX]}
REF=${2:?Usage: $0 PROJECT_DIR SAMPLE_ID [EXCLUDE_REGEX]}
EXCL=${3:-^$}
cd "$PROJECT"

R=$(find "out/$REF/annotate" -name "*.fasta" | head -1)
[[ -f "$R" ]] || { echo "No annotated FASTA for $REF"; exit 1; }

RESULTS=$(for F in $(find out/*/annotate -name "*.fasta" | grep -v "/$REF/" | grep -v -E "$EXCL"); do
  s=$(echo "$F" | cut -d/ -f2)
  awk -v s="$s" 'FNR==1{f++} !/^>/{q[f]=q[f] toupper($0)} END{
    if(length(q[1])!=length(q[2])) exit
    n=0; for(i=1;i<=length(q[1]);i++) if(substr(q[1],i,1)!=substr(q[2],i,1)) n++
    print n"\t"s}' "$R" "$F"
done | sort -n)

echo "== $REF vs others (differences) =="
echo "$RESULTS" | awk '{a[NR]=$1} END{print "  n="NR"  min="a[1]"  median="a[int((NR+1)/2)]"  max="a[NR]}'
if [[ "${LIST:-0}" == "1" ]]; then
  echo "  closest samples:"; echo "$RESULTS" | head -5 | sed 's/^/    /'
fi
