#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/array_jobs_sambamba
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=medmem
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=40:00:00
#SBATCH --job-name=sambamba
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err
#SBATCH --array=[1-190]%30 

# can test with array of 1-2, but should be 1-190 for real run

indir=/scratch2/nvollmer/analysis/Bam_merge
outdir=/scratch2/nvollmer/analysis/Marked_Dups

cd $indir

#find in the current directory (.) any file with the name .bam. 
#then but off everything but the lab ID
#the sed command is what pulls down each line to submit the array
inbam=$(ls *.bam | cut -f 1 -d "." | sed -n $(echo $SLURM_ARRAY_TASK_ID)p)

echo $inbam

#go to the folder where the sambamba code was downloaded and markdup
#nthreads should equal whatever I have above for cpus-per-task
#tmpdir puts temp files in a folder that I had to create called tmp
#call the .combined.bams in the indir
#call the output files the labID_mkdup.bam
~/bin/sambamba-1.0.1-linux-amd64-static markdup --nthreads=4  --tmpdir=/scratch2/nvollmer/analysis/Marked_Dups/tmp ${indir}/${inbam}.combined.bam ${outdir}/${inbam}_mkdup.bam
