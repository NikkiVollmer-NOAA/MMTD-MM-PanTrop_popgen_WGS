#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/psmc
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=7-00:00:00
#SBATCH --job-name=psmc
#SBATCH --output=%x.%A_%a.out
#SBATCH --error=%x.%A_%a.err
#SBATCH --array=0-7

# =============================================================================
# Step 6: Run PSMC + 100 bootstraps per individual
# Runs as a job array — one job per individual simultaneously
# Bootstraps are parallelized across your 4 CPUs within each job
# Runtime estimate: 4-12 hours per individual including bootstraps
# =============================================================================

# NOTE: Requires bio/psmc/0.6.5 module on Sedna HPC
# Verify with: module load bio/psmc/0.6.5 && psmc 2>&1 | head -3

SAMPLES=(7Satt014  7Satt013  Satt008  7Satt015  8Satt068  515-01   8Satt196  8Satt040)
POPS=(    ATL       ATL       ATL      ATL       GOM       GOM      GOM       GOM     )

SAMPLE=${SAMPLES[$SLURM_ARRAY_TASK_ID]}
POP=${POPS[$SLURM_ARRAY_TASK_ID]}

PSMCFA_DIR="/scratch2/nvollmer/psmc/consensus"
OUTDIR="/scratch2/nvollmer/psmc/results/${SAMPLE}"
BOOTDIR="${OUTDIR}/bootstraps"
mkdir -p ${OUTDIR}
mkdir -p ${BOOTDIR}

echo "================================================"
echo "Job started: $(date)"
echo "Sample:      ${SAMPLE} (${POP})"
echo "================================================"

module load bio/psmc/0.6.5

# Verify psmc is available
if ! command -v psmc &> /dev/null; then
    echo "ERROR: psmc not found. Install with:"
    echo "  mamba create -n psmc -c bioconda -c conda-forge psmc"
    exit 1
fi

PSMCFA="${PSMCFA_DIR}/${SAMPLE}.psmcfa"
if [ ! -f "${PSMCFA}" ]; then
    echo "ERROR: psmcfa not found: ${PSMCFA}"
    echo "Make sure Step 5 (consensus_array) completed for this sample."
    exit 1
fi

# =============================================================================
# 6a. Run PSMC
# -N25  : max 25 EM iterations
# -t15  : initial theta (scaled mutation rate) — 15 is standard
# -r5   : initial rho/theta ratio
# -p    : time interval pattern
#         "4+25*2+4+6" is standard — 64 free parameters
#         captures both ancient and recent history
# =============================================================================
echo ""
echo "[$(date)] Running PSMC..."

psmc \
    -N25 \
    -t15 \
    -r5 \
    -p "4+25*2+4+6" \
    -o ${OUTDIR}/${SAMPLE}.psmc \
    ${PSMCFA}

echo "[$(date)] PSMC complete."

# =============================================================================
# 6b. Split psmcfa for bootstrapping
# /opt/bioinformatics/bio/psmc/psmc-0.6.5/utils/splitfa randomly resamples segments of the psmcfa
# This accounts for LD structure along chromosomes
# =============================================================================
echo ""
echo "[$(date)] Generating bootstrap replicates..."

/opt/bioinformatics/bio/psmc/psmc-0.6.5/utils/splitfa ${PSMCFA} > ${OUTDIR}/${SAMPLE}_split.psmcfa

# Run 100 bootstraps in parallel using background processes
# Batched into groups of 4 to match your CPU count
N_BOOT=100
BATCH_SIZE=${SLURM_CPUS_PER_TASK}

for i in $(seq 1 ${N_BOOT}); do
    psmc \
        -N25 -t15 -r5 -b \
        -p "4+25*2+4+6" \
        -o ${BOOTDIR}/${SAMPLE}_boot_${i}.psmc \
        ${OUTDIR}/${SAMPLE}_split.psmcfa &

    # Every BATCH_SIZE jobs, wait for them to finish before launching more
    if (( i % BATCH_SIZE == 0 )); then
        wait
        echo "[$(date)] Completed bootstrap batch $((i/BATCH_SIZE)) of $((N_BOOT/BATCH_SIZE))"
    fi
done
wait  # catch any remaining background jobs
echo "[$(date)] All 100 bootstraps complete."

# =============================================================================
# 6c. Combine main run + bootstraps into a single file for plotting
# =============================================================================
echo ""
echo "[$(date)] Combining results..."

cat \
    ${OUTDIR}/${SAMPLE}.psmc \
    ${BOOTDIR}/${SAMPLE}_boot_*.psmc \
    > ${OUTDIR}/${SAMPLE}_combined.psmc

echo "Combined file: ${OUTDIR}/${SAMPLE}_combined.psmc"

# Generate R-ready text tables
PLOTDIR="/scratch2/nvollmer/psmc/results/${SAMPLE}/R_tables"
mkdir -p ${PLOTDIR}

/opt/bioinformatics/bio/psmc/psmc-0.6.5/utils/psmc_plot.pl \
    -u 2.5e-8 \
    -g 23 \
    -R \
    ${PLOTDIR}/${SAMPLE} \
    ${OUTDIR}/${SAMPLE}_combined.psmc

echo "R table written to: ${PLOTDIR}/${SAMPLE}.0.txt"

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "================================================"
echo "PSMC SUMMARY: ${SAMPLE}"
echo "================================================"
echo "Main PSMC:       ${OUTDIR}/${SAMPLE}.psmc"
echo "Bootstraps:      ${BOOTDIR}/${SAMPLE}_boot_1-100.psmc"
echo "Combined output: ${OUTDIR}/${SAMPLE}_combined.psmc"
echo ""
echo "Job finished: $(date)"
echo "================================================"
