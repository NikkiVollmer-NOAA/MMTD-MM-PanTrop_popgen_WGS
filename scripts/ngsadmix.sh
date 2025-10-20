#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/ngsadmix
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=medmem
#SBATCH --cpus-per-task=4
#SBATCH --mem=120G
#SBATCH --time=24:00:00
#SBATCH --job-name=ngsadmix
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err

module load bio/ngsadmix/32

BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned

NGSadmix -likes $BASEDIR'/ANGSDresults/GLF_2/ngsLD_25kb/PCA_LDpruned.beagle.gz' -K 3 -P 4 -o $BASEDIR'/ANGSDresults/GLF_2/ngsLD_25kb/ngsadmix/$








