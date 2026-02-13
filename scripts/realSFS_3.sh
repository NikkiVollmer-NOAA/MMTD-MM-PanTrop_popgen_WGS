#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=himem
#SBATCH --cpus-per-task=8
#SBATCH --mem=200G
#SBATCH --time=72:00:00
#SBATCH --job-name=realSFS_Satt_3pop
#SBATCH --output=%x.%A.out
#SBATCH --error=%x.%A.err

module load bio/angsd/0.940
BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/saf_runs

# 1. Define where each population's SAF file lives using an associative array
declare -A POP_PATHS
POP_PATHS=(
    ["Satt_GOMx_merged_saf"]="$BASEDIR/Satt_GOMx"
    ["Satt_ATL_merged_saf"]="$BASEDIR/Satt_ATL"
    ["Satt_ETP_merged_saf"]="$BASEDIR/Satt_ETP"
)

# 2. List the population names for the loop
POPS=("Satt_GOMx_merged_saf" "Satt_ATL_merged_saf" "Satt_ETP_merged_saf")

THREADS=8

# Create a directory for the results
OUTDIR="${BASEDIR}/Satt_fst_results_3pop"
mkdir -p "$OUTDIR"

# Nested loop to perform all 6 pairwise comparisons
for (( i=0; i<${#POPS[@]}; i++ )); do
    for (( j=i+1; j<${#POPS[@]}; j++ )); do

        P1=${POPS[$i]}
        P2=${POPS[$j]}
        PAIR="${P1}_${P2}"

        # Pull the directory from our map
        DIR1=${POP_PATHS[$P1]}
        DIR2=${POP_PATHS[$P2]}

        # Construct full paths to the .saf.idx files
        SAF1="${DIR1}/${P1}.saf.idx"
        SAF2="${DIR2}/${P2}.saf.idx"

        echo "-------------------------------------------------------"
        echo "Comparing $P1 and $P2"
        echo "-------------------------------------------------------"
        
        # Verify files exist before running
        if [[ -f "$SAF1" && -f "$SAF2" ]]; then

            echo "Step A: Estimating 2D-SFS for $PAIR..."
            # We pipe directly to awk to ensure we get exactly 1 line for the Fst indexer
            realSFS "$SAF1" "$SAF2" -P $THREADS -nSites 20000000 | \
            awk '{for(i=1;i<=NF;i++) a[i]+=$i; n++} END {for(i=1;i<=NF;i++) printf "%.6f%s", a[i]/n, (i==NF?ORS:FS)}' > "${OUTDIR}/${PAIR}.2dsfs"

            # Step B: Index the Fst
            # We check if the SFS file was actually created and is not empty before proceeding
            if [ -s "${OUTDIR}/${PAIR}.2dsfs" ]; then
                echo "Step B: Indexing Fst for $PAIR..."
                realSFS fst index "$SAF1" "$SAF2" -sfs "${OUTDIR}/${PAIR}.2dsfs" -fstout "${OUTDIR}/${PAIR}" -P $THREADS

                echo "Step C: Calculating Global Stats for $PAIR..."
                realSFS fst stats "${OUTDIR}/${PAIR}.fst.idx" > "${OUTDIR}/${PAIR}_global.txt"

                echo "Step D: Calculating Sliding Windows for $PAIR..."
                realSFS fst stats2 "${OUTDIR}/${PAIR}.fst.idx" -win 50000 -step 10000 > "${OUTDIR}/${PAIR}.50k.windows.txt"

                echo "Finished $PAIR successfully."
            else
                echo "ERROR: SFS file for $PAIR is empty. Skipping Fst steps."
            fi

        else
            echo "SKIPPING: One or both SAF files not found!"
            echo "Checked: $SAF1"
            echo "Checked: $SAF2"
        fi
     done
done

