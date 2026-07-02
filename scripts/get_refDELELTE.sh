#!/bin/bash
# 01_get_reference.sh
#
# Downloads the EU557096.1 Stenella attenuata mitogenome and builds
# a bwa-mem2 index (matching the aligner used in your existing pipeline).
# Uses curl against NCBI E-utilities directly (avoids needing an edirect
# module — curl/wget are essentially always available).
module load bio/samtools/1.19
module load aligners/bwa-mem2/2.2.1
set -euo pipefail

mkdir -p ref
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=EU557096.1&rettype=fasta&retmode=text" \
    -o ref/mito_EU557096.fasta

if [[ ! -s ref/mito_EU557096.fasta ]]; then
    echo "ERROR: download failed or returned empty file. If this node has no"
    echo "internet access, try running this script on the login/head node"
    echo "instead, or download EU557096.1 FASTA on your local machine and"
    echo "scp it to ref/mito_EU557096.fasta"
    exit 1
fi

echo "Reference downloaded:"
grep ">" ref/mito_EU557096.fasta
grep -v ">" ref/mito_EU557096.fasta | tr -d '\n' | wc -c
echo "^ bases above (sanity check: delphinid mitogenomes are ~16,400 bp)"

bwa-mem2 index ref/mito_EU557096.fasta
samtools faidx ref/mito_EU557096.fasta

echo "Done. Index files created in ref/"



