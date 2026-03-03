#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=himem
#SBATCH --cpus-per-task=8
#SBATCH --mem=300G #this mem is needed for the GOMx pop
#SBATCH --time=96:00:00 ##all comparison will finish within a day except the GOM vs ATL
#SBATCH --job-name=realSFS_3pop
#SBATCH --output=%x.%A_%a.out
#SBATCH --error=%x.%A_%a.err
#SBATCH --array=0-2


module load bio/angsd/0.940

# --- Setup Paths ---
BASEDIR=/scratch2/nvollmer/analysis/Clipped/Clipped_Realigned/ANGSDresults/saf_runs
OUTDIR="${BASEDIR}/Satt_fst_results_3pop"

# Define Population Pairs
POPS=("Satt_GOMx_merged_saf" "Satt_ATL_merged_saf" "Satt_ETP_merged_saf")
P1_LIST=("${POPS[0]}" "${POPS[0]}" "${POPS[1]}")
P2_LIST=("${POPS[1]}" "${POPS[2]}" "${POPS[2]}")

P1=${P1_LIST[$SLURM_ARRAY_TASK_ID]}
P2=${P2_LIST[$SLURM_ARRAY_TASK_ID]}
PAIR="${P1}_${P2}"

# Map to actual file paths
SAF1="${BASEDIR}/${P1%_merged_saf}/${P1}.saf.idx"
SAF2="${BASEDIR}/${P2%_merged_saf}/${P2}.saf.idx"

echo "Processing $PAIR..."

# 1. Generate the 21-line SFS file
# Added -maxIter and -tole so it doesn't take 3 days
realSFS "$SAF1" "$SAF2" -P $SLURM_CPUS_PER_TASK -nSites 20000000 -maxIter 100 -tole 1e-6 > "${OUTDIR}/${PAIR}.mlines"

# 2. THE CRUCIAL AWK STEP
# This sums the 21 lines and collapses them into ONE line.
# This prevents the 'dimension prior' error.
awk '{for(i=1;i<=NF;i++) a[i]+=$i} END {for(i=1;i<=NF;i++) printf "%f%s", a[i], (i==NF?ORS:FS)}' "${OUTDIR}/${PAIR}.mlines" > "${OUTDIR}/${PAIR}.2dsfs"

# 3. Index and Stats - with option for Hudson's type 1, need to has out either FST lines or Hudson's lines depending on what you want to run
#if [ -s "${OUTDIR}/${PAIR}.2dsfs" ]; then
#    echo "Indexing Fst for $PAIR..."
#    realSFS fst index "$SAF1" "$SAF2" -sfs "${OUTDIR}/${PAIR}.2dsfs" -fstout "${OUTDIR}/${PAIR}" -P $SLURM_CPUS_PER_TASK

#    echo "Calculating Global Stats..."
#    realSFS fst stats "${OUTDIR}/${PAIR}.fst.idx" > "${OUTDIR}/${PAIR}_global.txt"

#echo "Calculating Sliding Windows..."
#    realSFS fst stats2 "${OUTDIR}/${PAIR}.fst.idx" -win 50000 -step 10000 > "${OUTDIR}/${PAIR}.50k.windows.txt"

if [ -s "${OUTDIR}/${PAIR}.2dsfs" ]; then
    echo "Indexing Hudson Fst (-type 1) for $PAIR..."
    realSFS fst index "$SAF1" "$SAF2" -sfs "${OUTDIR}/${PAIR}.2dsfs" -fstout "${OUTDIR}/${PAIR}" -P $SLURM_CPUS_PER_TASK -type 1    
        
    echo "Calculating Global Stats..."
    realSFS fst stats "${OUTDIR}/${PAIR}.fst.idx" -type 1 > "${OUTDIR}/${PAIR}_hudson_global.txt"

    echo "Calculating Sliding Windows..."
    realSFS fst stats2 "${OUTDIR}/${PAIR}.fst.idx" -type 1 -win 50000 -step 10000 > "${OUTDIR}/${PAIR}.50k.hudson_windows.txt"
    
    # Cleanup inside the 'if' block
    rm "${OUTDIR}/${PAIR}.mlines"
else
    echo "ERROR: SFS file was not created correctly for $PAIR."
    exit 1
fi

# 4. Diversity and Thetas (Per population)
# We check BOTH P1 and P2 to ensure all populations in the study are covered
for POP in "$P1" "$P2"; do
    echo "Checking Thetas for $POP..."

    # Step A: 1D-SFS
    if [ ! -f "${OUTDIR}/${POP}.sfs" ]; then
        echo "Generating 1D-SFS for $POP..."
        realSFS "${BASEDIR}/${POP%_merged_saf}/${POP}.saf.idx" -P $SLURM_CPUS_PER_TASK -maxIter 100 -tole 1e-6 > "${OUTDIR}/${POP}.sfs"
    fi

    # Step B: Raw thetas
    if [ ! -f "${OUTDIR}/${POP}.thetas.idx" ]; then
        echo "Estimating raw thetas for $POP..."
        realSFS saf2theta "${BASEDIR}/${POP%_merged_saf}/${POP}.saf.idx" -sfs "${OUTDIR}/${POP}.sfs" -outname "${OUTDIR}/${POP}" -P $SLURM_CPUS_PER_TASK
    fi

    # Step C: Diversity Stats
    if [ ! -f "${OUTDIR}/${POP}.thetas.windows.gz.pestat" ]; then
        echo "Calculating pi, Watterson, and Tajima's D for $POP..."
        thetaStat do_stat "${OUTDIR}/${POP}.thetas.idx" -win 50000 -step 10000 -outnames "${OUTDIR}/${POP}.thetas.windows.gz"
    fi
done
