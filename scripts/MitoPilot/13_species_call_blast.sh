#!/bin/bash
# =============================================================================
# 13_species_call_blast.sh
# Whole-genome species call for every assembly in a MitoPilot project, by local
# BLAST against the Delphinidae seed database (846 near-complete mitogenomes).
#
# Why: MitoPilot's "Top BLAST Hit" can be wrong for Stenella. With ~100
# S. attenuata mitogenomes but only ONE complete S. frontalis in GenBank, all
# hits tie at E-value 0 and the top-5 list can omit the true best match.
# Batch 2: 5 S. frontalis (AJ-9, EH502-4, Sfro108, Sfro111, Sfro115) were
# reported by MitoPilot as S. attenuata at ~97%; this script showed S. frontalis
# at 98.99-99.89% along the whole genome (no mosaic / mixed sample).
#
# Method: for each sample, combine all HSPs (>= 1 kb) against each database
# record into a length-weighted identity, keep records with >= 15 kb aligned,
# take the best record per species, and report the closest 2 species.
#
# Requires: MitoPilot_deps env active (for `singularity`), compute node.
# Usage: bash scripts/13_species_call_blast.sh /scratch2/nvollmer/MitoPilot/Stenella_batch2
# Output: <project>/blast_check/species_calls.tsv (also printed)
# =============================================================================
set -uo pipefail
PROJECT=${1:?Usage: $0 /path/to/project}
IMG=${IMG:-/scratch2/nvollmer/singularity_cache/macguigand-mitopilot-1.6.0.img}
DB=${DB:-/scratch2/nvollmer/MitoPilot/refdb/delphinidae/seedDB.fasta}
export APPTAINER_BIND=/scratch2      # container can't see /scratch2 otherwise

cd "$PROJECT"
mkdir -p blast_check
[[ -f blast_check/delph.nsq || -f blast_check/delph.00.nsq ]] || \
  singularity exec "$IMG" makeblastdb -in "$DB" -dbtype nucl -out blast_check/delph -parse_seqids > /dev/null

{
printf "sample\tspecies1\tident1\tspecies2\tident2\n"
for Q in $(find out/*/assemble -name "*.fasta"); do
  s=$(echo "$Q" | cut -d/ -f2)
  singularity exec "$IMG" blastn -query "$Q" -db blast_check/delph -max_target_seqs 1000 \
    -outfmt "6 sacc pident length stitle" 2>/dev/null | \
  awk -F'\t' -v s="$s" '$3>=1000 {split($4,w," "); sp=w[1]" "w[2]; m[$1]+=$2*$3; L[$1]+=$3; spc[$1]=sp}
    END{for(a in L){id=m[a]/L[a]; if(L[a]>=15000 && id>best[spc[a]]) best[spc[a]]=id}
        for(i in best) print best[i]"\t"i}' | sort -k1,1gr | head -2 | \
  awk -F'\t' -v s="$s" '{sp[NR]=$2; id[NR]=$1} END{printf "%s\t%s\t%.2f\t%s\t%.2f\n", s, sp[1], id[1], sp[2], id[2]}'
done | sort -k2,2 -k3,3n
} | tee blast_check/species_calls.tsv | column -t -s $'\t'
