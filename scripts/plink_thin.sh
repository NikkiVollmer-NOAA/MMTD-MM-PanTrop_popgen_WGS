#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=8
#SBATCH --mem=8G
#SBATCH --time=4:00:00
#SBATCH --job-name=plink
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err


module load bio/bcftools
module load bio/plink/2.00a5.10

cd /scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/vcf/


## thin 0.02 tells PLINK to keep only 2% of the total variants and discard the other 98%
plink --bfile admixtools_ready \ --remove relatives_to_remove.txt \ --thin 0.02 \ --make-bed \
      --out admixtools_lite
