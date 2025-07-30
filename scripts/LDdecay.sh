#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/LDdecay
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=himem
#SBATCH --cpus-per-task=4
#SBATCH --mem=120G
#SBATCH --time=24:00:00
#SBATCH --job-name=LDdecay
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err

module load R/4.4.1

BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/GLF_2/ngsLD

cat ${BASEDIR}/ld_files_5.list | awk 'rand()<0.1' | Rscript --vanilla --slave /opt/bioinformatics/bio/ngsld/ngsld-1.2.0/scripts/fit_LDdecay.R \
--ld_files ${BASEDIR}/ld_files_5.list --fit_level 10 --plot_x_lim 5000 --out ${BASEDIR}/HiC_scaffold_5_LDplot.pdf

#the awk command is there to downsample and only analyze 10% of the input file because I keep running out of memory when trying to do the whole thing
