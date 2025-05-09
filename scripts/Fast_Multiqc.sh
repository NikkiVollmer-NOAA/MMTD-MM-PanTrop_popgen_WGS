#!/bin/bash
#SBATCH --job-name=fastqc
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -D /scratch2/nvollmer/log
#SBATCH -c 14
#SBATCH --partition=standard
#SBATCH --time=6:00:00

#might need to increase the time above if doing big files/directories

source ~/.bashrc

# load fastqc and multiqc
mamba activate multiqc-1.17

module load bio/fastqc/0.11.9


cd /scratch2/nvollmer

#can list all the directories for which there are reads to evaluate, separated by a space
for input_dir in 250103_NOA016_RERUN_PanTrop_WGS 250115_NOA016_PanTrop_WGS_8Satt149-152
do
    mkdir -p analysis/fastqc/${input_dir}/

#double check if fastq files are named .fastq.gz or .fq.gz or something else and change the last part of line 28 accordingly
    fastqc -t 14 --noextract -o analysis/fastqc/${input_dir}/ ${input_dir}/*.fastq.gz

    multiqc analysis/fastqc/${input_dir}/ -o  analysis/fastqc/ --filename multiqc_report_${input_dir}
done
