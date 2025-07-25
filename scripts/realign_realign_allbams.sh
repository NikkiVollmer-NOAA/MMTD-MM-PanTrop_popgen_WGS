#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=medmem
#SBATCH --mem=120G
#SBATCH --time=10-00
#SBATCH --job-name=realign
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err

cd /scratch2/nvollmer/analysis/Clipped

#adapted code from here https://github.com/therkildsen-lab/data-processing/blob/61eca5aea336f6594b44427ace58a419e0290696/scripts/realign_indels.sh#L34-L58
## Realign around in-dels
# This is done across all samples at once

GATK=~/bin/GenomeAnalysisTK.jar #had to download older version of GATK - 3.8.1 to get these realigner functions https://console.cloud.google.com/storage/browser/gatk-software/package-archive/gatk;tab=objects?prefix=&forceOnObjectsSortingFiltering=false  Used the Public URL link https://storage.googleapis.com/gatk-software/package-archive/gatk/GenomeAnalysisTK-3.8-1-0-gf15c1c3ef.tar.bz2
BASEDIR=/scratch2/nvollmer/analysis/Clipped
BAMLIST=/scratch2/nvollmer/analysis/Clipped/bam_list.list #make sure file name ends in .list
REFERENCE=/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta #need to make sure reference is uncompressed and there is a .fai and .dict file - see gatk_fasta.txt

## Create list of potential in-dels
#java -Xmx96g -jar $GATK \
#	   -T RealignerTargetCreator \
#	   -R $REFERENCE \
#	   -I $BAMLIST \
#	   -o $BASEDIR'/all_samples_for_indel_realigner.intervals' \
#	   -drf BadMate

cd /scratch2/nvollmer/analysis/realign

## Run the indel realigner tool
java -Xmx96g -jar $GATK \
   -T IndelRealigner \
   -R $REFERENCE \
   -I $BAMLIST \
   -targetIntervals $BASEDIR'/intervals/concat.intervals' \ #this concat.invtervals file should have been previously created so make sure if the basedir is changed above that this line still takes you to the concat.intervals file
   --consensusDeterminationModel USE_READS  \
   --nWayOut _realigned.bam
