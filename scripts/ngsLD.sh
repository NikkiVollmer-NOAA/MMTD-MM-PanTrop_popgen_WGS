#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/array_ngsld
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=himem
#SBATCH --cpus-per-task=6
#SBATCH --mem=20G
#SBATCH --time=48:00:00
#SBATCH --job-name=ngsld
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err
#SBATCH --array=1-21%4 #just running the first 21 scaffolds

module load bio/ngsld/1.2.0

BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/GLF_2
SCAFFOLD_NAMES=/scratch2/nvollmer/refseq/ref_chrom.list
SCAFFOLD_DIR=/scratch2/nvollmer/refseq
SCAFFOLD_NAMES_target=$(cat $SCAFFOLD_DIR/ref_chrom.txt | sed -n ${SLURM_ARRAY_TASK_ID}p)
SCAFFOLD_NAMES_target_name=${SCAFFOLD_NAMES_target/.txt/}
N_SITES=$(grep -w $SCAFFOLD_NAMES_target_name $BASEDIR/sites_10.txt | cut -f 2)


ngsLD \
--geno ${BASEDIR}/${SCAFFOLD_NAMES_target_name}_subsampled_10.beagle.gz \
--pos ${BASEDIR}/${SCAFFOLD_NAMES_target_name}_subsampled_10.pos.gz \
--probs \
--n_ind 190 \
--n_sites $N_SITES \
--max_kb_dist 25 \
--n_threads 6 \
--out $BASEDIR/ngsLD_25kb/${SCAFFOLD_NAMES_target}.ld

#am using max_kb_dist = 25 (25kb) based on LDdecay graphs


