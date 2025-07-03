#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=12G
#SBATCH --time=24:00:00
#SBATCH --job-name=angsd
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err

module load bio/angsd/0.940
module load bio/samtools/1.19

BASEDIR=/scratch2/nvollmer/analysis/Clipped
REFERENCE=/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta

#looking at one chromosome at the first 500k bp for a faster test of the code
#these filters will retain only uniquely mapping reads, not tagged as bad, considering only proper pairs, without trimming, 
#and adjusting for indel/mapping (as in samtools). -C 50 reduces the effect of reads with excessive mismatches, 
#while -baq 1 computes base alignment quality as explained here (BAQ) used to rule out false SNPs close to INDELS.
angsd -b  $BASEDIR/ANGSD_bams.txt -ref $REFERENCE -out $BASEDIR/ANGSD \
	-uniqueOnly 1 -remove_bads 1 -only_proper_pairs 1 -trim 0 -minMapQ 25 -minQ 25 -skipTriallelic 1 \
  -setMinDepth 3 -minInd 142 -SNP_pval 1e-6 -doMajorMinor 1 -doMaf 1 -minMAF 0.05 \
  -GL 1 -doGLF 2 #2=GATK or 1=Samtools; 4=output in text format 2=beagle and seems popular

#	-r chr1:1-500000
##unsure if I should use
-C 50 #reduces the effect of reads with excessive mismatches
-baq 1 #computes base alignment quality used to rule out false SNPs close to INDELS
#-minInd 142 #use only sites with data from at least 75% individuals, 142 of 190
-setMinDepth 1 #Discard site if total sequencing depth (all individuals added together) is below [int]. Requires -doCounts
-setMaxDepth 30 #Filters out sites where the total depth across all individuals exceeds a threshold. Requires -doCounts
-setMinDepthInd #Discard individual if sequencing depth for an individual is below [int]. This filter is only applied to analysis which are based on counts of alleles i.e. analysis that uses -doCounts
-setMaxDepthInd #Discard individual if sequencing depth for an individual is above [int] This filter is only applied to analysis which are based on counts of alleles i.e. analysis that uses -doCounts
-doCounts 1 ##count # ATCG at all sites and samples
#-SNP_pval 1e-6 #Remove sites with a pvalue larger
-sb_pval 1e-6
-hwe_pval 0.05
-hetbias_pval 1e-5
-edge_pval 1e-4
-mapQ_pval 1e-4
#-minMAF #remove sites with MAF below
#-doMaf	 #Calculate persite frequencies '.mafs.gz'
-P or -nThreads #sets # of threads to use
#-doMajorMinor 1 #Infer the major/minor using different approaches - 1= from GL; 4 = use ref allele as major, requires ref
-geno_minDepth #Only call genotypes if the depth is as least [int] for that individuals This requires -doCounts and -doGeno















