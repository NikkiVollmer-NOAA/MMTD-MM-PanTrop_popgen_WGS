#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/LDdecay
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=40G
#SBATCH --time=24:00:00
#SBATCH --job-name=LDdecay
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err

module load R/4.4.1

BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/GLF_2/ngsLD

Rscript --vanilla --slave /opt/bioinformatics/bio/ngsld/ngsld-1.2.0/scripts/fit_LDdecay.R --ld_files ${BASEDIR}/ld_files.list --out ${BASEDIR}/plot.pdf
