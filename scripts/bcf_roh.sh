##!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/roh
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --job-name=ROH
#SBATCH --cpus-per-task=12
#SBATCH --mem=64G
#SBATCH --time=48:00:00
#SBATCH --partition=standard
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err

# Load bcftools
module load bio/bcftools

cd /scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/vcf/

INPUT="merged_data_noX.bcf.gz"
OUTPUT="Satt_ROH_results.txt"

echo "Job started at: $(date)"


# 1. Subsets the BCF to only your target samples. If you want to run all samples in bcf remove first 2 bcftools lines in code below
# 2. Recalculates the AF tag based ONLY on those samples
# 3. Runs ROH


# The --AF-tag AF tells it to use your existing info field.
# By default, bcftools roh uses PL tags if they are in the file.
# We add --skip-indels (-I) because ANGSD indels can be noisy
# and often mess up ROH boundaries.

bcftools view -S Satt_GOMxATL_154.txt --force-samples $INPUT | \
bcftools +fill-tags -- -t AF | \
bcftools roh \
    --threads 12 \
    --AF-tag AF \
    --skip-indels \
    -O r \
    -o $OUTPUT \
    $INPUT

echo "Job finished at: $(date)"


## ONCE JOB IS DONE run this using the output text file to get all the lines starting with RG:
grep "^RG" Satt_ROH_results.txt > Satt_ROH_regions.tsv

## THEN need to calculate the total Froh per individuals using this:
## This sums column 6 (length) for each unique sample ID in column 2
awk '{sum[$2]+=$6} END {for (i in sum) print i, sum[i]}' Satt_ROH_regions.tsv > individual_roh_sums.txt

## THEN need to take the sum for each individual and divide it by the total size of my assembly. 
## Can get this number by doing:
bcftools view -h merged_data_noX.bcf.gz | grep "^##contig" | sed 's/.*length=\([0-9]*\).*/\1/' | awk '{sum+=$1} END {print sum}'
