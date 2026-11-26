#!/bin/bash
# =============================================================================
# 15_getorg_rescue_test.sh
# Test alternative GetOrganelle settings on ONE failed sample directly, using
# the reads MitoPilot already trimmed (in the project's work/ folder), without
# rerunning the whole MitoPilot project. Use the winning setting afterwards as
# a new MitoPilot assembly parameter set for the failed samples only.
#
# Batch 3 (Nov 2026): 5 of 47 failed with the batch settings
# (-R 15 -k 21,45,65,85, default read cap 500x). Tests on 8Satt172 / 8Satt174:
#   A: -R 10 -k 21,45,65,85,105,115                        -> 172 circular 560x; 174 FAILED (16 scaffolds, 9.7x)
#   B: -R 15 -k 21,45,65,85 --reduce-reads-for-coverage 200 -> 172 circular 213x; 174 circular 217x   <- adopted
#
# Usage (from <project>/rescue_tests/):
#   sbatch -J 172_B -o 172_B.out 15_getorg_rescue_test.sh 8Satt172 B "-R 15 -k 21,45,65,85 --reduce-reads-for-coverage 200"
# Then:  tail -n 2 *.out   (look for "circular genome" at 100s of x)
# Check a result:  length of <S>_<T>/*path_sequence.fasta (~16,386) and BLAST species.
# =============================================================================
#SBATCH -p standard
#SBATCH -c 6
#SBATCH --mem=48G
#SBATCH -t 12:00:00
S=${1:?sample}; T=${2:?test name}; OPTS=${3:-}
P=${PROJECT:-/scratch2/nvollmer/MitoPilot/Stenella_batch3}
SEEDS=${SEEDS:-/scratch2/nvollmer/MitoPilot/refdb/conspecific_seeds/Stenella_batch2_seeds.fasta}
LABELS=${LABELS:-/scratch2/nvollmer/MitoPilot/refdb/delphinidae/labelDB.fasta}
IMG=${IMG:-/scratch2/nvollmer/singularity_cache/macguigand-mitopilot-1.6.0.img}

source ~/.bashrc; mamba activate MitoPilot_deps
export APPTAINER_BIND=/scratch2      # container can't see /scratch2 otherwise

# MitoPilot's assemble task dir holds the trimmed reads: <task>/<S>_preprocess_R{1,2}.fastq.gz
TASK=$(dirname "$(dirname "$(dirname "$(find "$P/work" -path "*/$S/assemble/get_org.log.txt" | head -1)")")")
R1=$(ls "$TASK/${S}_preprocess_R1.fastq.gz"); R2=$(ls "$TASK/${S}_preprocess_R2.fastq.gz")

cd "$P/rescue_tests"
singularity exec "$IMG" get_organelle_from_reads.py -1 "$R1" -2 "$R2" -o "${S}_${T}" --overwrite \
  -s "$SEEDS" --genes "$LABELS" \
  -t 6 -F anonym --larger-auto-ws --expected-max-size 20000 --target-genome-size 16500 $OPTS
grep -E "Average anonym base-coverage|Result status" "${S}_${T}/get_org.log.txt"
