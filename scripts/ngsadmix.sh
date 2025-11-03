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
#SBATCH --array=[1-100]10% #<-- 10 K-values (2-6) * 10 replicates = 50 jobs; run 10 at a time

module load bio/ngsadmix/32

BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned

# We have 10 replicates for each K
REPS_PER_K=10
# Our K-values start at 1
K_OFFSET=1

# Calculate K_VALUE and REP_NUM from the SLURM_ARRAY_TASK_ID (1-100)
# We use ($SLURM_ARRAY_TASK_ID - 1) for 0-based indexing to make math easier
IDX_ZERO_BASED=$((SLURM_ARRAY_TASK_ID - 1))

# K_VALUE will be 1, 2, 3, ... 10
K_VALUE=$(( (IDX_ZERO_BASED / REPS_PER_K) + K_OFFSET ))

# REP_NUM will be 1, 2, 3, ... 10
REP_NUM=$(( (IDX_ZERO_BASED % REPS_PER_K) + 1 ))

# SEED will be 1, 2, 3, ... 100 (unique and reproducible for each job)
SEED=$SLURM_ARRAY_TASK_ID

echo "Running NGSadmix for K = $K_VALUE, Replicate = $REP_NUM, Seed = $SEED"

NGSadmix -likes $BASEDIR'/ANGSDresults/GLF_2/ngsLD_25kb/PCA_LDpruned.beagle.gz' \
         -K $K_VALUE \
         -P 4 \
         -maxiter 10000 \
         -seed $SEED \
         -o $BASEDIR'/ANGSDresults/GLF_2/ngsLD_25kb/ngsadmix/PCA_LDpruned_ngsAdmix_K'$K_VALUE'_rep'$REP_NUM'_out'

echo "Finished K = $K_VALUE, Replicate = $REP_NUM"
