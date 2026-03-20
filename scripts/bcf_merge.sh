
#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=12:00:00
#SBATCH --job-name=bcftools
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err


module load bio/bcftools

cd /scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/vcf/

# Concatenate the files
bcftools concat -f bcf_list_noX.txt -O z -o merged_data_noX.bcf.gz

# Index the result (important for downstream steps)
bcftools index -t merged_data_noX.bcf.gz

