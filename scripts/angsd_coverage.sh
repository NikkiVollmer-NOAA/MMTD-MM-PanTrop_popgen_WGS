  GNU nano 2.9.8                                                          angsd.sh

#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/array_angsd
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
#REF_INDEXED=/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta.fai
SCAFFOLD_DIR=/scratch2/nvollmer/refseq
SCAFFOLD_NAMES=/scratch2/nvollmer/refseq/ref_chrom.list

SCAFFOLD_NAMES_target=$(cat $SCAFFOLD_DIR/ref_chrom.txt | sed -n ${SLURM_ARRAY_TASK_ID}p)
SCAFFOLD_NAMES_target_name=${SCAFFOLD_NAMES_target/.txt/}

angsd -b $BASEDIR/ANGSD_bams.txt -ref $REFERENCE -out $BASEDIR/ANGSDresults/$SCAFFOLD_NAMES_target -r $SCAFFOLD_NAMES_target \
        -uniqueOnly 1 -remove_bads 1 -only_proper_pairs 1 -trim 0 -minMapQ 25 -minQ 25 -skipTriallelic 1 \
        -doCounts 1 -minInd 142 -SNP_pval 1e-6 -doMajorMinor 1 -doMaf 1 -minMAF 0.05 \
        -GL 1 -doGLF 4 -doPost 1 -nThreads 6 -dobcf 1




