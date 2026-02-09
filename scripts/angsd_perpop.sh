#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=70G
#SBATCH --time=48:00:00
#SBATCH --job-name=angsd_Satt_G
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err

module load bio/angsd/0.940

### this code was run on groups separately to produce saf files to eventually calculate Fst between the groups. Had to make a bam list for the groups I wanted
### first and ran this code separately on each group.

BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned
REFERENCE=/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta

angsd -b $BASEDIR/ANGSD_bams_Sfro_eGOMx.txt -anc $REFERENCE -out $BASEDIR/ANGSDresults/Sfro_eGOMx -dosaf 1 -gl 1
