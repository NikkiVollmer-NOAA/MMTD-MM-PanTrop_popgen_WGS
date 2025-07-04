#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=12G
#SBATCH --time=60:00:00
#SBATCH --job-name=samtools
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err


module load bio/samtools/1.19

cd /scratch2/nvollmer/analysis/Clipped/

for sample in *.bam

do

f1=${sample%.bam}
#need to create a folder in Clipped called Depth
samtools depth $sample>Depth/$f1-stats.txt

#to get depth at all bp in each sample
#samtools depth -aa $sample | gzip > Depth/$f1-clipped_realigned_depth_stats.gz

done


