##before running this need to create the environment:
##while logged in to /scratch2/nvollmer I typed: 
##Create a new environment named 'dolphin_env'
#mamba create -n dolphin_env python=3.9 numpy
##Activate it
#mamba activate dolphin_env
##Install the high-speed VCF parser
#pip install cyvcf2

###Then can run following script

#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/roh
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --job-name=ROHw
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --partition=standard
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err

# Initialize Conda/Mamba for the bash script
source $(conda info --base)/etc/profile.d/conda.sh

# Activate the specific environment you created
conda activate ~/.conda/envs/dolphin_env

cd /scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/vcf/

python3 calc_window_het.py Satt_subset_154.bcf > Satt_1Mb_windows.csv

