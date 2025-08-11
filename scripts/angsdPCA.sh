#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=himem
#SBATCH --cpus-per-task=6
#SBATCH --mem=200G
#SBATCH --time=7-00
#SBATCH --job-name=angsdPCA
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err

module load bio/angsd/0.940


BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned
REF=/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta
SNPLIST=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/GLF_2/ngsLD_25kb/AllScaffolds_snps.list

angsd sites index $SNPLIST


angsd -b $BASEDIR/ANGSD_bams.txt -anc $REF -out $BASEDIR/ANGSDresults/GLF_2/ngsLD_25kb/PCA_LDpruned \
    -GL 1 -doGlf 2 -doMajorMinor 3 -doMAF 1 -doPost 1 -doIBS 1 -doCounts 1 -doCov 1 -makeMatrix 1 \
    -rf $BASEDIR/ANGSDresults/GLF_2/ngsLD_25kb/chrs.txt -sites $SNPLIST

#chrs.txt is a text file that list the name of the 1st 21 scaffolds so that the analysis is limited to just those
