#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/ngsrelate
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=20G
#SBATCH --time=24:00:00
#SBATCH --job-name=ngsrelate
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err

module load bio/ngsrelate

BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/GLF_2/ngsLD_25kb

ngsrelate -G $BASEDIR/PCA_LDpruned.beagle.gz -n 190 -f $BASEDIR/PCA_LDpruned.freq.gz  -O $BASEDIR/ngsrelate_output
