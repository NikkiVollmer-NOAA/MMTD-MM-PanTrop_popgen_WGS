#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/array_jobs_index
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --mem=24G
#SBATCH --time=24:00:00
#SBATCH --job-name=index
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err
#SBATCH --array=[1-190]%16 

module load bio/samtools

bams=/scratch2/nvollmer/analysis/Clipped/

cd $bams
inbam=$(ls *.bam | sed -n $(echo $SLURM_ARRAY_TASK_ID)p)


## Index bam files
samtools index $inbam 
