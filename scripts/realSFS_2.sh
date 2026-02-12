#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=medmem
#SBATCH --cpus-per-task=4
#SBATCH --mem=120G
#SBATCH --time=24:00:00
#SBATCH --job-name=realSFS_Sfro_4pop
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err

module load bio/angsd/0.940
BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/saf_runs

# 1. Define where each population's SAF file lives
declare -A POP_PATHS
POP_PATHS=(
    ["Sfro_eGOMx_merged_saf"]="$BASEDIR/Sfro_eGOMx"
    ["Sfro_wGOMx_merged_saf"]="$BASEDIR/Sfro_wGOMx"
    ["Sfro_sWNA_merged_saf"]="$BASEDIR/Sfro_sWNA"
    ["Sfro_Oceanic_merged_saf"]="$BASEDIR/Sfro_Oceanic"
)

# 2. List the population names (keys from the array above)
POPS=("Sfro_eGOMx_merged_saf" "Sfro_wGOMx_merged_saf" "Sfro_sWNA_merged_saf" "Sfro_Oceanic_merged_saf")

THREADS=4

# Create a directory for the results so your script folder stays clean
OUTDIR="${BASEDIR}/Sfro_fst_results_4pop"
mkdir -p "$OUTDIR"

for (( i=0; i<${#POPS[@]}; i++ )); do
    for (( j=i+1; j<${#POPS[@]}; j++ )); do

        P1=${POPS[$i]}
        P2=${POPS[$j]}
        PAIR="${P1}_${P2}"

        # Pull the directory from our map
        DIR1=${POP_PATHS[$P1]}
        DIR2=${POP_PATHS[$P2]}

        # Construct full paths
        SAF1="${DIR1}/${P1}.saf.idx"
        SAF2="${DIR2}/${P2}.saf.idx"

        echo "-------------------------------------------------------"
        echo "Comparing $P1 (in $DIR1) and $P2 (in $DIR2)"

        # Verify files exist before running
        if [[ -f "$SAF1" && -f "$SAF2" ]]; then

            # Step A: Estimate 2D-SFS (Subsampled to 20M sites)...
            realSFS "$SAF1" "$SAF2" -P $THREADS -nSites 20000000 > "${OUTDIR}/${PAIR}.2dsfs"

            # Step B: Index the Fst
            realSFS fst index "$SAF1" "$SAF2" -sfs "${OUTDIR}/${PAIR}.2dsfs" -fstout "${OUTDIR}/${PAIR}"

            # Step C: Global Stats
            realSFS fst stats "${OUTDIR}/${PAIR}.fst.idx" > "${OUTDIR}/${PAIR}_global.txt"

            # Step D: Sliding Window Analysis
            #-win 50000: 50kb window size
            #-step 10000: 10kb slide (results in 40kb overlap)
            echo "Calculating sliding window for $PAIR..."
            realSFS fst stats2 "${OUTDIR}/${PAIR}.fst.idx" -win 50000 -step 10000 > "${OUTDIR}/${PAIR}.50k.windows.txt"

            echo "Finished $PAIR"
        else
            echo "SKIPPING: One or both files not found!"
            echo "Checked: $SAF1"
            echo "Checked: $SAF2"
        fi
    done
done


            # Step B: Index the Fst
