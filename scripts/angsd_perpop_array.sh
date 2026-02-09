

#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=himem
#SBATCH --cpus-per-task=6
#SBATCH --mem=100G
#SBATCH --time=24:00:00
#SBATCH --job-name=angsd_Satt_G
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err
#SBATCH --array=1-21%4 #just running the first 21 scaffolds

module load bio/angsd/0.940

### https://www.popgen.dk/angsd/index.php/Fst

BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned
REFERENCE=/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta
SCAFFOLD_DIR=/scratch2/nvollmer/refseq
SCAFFOLD_NAMES=/scratch2/nvollmer/refseq/ref_chrom.list

SCAFFOLD_NAMES_target=$(cat $SCAFFOLD_DIR/ref_chrom.txt | sed -n ${SLURM_ARRAY_TASK_ID}p)
SCAFFOLD_NAMES_target_name=${SCAFFOLD_NAMES_target/.txt/}

angsd -b $BASEDIR/ANGSD_bams_Satt_GOMx.txt -anc $REFERENCE -out $BASEDIR/ANGSDresults/$SCAFFOLD_NAMES_target -r $SCAFFOLD_NAMES_target \
        -dosaf 1 -gl 1 -nthreads 6


