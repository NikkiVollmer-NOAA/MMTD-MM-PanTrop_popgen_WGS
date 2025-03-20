#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/array_jobs_picard
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=medmem
#SBATCH --cpus-per-task=2
#SBATCH --mem=100G
#SBATCH --time=40:00:00
#SBATCH --job-name=picard
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err
#SBATCH --array=[1-190]%8 

# can test with array of 1-2, but should be 1-190 for real run

module load bio/picard/2.23.9

indir=/scratch2/nvollmer/analysis/Bam_merge
outdir=/scratch2/nvollmer/analysis/Marked_Dups

cd $indir

#find in the current directory (.) any file with the name .bam. 
#then but off everything but the lab ID
#the sed command is what pulls down each line to submit the array
inbam=$(ls *.bam | cut -f 1 -d "." | sed -n $(echo $SLURM_ARRAY_TASK_ID)p)

echo $inbam

#first am limiting memory usage in java to 96 - a little buffer so it doesn't reach 100 that is set in sbatch above
java -Xmx96g -jar $PICARD MarkDuplicates I=${indir}/${inbam}.combined.bam O=${outdir}/${inbam}_mkdup.bam TMP_DIR=/scratch2/nvollmer/analysis/Marked_Dups/tmp M=${outdir}/${inbam}.metrics.txt

