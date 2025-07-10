#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=medmem
#SBATCH --mem=120G
#SBATCH --time=7-00
#SBATCH --job-name=realign_array
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err
#SBATCH --array=1-7  # Adjust based on total number of batches needed = 190 bams/30batches = 6.33 rounded up =7

##first tried doing this realignment across all bams at once (see realign_realign_allbams.sh) but it timed out and would end up taking many weeks. So created this code
## which does the bams in batches

cd /scratch2/nvollmer/analysis/Clipped

GATK=~/bin/GenomeAnalysisTK.jar
BASEDIR=/scratch2/nvollmer/analysis/Clipped
BAMLIST=/scratch2/nvollmer/analysis/Clipped/bam_list.list
REFERENCE=/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta
BATCH_SIZE=30 # change to whatever makes sense. Will need to agree with the number of arrays.

# grab lines from your bamlist
START_LINE=$(( (SLURM_ARRAY_TASK_ID - 1) * BATCH_SIZE + 1 ))
END_LINE=$(( SLURM_ARRAY_TASK_ID * BATCH_SIZE ))

# make the bam list
BATCH_BAMLIST="batch_${SLURM_ARRAY_TASK_ID}_bams.list"
sed -n "${START_LINE},${END_LINE}p" $BAMLIST > $BATCH_BAMLIST

echo "running batch ${SLURM_ARRAY_TASK_ID}"

cd /scratch2/nvollmer/analysis/realign

java -Xmx96g -jar $GATK \
   -T IndelRealigner \
   -R $REFERENCE \
   -I $BATCH_BAMLIST \
   -targetIntervals $BASEDIR'/intervals/concat.intervals' \ #this concat.invtervals file should have been previously created so make sure if the basedir is changed above that this line still takes you to the concat.intervals file
   --consensusDeterminationModel USE_READS  \
   --nWayOut _realigned.bam
