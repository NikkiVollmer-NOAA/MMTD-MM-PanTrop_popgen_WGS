#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --job-name=realign
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err
#SBATCH --cpus-per-task=6   # 6 data threads + 4 GC threads
#SBATCH --mem=300G #had this at 72 but we think it kept getting stuck so upped it a lot
#SBATCH --partition=standard          
#SBATCH --time=99:00:00
#SBATCH --array=1-22%4 # 21 large scaffolds. then lump the rest into 1

####It was going to take more than a month to complete the realignment with out paralellizing it (using the realign_realign.sh code) so decided to 
#break it up by running the 21 biggest scaffolds - presumably the chromosomes - each separately, then doing all the remaining smaller scaffolds 
#together in one lump

# split the array by scaffold
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# make a list of scaffolds, before running the array script:
# cat /scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta.fai | awk '{ print $1":1-"$2}' | cut -f 1 -d ":" > all_scaffolds.list

GATK=~/bin/GenomeAnalysisTK.jar
BASEDIR=/scratch2/nvollmer/analysis/Clipped/intervals/ 
BAMLIST=/scratch2/nvollmer/analysis/Clipped/bam_list.list
REFERENCE=/scratch2/nvollmer/refseq/Stenella_attenuata_HiC.fasta
SCAFFOLD_LIST=/scratch2/nvollmer/analysis/Clipped/all_scaffolds.list

mkdir -p ${BASEDIR}

cd /scratch2/nvollmer/analysis/Clipped

# for the first 21 chrs, run them separately. 
if [[ ${SLURM_ARRAY_TASK_ID} -le 21 ]]; then
  scaffold_name=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${SCAFFOLD_LIST})
  intervals="-L ${scaffold_name}"
  output_file="${BASEDIR}/scaffold_${SLURM_ARRAY_TASK_ID}.intervals"
else
  # for the other many scaffolds, that are small, run as one. so exclude the first 21
  intervals="-XL HiC_scaffold_1 -XL HiC_scaffold_2 -XL HiC_scaffold_3 -XL HiC_scaffold_4 -XL HiC_scaffold_5 -XL HiC_scaffold_6 -XL HiC_scaffold_7 -XL HiC_scaffold_8 -XL HiC_scaffold_9 -XL HiC_scaffold_10 -XL HiC_scaffold_11 -XL HiC_scaffold_12 -XL HiC_scaffold_13 -XL HiC_scaffold_14 -XL HiC_scaffold_15 -XL HiC_scaffold_16 -XL HiC_scaffold_17 -XL HiC_scaffold_18 -XL HiC_scaffold_19 -XL HiC_scaffold_20 -XL HiC_scaffold_21"
  output_file="${BASEDIR}/small_scaffolds.intervals"
fi

java -Xmx280G -jar ${GATK} \
  -T RealignerTargetCreator \
  -nt 4 \
  -R ${REFERENCE} \
  ${intervals} \
  -I ${BAMLIST} \
  -o ${output_file} \
  -drf BadMate
