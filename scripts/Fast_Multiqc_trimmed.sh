#!/bin/bash
#SBATCH --job-name=fastqc
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -D /scratch2/nvollmer/log
#SBATCH -c 14
#SBATCH --partition=standard
#SBATCH --time=24:00:00

#see Fast_Multiqc.sh for some additional notes

source ~/.bashrc

# load fastqc and multiqc
mamba activate multiqc-1.17

module load bio/fastqc/0.11.9


cd /scratch2/nvollmer/trimmed-trimmomatic

for input_dir in 241129_NOA015_PanTrop_WGS 241129_NOA016_PanTrop_WGS 250103_NOA015_RERUN_PanTrop_WGS 250115_NOA016_PanTrop_WGS_8Satt149-152
do
    mkdir -p analysis/fastqc_trimmed/${input_dir}/
    fastqc -t 14 --noextract -o analysis/fastqc_trimmed/${input_dir}/ ${input_dir}/*.fq.gz

    multiqc analysis/fastqc_trimmed/${input_dir}/ -o  analysis/fastqc_trimmed/ --filename multiqc_trimmed_report_${input_dir}
done

