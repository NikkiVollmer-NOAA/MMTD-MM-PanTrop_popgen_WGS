#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=himeme
#SBATCH --cpus-per-task=6
#SBATCH --mem=200G
#SBATCH --time=7-00
#SBATCH --job-name=angsdPCAall
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err

module load bio/angsd/0.940


BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned
REF=/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta


angsd -b $BASEDIR/ANGSD_bams.txt -anc $REF -out $BASEDIR/ANGSDresults/GLF_2/PCA_allSNPs/PCA \
    -minMapQ 20 -minQ 20 -doMaf 1 -minMaf 0.05 -SNP_pval 2e-6 \
    -GL 1 -doGlf 2 -doMajorMinor 1 -doPost 1 \
    -doIBS 1 -doCounts 1 -doCov 1 -makeMatrix 1 -P 4

#the angsd parameters come directly from the link below to make a PCA with all SNPs
#https://github.com/nt246/lcwgs-guide-tutorial/blob/main/tutorial3_ld_popstructure/markdowns/pca_admixture.md#optional-compare-the-results-to-a-pca-based-on-all-snps
