#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/array_jobs
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=12G
#SBATCH --time=6:00:00
#SBATCH --job-name=samtools
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err
#SBATCH --array=[1-2]%25 

# can test with array of 1-2, but should be 1-189 for real run

module load bio/samtools/1.19

cd /scratch2/nvollmer/analysis/alignment

#find in the current directory (.) any file with the name .bam. 
#Then for all those found, using / as the delimitor cut off the first 3 sections
#Then using _ as the delimitor cut off the first 1 sections
#then for all that remain sort and then make a list of unique values
#then find and remove any named AJ-9
#then find and remove any named AJno9
#then the sed command is "what pulls down each line to submit the array"
sample=$(find . -name "*.bam" | cut -f 3 -d "/" | cut -f 1 -d "_" | sort |uniq | grep -v AJ-9 | grep -v AJno9 | sed -n $(echo $SLURM_ARRAY_TASK_ID)p)


#find in the current directory (.) any file with the name samplename.bam where sample name is what you set as your variable above and should be just the lab ID
#send all it finds to samtools sort command, which creates a Temporary file (-T) named sampleID.temp and then saves those files in bam format ( -O bam) and outputs
#the results to the output folder (-o Bam_merge) and calls them finally sampleID.combined.bam
samtools merge - $(find . -name "${sample}*.bam") | samtools sort - -T ${sample}.temp -O bam -o /scratch2/nvollmer/analysis/Bam_merge/${sample}.combined.bam
