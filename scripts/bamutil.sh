#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=12G
#SBATCH --time=18:00:00
#SBATCH --job-name=bamutil
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err
#SBATCH --array=[1-190]%25

module load bio/bamutil/1.0.5

#set location of where marked bams are and where you want the clipped bams to go
bams=/scratch2/nvollmer/analysis/Marked_Dups
output=/scratch2/nvollmer/analysis/Clipped/

#go to your marked bams, take every file labeled .bam (samplename_mkdup.bam) and first remove everything after the '.' = bam
#next remove everything after the '_' = mkdup so all you are left with is a list of sample names
#then last bit is all for running the array
cd $bams
inbam=$(ls *.bam | cut -f 1 -d "." | cut -f 1 -d "_" |  sed -n $(echo $SLURM_ARRAY_TASK_ID)p)

#echo the inbam to make sure all the cutting was correct so you are left with just the sample names
echo $inbam

#this creates the format naming for the output files which will be save in output directory called above
#and then be named with just sample name (from inbam) and then _clipped.bam
output_file="${output}${inbam}_clipped.bam"

#running the actual clipOverlap code calling --in input files and --out output files and running --stats option
bam clipOverlap --in ${inbam}_mkdup.bam --out $output_file --stats 
