#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=8
#SBATCH --mem=20G
#SBATCH --time=48:00:00
#SBATCH --job-name=realSFS_Sfro_4pop
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err

module load bio/angsd/0.940
BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/saf_runs

# Create a directory for the results so your script folder stays clean
OUTDIR="${BASEDIR}/Sfro_fst_results_4pop"
mkdir -p "$OUTDIR"

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

THREADS=8

# --- FST PAIRWISE LOOP ---
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

            echo "Step A: Estimating 2D-SFS for $PAIR..."
            # We pipe directly to awk to ensure we get exactly 1 line for the Fst indexer
            realSFS "$SAF1" "$SAF2" -P $THREADS -nSites 20000000 | \
            awk '{for(i=1;i<=NF;i++) a[i]+=$i; n++} END {for(i=1;i<=NF;i++) printf "%.6f%s", a[i]/n, (i==NF?ORS:FS)}' > "${OUTDIR}/${PAIR}.2dsfs"

            # Check if SFS was created correctly
            if [ -s "${OUTDIR}/${PAIR}.2dsfs" ]; then

            # Step B: Index the Fst - note the code below can be used for reynold's FST or Hudson's FST - need to change hashed appropriately
            # We check if the SFS file was actually created and is not empty before proceeding
            
            # for Reynolds FST
            #    echo "Step B: Indexing Fst for $PAIR..."
            #    realSFS fst index "$SAF1" "$SAF2" -sfs "${OUTDIR}/${PAIR}.2dsfs" -fstout "${OUTDIR}/${PAIR}" -P $THREADS

            #    echo "Step C: Calculating Global Stats for $PAIR..."
            #    realSFS fst stats "${OUTDIR}/${PAIR}.fst.idx" > "${OUTDIR}/${PAIR}_global.txt"

            #    echo "Step D: Calculating Sliding Windows for $PAIR..."
            #    realSFS fst stats2 "${OUTDIR}/${PAIR}.fst.idx" -win 50000 -step 10000 > "${OUTDIR}/${PAIR}.50k.windows.txt"


         # Step B: Index Hudson Fst (-type 1)
            echo "Step B: Indexing Hudson Fst for $PAIR..."
            realSFS fst index "$SAF1" "$SAF2" -sfs "${OUTDIR}/${PAIR}.2dsfs" -fstout "${OUTDIR}/${PAIR}_hudson" -P $THREADS -type 1

            echo "Step C: Calculating Global Hudson Stats..."
            realSFS fst stats "${OUTDIR}/${PAIR}_hudson.fst.idx" > "${OUTDIR}/${PAIR}_hudson_global.txt"

            echo "Step D: Calculating Hudson Sliding Windows..."
            realSFS fst stats2 "${OUTDIR}/${PAIR}_hudson.fst.idx" -win 50000 -step 10000 > "${OUTDIR}/${PAIR}_hudson.50k.windows.txt"

            echo "Finished Fst for $PAIR successfully."
            
        else
            echo "ERROR: SFS file for $PAIR is empty. Skipping Fst steps."
        fi

    else
        echo "SKIPPING: One or both SAF files not found for $PAIR!"
    fi
   done
done

# Step E: Diversity and Thetas (Per population)
# This loop runs once per population to get pi and Tajima's D
echo "-------------------------------------------------------"
echo "Starting Diversity/Theta Calculations for all populations..."

for POP in "${POPS[@]}"; do
    echo "Processing Thetas for $POP..."
    DIR=${POP_PATHS[$POP]}
    SAF="${DIR}/${POP}.saf.idx"

    # 1D-SFS
    if [ ! -f "${OUTDIR}/${POP}.sfs" ]; then
        realSFS "$SAF" -P $THREADS -maxIter 100 > "${OUTDIR}/${POP}.sfs"
    fi

    # Raw Thetas
    if [ ! -f "${OUTDIR}/${POP}.thetas.idx" ]; then
        realSFS saf2theta "$SAF" -sfs "${OUTDIR}/${POP}.sfs" -outname "${OUTDIR}/${POP}" -P $THREADS
    fi

    # Windowed Diversity Stats (pi, Watterson's, Tajima's D)
    if [ ! -f "${OUTDIR}/${POP}.thetas.windows.gz.pestat" ]; then
        thetaStat do_stat "${OUTDIR}/${POP}.thetas.idx" -win 50000 -step 10000 -outnames "${OUTDIR}/${POP}.thetas.windows.gz"
    fi
done

echo "All tasks complete."
