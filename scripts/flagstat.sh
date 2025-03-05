#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=12G
#SBATCH --time=12:00:00
#SBATCH --job-name=samtools
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err


module load bio/samtools/1.19

cd /scratch2/nvollmer/analysis/alignment/241129_NOA016_PanTrop_WGS/

for sample in *.bam

do

f1=${sample%.bam}

samtools flagstat $sample>Flagstat/$f1-stats.txt

done

