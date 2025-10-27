#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/evaladmix
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=20G
#SBATCH --time=24:00:00
#SBATCH --job-name=evaladmix
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err


module load bio/evaladmix/0.962

BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned
NGSADMIX_DIR=$BASEDIR/ANGSDresults/GLF_2/ngsLD_25kb/ngsadmix
BEAGLE_FILE=$BASEDIR/ANGSDresults/GLF_2/ngsLD_25kb/PCA_LDpruned.beagle.gz

# --- Loop over all .fopt.gz files ---
# This loop finds every file ending in .fopt.gz in the directory
for fopt_file in $NGSADMIX_DIR/PCA_LDpruned_ngsAdmix_*.fopt.gz
do
    # Check if a file was found (prevents errors if no files match)
    [ -e "$fopt_file" ] || continue

    echo "--- Processing file: $fopt_file ---"

    # 1. Get the file prefix (e.g., ".../PCA_LDpruned_ngsAdmix_K2")
    # This command removes the '.fopt.gz' suffix from the variable
    prefix="${fopt_file%.fopt.gz}"

    # 2. Define the corresponding .qopt and a *unique* output file
    qopt_file="${prefix}.qopt"
    output_file="${prefix}_Evaladmix_output.corres.txt"

    # 3. Run evalAdmix with the specific file paths
    evalAdmix -beagle $BEAGLE_FILE \
              -fname $fopt_file \
              -qname $qopt_file \
              -P 4 \
              -o $output_file

    echo "Finished. Output saved to: $output_file"
    echo "--------------------------------------"
done

echo "All evalAdmix runs complete."
