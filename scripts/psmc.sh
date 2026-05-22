#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/psmc
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --job-name=PSMC
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=48:00:00
#SBATCH --partition=standard
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err


# Load required modules
module load bio/bcftools
module load bio/samtools
module load bio/psmc/0.6.5

# Paths (Update these to your actual paths)
REF="/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta"
BAMS=("/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/7Satt014_clipped_realigned.bam" "/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/7Satt013_clipped_realigned.bam" "/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/Satt008_clipped_realigned.bam" "/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/7Satt015_clipped_realigned.bam" "/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/8Satt068_clipped_realigned.bam" "/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/515-01_clipped_realigned.bam" "/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/8Satt196_clipped_realigned.bam" "/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/8Satt040_clipped_realigned.bam")

# Loop through your 8 selected individuals
for BAM in "${BAMS[@]}"
do
    ID=$(basename $BAM _clipped_realigned.bam)
    echo "Processing $ID at $(date)"

    # 1. Generate the diploid consensus (FASTQ)
    # Using -d 4 and -D 25 based on your 12x average
    # -C 50 helps reduce the impact of poorly mapped reads
    bcftools mpileup -C 50 -f $REF $BAM | \
    bcftools call -c -V indels | \
    vcfutils.pl vcf2fq -d 4 -D 25 > ${ID}.fq

    # 2. Convert FASTQ to PSMC input format
    # -q 20 ensures only high-quality bases are used
    fq2psmcfa -q 20 ${ID}.fq > ${ID}.psmcfa

    # 3. Run the PSMC analysis (same params as Rice's manu)
    # -p Pattern "4+25*2+4+6" is effective for mammals
    # -N25 Number of iterations
    psmc -N25 -t15 -r5 -p "4+25*2+4+6" -o ${ID}.psmc ${ID}.psmcfa

    # 4. Optional: Generate the plot data (Scale with Mu and Generation time)
    # Using g=23 years (Taylor etal 2007) and u=1.5e-8 (from Moura etal 2014 and Suzuki etal 2022)
    psmc_plot.pl -g 23 -u 1.5e-8 ${ID}_plot ${ID}.psmc

    echo "Finished $ID at $(date)"
done
