#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/prune_graph
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=40G
#SBATCH --time=24:00:00
#SBATCH --job-name=prune_graph
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err
#SBATCH --array=1-21%4 #just running the first 21 scaffolds

module load bio/prune_graph/0.3.4

BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/GLF_2/ngsLD
SCAFFOLD_NAMES=/scratch2/nvollmer/refseq/ref_chrom.list
SCAFFOLD_DIR=/scratch2/nvollmer/refseq
SCAFFOLD_NAMES_target=$(cat $SCAFFOLD_DIR/ref_chrom.txt | sed -n ${SLURM_ARRAY_TASK_ID}p)
SCAFFOLD_NAMES_target_name=${SCAFFOLD_NAMES_target/.txt/}


cat ${BASEDIR}/${SCAFFOLD_NAMES_target_name} | prune_graph --weight-field "column_7" --weight-filter "column_7 ≥ 0.2"--out ${BASEDIR}/$SCAFFOLD_NAMES_target.keep
