#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/ngsadmix
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=20G
#SBATCH --time=24:00:00
#SBATCH --job-name=ngsadmix
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err
#SBATCH --array=2-6 #<-- RUNS FOR K=2, K=3, K=4, K=5, K=6

module load bio/ngsadmix/32

BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned

# The SLURM_ARRAY_TASK_ID variable will be 2, 3, 4, or 5
# We assign it to a clearer variable name
K_VALUE=$SLURM_ARRAY_TASK_ID

echo "Running NGSadmix for K = $K_VALUE"

NGSadmix -likes $BASEDIR'/ANGSDresults/GLF_2/ngsLD_25kb/PCA_LDpruned.beagle.gz' \
         -K $K_VALUE \
         -P 4 \
         -maxiter 5000 \
         -o $BASEDIR'/ANGSDresults/GLF_2/ngsLD_25kb/ngsadmix/PCA_LDpruned_ngsAdmix_K'$K_VALUE'_out'

echo "Finished K = $K_VALUE"

##to run a single K 
#NGSadmix -likes $BASEDIR'/ANGSDresults/GLF_2/ngsLD_25kb/PCA_LDpruned.beagle.gz' -K 3 -P 4 -o $BASEDIR'/ANGSDresults/GLF_2/ngsLD_25kb/ngsadmix/PCA_LDpruned_ngsAdmix_K3_out'











