
#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --job-name=plink
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err


module load bio/bcftools
module load bio/plink

cd /scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/vcf/

# Use --threads to speed up the process
# --vcf-half-call h handles any missing/ambiguous genotypes safely
bcftools view -v snps -m2 -M2 merged_data_noX.bcf.gz | \
plink2 --vcf /dev/stdin \
       --make-bed \
       --out my_data_final \
       --threads 8 \
       --vcf-half-call h \
       --allow-extra-chr
