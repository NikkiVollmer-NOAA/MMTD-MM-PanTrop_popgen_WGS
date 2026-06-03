#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=12:00:00
#SBATCH --job-name=bcfconcat
#SBATCH --output=%x.%A.out
#SBATCH --error=%x.%A.err


module load bio/bcftools
module load bio/htslib

cd /scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/vcf/

# 1. Create a list of all your final filtered scaffold VCFs in numerical order (-v)
ls -v final_8_HiC_scaffold_*.vcf.gz > vcf_list.txt

# 2. Concatenate (stitch) them back together in order
bcftools concat -f vcf_list.txt -Oz -o final_8_filtered_master.vcf.gz

# 3. Index the final master file
tabix -p vcf final_8_filtered_master.vcf.gz
