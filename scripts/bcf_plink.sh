
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
bcftools view -v snps -m2 -M2 -Ou merged_data_noX.bcf.gz | \
plink2 --vcf /dev/stdin \
       --make-bed \
       --out my_data_final \
       --threads 8 \
       --vcf-half-call h \
       --allow-extra-chr

# 2. Identify SNPs for Pruning
# Fixed: Changed 'full_data' to 'my_data_final' to match the step above
# pruning using sliding window, windows are 50kb in this code, and am calculating the correlation (r2) 
# between all pairs of SNPs in a window, if any pair is highly correlated (r2>0.1) one SNP is removed
# It then shifts 5 SNPs forward and repeats the process
plink2 --bfile my_data_final \
       --indep-pairwise 50 5 0.1 \
       --out prune_it \
       --threads 8 \
       --allow-extra-chr

# 3. Create the pruned dataset
plink2 --bfile my_data_final \
       --extract prune_it.prune.in \
       --make-bed \
       --out admixtools_ready \
       --threads 8 \
       --allow-extra-chr
