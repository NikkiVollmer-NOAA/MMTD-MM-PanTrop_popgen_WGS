#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/array_jobs
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=30G
#SBATCH --time=2:00:00
#SBATCH --job-name=bwa
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err+
#SBATCH --array=[1-285]%25

#More array info for line 12: The total number should be equal to the number of samples you want to run. 
#It will run up to that number of jobs you put here: --array=[1-285]%25, so 285, and run 25 at a time.
#If you have 600, then only the first 285 will run. If you have 100, but say 285, the 100 will run. So you should set it to the number of samples you have.
#But if we are keeping all lanes per sample separate (see below) then need to could each Lane per sample as a "sample" - e.g. Satt001_L002 = sample #1, 
#Satt001_L001 = sample #2, etc.

#One of the largest directories timed out using a 2hr limit so went big with 24 hr. Per Giles "requesting 24 hrs for jobs that take 1 hr shouldn't be a problem. 
#Its just the max amount of time that the job could possibly run, you're not really wasting resources if it only goes for one hour if that is what you're thinking"

module load bio/samtools/1.19
module load aligners/bwa-mem2/2.2.1

#need to make the outdir folder that you want it to put the output files in and make sure there is a ending '/'
indir=/scratch2/nvollmer/trimmed-trimmomatic/241129_NOA016_PanTrop_WGS_Satt005_8Satt204/
bwagenind=/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta.gz
outdir=/scratch2/nvollmer/analysis/alignment/241129_NOA016_PanTrop_WGS_Satt005_8Satt204/


fq1=$(find $indir -name "*_paired.R1.fq.gz" | sed -n $(echo $SLURM_ARRAY_TASK_ID)p)
fq2=$(echo $fq1 | sed 's/_paired.R1.fq.gz/_paired.R2.fq.gz/g')
sample=$(echo $fq1 | cut -f 6 -d "/" | cut -f 1 -d "_")
#Decided to keep separate all Lanes per Sample. Eg all Satt001 run on Lane 001 would be aligned into one bam - Satt001_L001.bam; and all Satt001 on Lane 002 would
#be a separate bam - Satt001_L002.bam. So the sample variable is calling out the sample ID and the sample lane variable the Lane number.
#OLD:library=$(echo $fq1 | cut -f 5 -d "/" | cut -f 2 -d "_")
samplelane=$(echo $fq1 | cut -f 6 -d "/" | cut -f 3 -d "_")
#library=$(echo $fq1 | cut -f 6 -d "/" | cut -f 1 -d "_")


#rg=$(echo \@RG\\tID:$sample\\tPL:Illumina\\tPU:x\\tLB:${library}_${run}\\tSM:$sample)
rg=$(echo \@RG\\tID:$sample\\tPL:Illumina\\tPU:x\\tLB:${sample}\\tSM:$sample)
#tempsort=$sample.$library.$run.temp
tempsort=$sample.$samplelane.temp
#outfile=$outdir$sample_$library.bam
outfile=$outdir${sample}_$samplelane.bam

echo $SLURM_ARRAY_TASK_ID
echo $sample
echo $fq1
echo $fq2
echo $rg
echo $tempsort
echo $outfile
echo $outdir

bwa-mem2 mem -t 4 -R $rg $bwagenind $fq1 $fq2 | \
samtools view -S -h -u - | \
samtools sort - -O BAM -o $outfile
