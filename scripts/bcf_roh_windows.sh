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
#SBATCH --mem=16G
#SBATCH --time=24:00:00
#SBATCH --partition=standard
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err
#SBATCH --array=[1-154]%10

# Load necessary modules
module load bio/bcftools
module load bio/bedtools

# Navigate to the working directory
cd /scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/vcf

# --- CONFIGURATION ---
BCF="Satt_subset_154.bcf"
WINDOWS="windows_1Mb_100kb.bed"
OUTDIR="./window_het_results"
mkdir -p $OUTDIR

# --- GET SAMPLE ID ---
# sed -n "${SLURM_ARRAY_TASK_ID}p" grabs the specific line for this job
SAMPLE=$(bcftools query -l $BCF | sed -n "${SLURM_ARRAY_TASK_ID}p")

echo "Processing sample ${SLURM_ARRAY_TASK_ID}: $SAMPLE"

# --- CALCULATE HETS AND TOTAL SITES ---
# 1. Extract heterozygous sites for this sample
bcftools view -s $SAMPLE -g het $BCF | bcftools query -f '%CHROM\t%POS\t%POS\n' > ${SAMPLE}_hets.bed

# 2. Count heterozygous sites falling into each 1Mb window
bedtools intersect -a $WINDOWS -b ${SAMPLE}_hets.bed -c > ${SAMPLE}_counts.txt

# 3. Extract ALL called positions for this sample (the denominator)
bcftools view -s $SAMPLE $BCF | bcftools query -f '%CHROM\t%POS\t%POS\n' > ${SAMPLE}_total_sites.bed

# 4. Count total called sites per window
bedtools intersect -a $WINDOWS -b ${SAMPLE}_total_sites.bed -c > ${SAMPLE}_total_sites_counts.txt

# --- COMBINE AND CLEAN ---
# Columns: Chrom, Start, End, HetCount, TotalSites, SampleName
paste ${SAMPLE}_counts.txt ${SAMPLE}_total_sites_counts.txt | \
awk -v s="$SAMPLE" '{print $1"\t"$2"\t"$3"\t"$4"\t"$8"\t"s}' > $OUTDIR/${SAMPLE}_final_windows.txt

# Remove temporary BED files to keep the directory clean
rm ${SAMPLE}_hets.bed ${SAMPLE}_counts.txt ${SAMPLE}_total_sites.bed ${SAMPLE}_total_sites_counts.txt
