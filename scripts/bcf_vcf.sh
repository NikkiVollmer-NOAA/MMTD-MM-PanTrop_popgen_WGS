#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/vcf
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --job-name=vcf_array              
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G                   
#SBATCH --time=12:00:00              
#SBATCH --partition=standard
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err
#SBATCH --array=1-20   

# Load required modules
module load bio/bcftools
module load bio/samtools

cd /scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/vcf

REF="/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta"

# 1. Dynamically grab the exact scaffold name (Excluding scaffold 21!)
SCAFFOLD=$(sort -k2,2nr ${REF}.fai | grep -w -v "HiC_scaffold_21" | head -n 20 | awk -v row=$SLURM_ARRAY_TASK_ID 'NR==row {print $1}')

echo "Starting variant calling for $SCAFFOLD"

# 2. Generate the raw VCF for ONLY this scaffold using the -r flag
bcftools mpileup -r $SCAFFOLD -q 30 -Q 20 -a FORMAT/DP -f $REF -b bams8.txt | \
bcftools call -mv -Oz -o raw_8_${SCAFFOLD}.vcf.gz

# 3. Filter the VCF for pristine SNPs
bcftools view -m2 -M2 -v snps raw_8_${SCAFFOLD}.vcf.gz | \
bcftools filter -i 'QUAL>30' -Oz -o final_8_${SCAFFOLD}.vcf.gz

# 4. Index the file
tabix -p vcf final_8_${SCAFFOLD}.vcf.gz

echo "Finished processing $SCAFFOLD"
