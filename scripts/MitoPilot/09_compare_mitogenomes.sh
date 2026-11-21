#!/bin/bash
# =============================================================================
# 09_compare_mitogenomes.sh
# Base-by-base comparison of two mitogenome FASTAs (single sequence each).
# MitoPilot rotates circular assemblies to start at trnF, so annotated
# sequences from the same lineage line up directly.
# Used for the mother/fetus check (1Slon001 vs 1Slon001f): 16387 bp each, 0 differences.
# Usage: bash scripts/09_compare_mitogenomes.sh A.fasta B.fasta
# Example:
#   bash scripts/09_compare_mitogenomes.sh \
#     out/1Slon001/annotate/1Slon001_assembly_1_1.fasta \
#     out/1Slon001f/annotate/1Slon001f_assembly_1_1.fasta
# Note: an indel shifts all later positions; if lengths differ, align instead
# (e.g. MAFFT) before counting differences.
# =============================================================================
set -euo pipefail
A=${1:?Usage: $0 A.fasta B.fasta}
B=${2:?Usage: $0 A.fasta B.fasta}

awk 'FNR==1{f++} !/^>/{s[f]=s[f] toupper($0)} END{
  print "Seq1: " length(s[1]) " bp   Seq2: " length(s[2]) " bp";
  n=0; L=(length(s[1])>length(s[2]))?length(s[1]):length(s[2]);
  for(i=1;i<=L;i++){a=substr(s[1],i,1); b=substr(s[2],i,1);
    if(a!=b){n++; if(n<=20) print "  pos " i ": seq1=" a " seq2=" b}}
  print "Differences: " n
}' "$A" "$B"
