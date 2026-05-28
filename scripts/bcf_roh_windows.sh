### To get this windowed heterozygosity data, need to generate two numbers for every 1Mb window in every sample: the count of heterozygous sites (the numerator) and the total number of callable sites (the denominator).
### Step 1: Create the Genomic Windows
### First,  reate a BED file that defines the "boxes" across your genome.

### Navigate to folder with ref genome and manually (not using a slurm script0 run the following code to
### Create 1Mb windows with a 100kb step (slide)

#module load bio/bedtools
#bedtools makewindows -g Stenella_attenuata_HiC.fasta.fai -w 1000000 -s 100000 > windows_1Mb_100kb.bed

###then need to move this .bed file to my vcf folder

### Then can run the following script

#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/roh
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --job-name=ROHw
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --partition=standard
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err
#SBATCH --array=1-154%10

# Load necessary modules
module load bio/bcftools
module load bio/bedtools

# Navigate to the working directory
cd /scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/vcf

# --- CONFIGURATION ---
BCF="Satt_subset_154.bcf"
WINDOWS="windows_1Mb_100kb.sorted.bed"
OUTDIR="./window_het_results"
mkdir -p $OUTDIR

# --- GET SAMPLE IDs ---
# RAW_SAMPLE: The exact string in the BCF header (potentially a long path)
# SAMPLE: A clean name for file naming (e.g., 26Satt001)
RAW_SAMPLE=$(bcftools query -l $BCF | sed -n "${SLURM_ARRAY_TASK_ID}p")
SAMPLE_NAME=$(basename "$RAW_SAMPLE")
SAMPLE=${SAMPLE_NAME%%.*}

echo "Processing Array Index ${SLURM_ARRAY_TASK_ID}"
echo "Header ID: $RAW_SAMPLE"
echo "Clean Name: $SAMPLE"

# --- CALCULATE HETS AND TOTAL SITES ---

# 1. Extract heterozygous sites
# We use $RAW_SAMPLE to tell bcftools exactly which column to pull
bcftools view -s "$RAW_SAMPLE" -g het "$BCF" | \
bcftools query -f '%CHROM\t%POS\t%POS\n' > "${SAMPLE}_hets.bed"

# 2. Count hets per window
# -sorted is used to keep memory usage low (requires sorted windows)
bedtools intersect -a "$WINDOWS" -b "${SAMPLE}_hets.bed" -c -sorted > "${SAMPLE}_counts.txt"

# 3. Extract ALL called positions (the denominator)
bcftools view -s "$RAW_SAMPLE" "$BCF" | \
bcftools query -f '%CHROM\t%POS\t%POS\n' > "${SAMPLE}_total_sites.bed"

# 4. Count total sites per window
bedtools intersect -a "$WINDOWS" -b "${SAMPLE}_total_sites.bed" -c -sorted > "${SAMPLE}_total_sites_counts.txt"

# --- COMBINE AND CLEAN ---
# Columns: Chrom, Start, End, HetCount, TotalSites, SampleName
# We use the clean $SAMPLE variable for the filename to avoid "No such file" errors
paste "${SAMPLE}_counts.txt" "${SAMPLE}_total_sites_counts.txt" | \
awk -v s="$SAMPLE" 'BEGIN{OFS="\t"} {print $1, $2, $3, $4, $8, s}' > "${OUTDIR}/${SAMPLE}_final_windows.txt"

# Remove temporary files
rm "${SAMPLE}_hets.bed" "${SAMPLE}_counts.txt" "${SAMPLE}_total_sites.bed" "${SAMPLE}_total_sites_counts.txt"

echo "Done."
