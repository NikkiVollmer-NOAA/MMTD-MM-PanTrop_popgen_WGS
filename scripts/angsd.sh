#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=himem
#SBATCH --cpus-per-task=6
#SBATCH --mem=100G
#SBATCH --time=24:00:00
#SBATCH --job-name=angsd
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err
#SBATCH --array=1-21%4 #just running the first 21 scaffolds 

module load bio/angsd/0.940
module load bio/samtools/1.19

BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned
REFERENCE=/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta
SCAFFOLD_DIR=/scratch2/nvollmer/refseq
SCAFFOLD_NAMES=/scratch2/nvollmer/refseq/ref_chrom.list

SCAFFOLD_NAMES_target=$(cat $SCAFFOLD_DIR/ref_chrom.txt | sed -n ${SLURM_ARRAY_TASK_ID}p)
SCAFFOLD_NAMES_target_name=${SCAFFOLD_NAMES_target/.txt/}

angsd -b  $BASEDIR/ANGSD_bams.txt -ref $REFERENCE -out $BASEDIR/ANGSDresults/$SCAFFOLD_NAMES_target -rf $SCAFFOLD_NAMES_target \
	-uniqueOnly 1 -remove_bads 1 -only_proper_pairs 1 -trim 0 -minMapQ 25 -minQ 25 -skipTriallelic 1 \
  	-doCounts 1 -minInd 142 -SNP_pval 1e-6 -doMajorMinor 1 -doMaf 1 -minMAF 0.05 \
 	-GL 1 -doGLF 2 -doPost 1 -nThreads 6 -dobcf 1 #2=GATK or 1=Samtools; 4=output in text format or 2=beagle and seems popular

#	-r HiC_scaffold_1:1-500000
#####unsure if I should use anything below this line for first run, those with ## are in the code above, those with # are not
#-C 50 #reduces the effect of reads with excessive mismatches
#-baq 1 #computes base alignment quality used to rule out false SNPs close to INDELS
##-minInd 142 #use only sites with data from at least 75% individuals, 142 of 190
#-setMinDepth 1 #Discard site if total sequencing depth (all individuals added together) is below [int]. Requires -doCounts
#-setMaxDepth 30 #Filters out sites where the total depth across all individuals exceeds a threshold. Requires -doCounts
#-setMinDepthInd #Discard individual if sequencing depth for an individual is below [int]. This filter is only applied to analysis which are based on counts of alleles i.e. analysis that uses -doCounts
#-setMaxDepthInd #Discard individual if sequencing depth for an individual is above [int]. This filter is only applied to analysis which are based on counts of alleles i.e. analysis that uses -doCounts
##-doCounts 1 ##count # ATCG at all sites and samples
##-SNP_pval 1e-6 #Remove sites with a pvalue larger
#-sb_pval 1e-6
#-hwe_pval 0.05
#-hetbias_pval 1e-5
#-edge_pval 1e-4
#-mapQ_pval 1e-4
##-minMAF #remove sites with MAF below
##-doMaf	 #Calculate persite frequencies '.mafs.gz'
##-P or -nThreads #sets # of threads to use
##-doMajorMinor 1 #Infer the major/minor using different approaches - 1= from GL; 4 = use ref allele as major, requires ref
#-geno_minDepth #Only call genotypes if the depth is as least [int] for that individuals This requires -doCounts and -doGeno















