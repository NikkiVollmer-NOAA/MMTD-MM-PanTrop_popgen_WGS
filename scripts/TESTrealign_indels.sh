#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/array_jobs_realign
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=himem
#SBATCH --cpus-per-task=2
#SBATCH --mem=96G
#SBATCH --time=40:00:00
#SBATCH --job-name=realign
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err
#SBATCH --array=[1-190]%16 


BAMLIST=$1 /scratch2/nvollmer/analysis/Clipped/bam_list.txt # Path to a list of merged, deduplicated, and overlap clipped bam files. Full paths should be included. An example of such a bam list is /workdir/cod/greenland-cod/sample_lists/bam_list_1.tsv
BASEDIR=$2 /scratch2/nvollmer/analysis/realign # Path to the base directory where adapter clipped fastq file are stored in a subdirectory titled "adapter_clipped" and into which output files will be written to separate subdirectories. An example for the Greenland cod data is: /workdir/cod/greenland-cod/
REFERENCE=$3 /scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta.gz # Path to reference fasta file and file name, e.g /workdir/cod/reference_seqs/gadMor2.fasta
SAMTOOLS=${4:-samtools} /opt/bioinformatics/bio/samtools/1.19 # Path to samtools
JAVA=${5:-/usr/local/jdk1.8.0_121} # Path to java
GATK=${6:-/programs/GenomeAnalysisTK-3.7/GenomeAnalysisTK.jar} /opt/bioinformatics/bio/gatk/gatk-4.6.0.0 # Path to GATK
JOBS=${7:-1} # Number of indexing jobs to run in parallel (default 1)


JOB_INDEX=0

## Loop over each sample
for SAMPLEBAM in `cat $BAMLIST`; do

if [ -e $SAMPLEBAM'.bai' ]; then
	echo "the file already exists"
else
	## Index bam files
	$SAMTOOLS index $SAMPLEBAM &

	JOB_INDEX=$(( JOB_INDEX + 1 ))
	if [ $JOB_INDEX == $JOBS ]; then
		wait
		JOB_INDEX=0
	fi
fi

done

wait

## Realign around in-dels
# This is done across all samples at once

## Use an older version of Java
export JAVA_HOME=$JAVA
export PATH=$JAVA_HOME/bin:$PATH

## Create list of potential in-dels
if [ ! -f $BASEDIR'bam/all_samples_for_indel_realigner.intervals' ]; then
	java -Xmx40g -jar $GATK \
	   -T RealignerTargetCreator \
	   -R $REFERENCE \
	   -I $BAMLIST \
	   -o $BASEDIR'bam/all_samples_for_indel_realigner.intervals' \
	   -drf BadMate
fi

## Run the indel realigner tool
java -Xmx40g -jar $GATK \
   -T IndelRealigner \
   -R $REFERENCE \
   -I $BAMLIST \
   -targetIntervals $BASEDIR'bam/all_samples_for_indel_realigner.intervals' \
   --consensusDeterminationModel USE_READS  \
   --nWayOut _realigned.bam
