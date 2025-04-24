#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=himem
#SBATCH --mem=120G
#SBATCH --time=99:00:00
#SBATCH --job-name=realign
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err

cd /scratch2/nvollmer/analysis/Clipped

## Realign around in-dels
# This is done across all samples at once

GATK=~/bin/GenomeAnalysisTK.jar
BASEDIR=/scratch2/nvollmer/analysis/Clipped
BAMLIST=/scratch2/nvollmer/analysis/Clipped/bam_list.list #make sure file name ends in .list
REFERENCE=/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta #need to make sure reference is uncompressed and there is a .fai and .dict file - see gatk_fasta.txt

## Create list of potential in-dels
java -Xmx96g -jar $GATK \
	   -T RealignerTargetCreator \
	   -R $REFERENCE \
	   -I $BAMLIST \
	   -o $BASEDIR'/all_samples_for_indel_realigner.intervals' \
	   -drf BadMate

cd /scratch2/nvollmer/analysis/realign

## Run the indel realigner tool
java -Xmx96g -jar $GATK \
   -T IndelRealigner \
   -R $REFERENCE \
   -I $BAMLIST \
   -targetIntervals $BASEDIR'/all_samples_for_indel_realigner.intervals' \
   --consensusDeterminationModel USE_READS  \
   --nWayOut _realigned.bam
