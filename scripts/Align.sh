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

#One of the largest directories timed out using a 2hr limit so went big with 24 hr. Per Giles "requesting 24 hrs for jobs that take 1 hr shouldn't be a problem. 
#Its just the max amount of time that the job could possibly run, you're not really wasting resources if it only goes for one hour if that is what you're thinking"

module load bio/samtools/1.19
module load aligners/bwa-mem2/2.2.1

#need to make the outdir folder that you want it to put the output files in and make sure there is a ending '/'
indir=/scratch2/nvollmer/trimmed-trimmomatic/241129_NOA015_PanTrop_WGS/
bwagenind=/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta.gz
outdir=/scratch2/nvollmer/analysis/alignment/241129_NOA015_PanTrop_WGS/
run=run1


fq1=$(find $indir -name "*_paired.R1.fq.gz" | sed -n $(echo $SLURM_ARRAY_TASK_ID)p)
fq2=$(echo $fq1 | sed 's/_paired.R1.fq.gz/_paired.R2.fq.gz/g')
sample=$(echo $fq1 | cut -f 6 -d "/" | cut -f 1 -d "_")
#Per Reid decided to use separate library names for each sample. just to be super careful. why? "because you'll mark duplicates for each merged bam separately, I don't think it actually matters. 
#but just in case, you can call each sample its own library." so made library variable be same as sample variable for the RG
#OLD:library=$(echo $fq1 | cut -f 5 -d "/" | cut -f 2 -d "_")
library=$(echo $fq1 | cut -f 6 -d "/" | cut -f 1 -d "_")


rg=$(echo \@RG\\tID:$sample\\tPL:Illumina\\tPU:x\\tLB:${library}_${run}\\tSM:$sample)
tempsort=$sample.$library.$run.temp
outfile=$outdir$sample_$library.bam

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
