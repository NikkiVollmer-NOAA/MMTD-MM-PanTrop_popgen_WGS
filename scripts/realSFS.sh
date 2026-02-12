#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=70G
#SBATCH --time=2:00:00
#SBATCH --job-name=realSFS
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err

module load bio/angsd/0.940
BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/saf_runs

#for calculating per pop saf for each population. This first step combines all the saf files for each scaffold into a single saf file
realSFS cat -b $BASEDIR/Sfro_wGOMx/saf_list.txt -outnames $BASEDIR/Sfro_wGOMx/Sfro_wGOMx_merged_saf -P 4

#for calculating the 2dsfs prior_can do standard; 4 cpu; 70GB mem
realSFS $BASEDIR/Sfro_wGOMx/Sfro_wGOMx_merged_saf.saf.idx $BASEDIR/Sfro_eGOMx/Sfro_eGOMx_merged_saf.saf.idx > $BASEDIR/Sfro_eGOMx_wGOMx.global.sfs -P 4


##-P is number of threads, https://www.popgen.dk/angsd/index.php/RealSFS#Merge_SAF_files
##make sure saf_list.txt has pathway for every file
