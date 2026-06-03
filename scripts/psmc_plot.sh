#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/psmc
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=1:00:00
#SBATCH --job-name=psmc_plot
#SBATCH --output=%x.%A.out
#SBATCH --error=%x.%A.err

# =============================================================================
# Step 7: Plot PSMC results for all 8 individuals
# Produces plots scaled by mutation rate and generation time
# =============================================================================

RESDIR="/scratch2/nvollmer/psmc/results"
OUTDIR="/scratch2/nvollmer/psmc/plots"
mkdir -p ${OUTDIR}

echo "================================================"
echo "Job started: $(date)"
echo "================================================"

source /opt/bioinformatics/mambaforge/etc/profile.d/conda.sh
conda activate psmc

# =============================================================================
# Scaling parameters — ADJUST THESE if you change your assumptions
#
# Mutation rate: 2.5e-8 per base per generation
#   This is borrowed from humans. Cetacean-specific rates are poorly
#   constrained. Some studies use 1.7e-8 for dolphins.
#   Sensitivity analyses at 1.7e-8 and 2.5e-8 are recommended.
#
# Generation time: 23 years (as used in your SMC++ analysis)
#   Range in literature for S. attenuata: ~11-23 years
#   Run sensitivity analyses at g=12 and g=23 to bracket uncertainty
# =============================================================================

MU="2.5e-8"   # mutation rate per base per generation
GEN=23        # generation time in years

# Sample arrays matching results directories
ATL_SAMPLES=(7Satt014 7Satt013 Satt008 7Satt015)
GOM_SAMPLES=(8Satt068 515-01 8Satt196 8Satt040)

# Build input file list and label string
COMBINED_FILES=""
LABELS=""

for s in "${ATL_SAMPLES[@]}"; do
    COMBINED_FILES="${COMBINED_FILES} ${RESDIR}/${s}/${s}_combined.psmc"
    LABELS="${LABELS}${s}_ATL,"
done
for s in "${GOM_SAMPLES[@]}"; do
    COMBINED_FILES="${COMBINED_FILES} ${RESDIR}/${s}/${s}_combined.psmc"
    LABELS="${LABELS}${s}_GOM,"
done

# Remove trailing comma from labels
LABELS=${LABELS%,}

# Check all input files exist
echo "Checking input files..."
for s in "${ATL_SAMPLES[@]}" "${GOM_SAMPLES[@]}"; do
    f="${RESDIR}/${s}/${s}_combined.psmc"
    if [ ! -f "${f}" ]; then
        echo "ERROR: Missing combined PSMC file: ${f}"
        echo "Make sure Step 6 completed for all samples."
        exit 1
    fi
    echo "  Found: ${f}"
done

# =============================================================================
# Plot 1: All 8 individuals together
# =============================================================================
echo ""
echo "[$(date)] Generating combined plot (all individuals)..."

psmc_plot.pl \
    -u ${MU} \
    -g ${GEN} \
    -M "${LABELS}" \
    -x 1e4 \
    -X 1e7 \
    -Y 5e5 \
    ${OUTDIR}/all_individuals \
    ${COMBINED_FILES}

# =============================================================================
# Plot 2: ATL individuals only
# =============================================================================
echo "[$(date)] Generating ATL-only plot..."

ATL_FILES=""
ATL_LABELS=""
for s in "${ATL_SAMPLES[@]}"; do
    ATL_FILES="${ATL_FILES} ${RESDIR}/${s}/${s}_combined.psmc"
    ATL_LABELS="${ATL_LABELS}${s},"
done
ATL_LABELS=${ATL_LABELS%,}

psmc_plot.pl \
    -u ${MU} \
    -g ${GEN} \
    -M "${ATL_LABELS}" \
    -x 1e4 \
    -X 1e7 \
    ${OUTDIR}/ATL_only \
    ${ATL_FILES}

# =============================================================================
# Plot 3: GOM individuals only
# =============================================================================
echo "[$(date)] Generating GOM-only plot..."

GOM_FILES=""
GOM_LABELS=""
for s in "${GOM_SAMPLES[@]}"; do
    GOM_FILES="${GOM_FILES} ${RESDIR}/${s}/${s}_combined.psmc"
    GOM_LABELS="${GOM_LABELS}${s},"
done
GOM_LABELS=${GOM_LABELS%,}

psmc_plot.pl \
    -u ${MU} \
    -g ${GEN} \
    -M "${GOM_LABELS}" \
    -x 1e4 \
    -X 1e7 \
    ${OUTDIR}/GOM_only \
    ${GOM_FILES}

# =============================================================================
# Sensitivity: re-plot with alternative generation time g=12
# =============================================================================
echo "[$(date)] Generating sensitivity plot (g=12)..."

psmc_plot.pl \
    -u ${MU} \
    -g 12 \
    -M "${LABELS}" \
    -x 1e4 \
    -X 1e7 \
    ${OUTDIR}/all_individuals_g12 \
    ${COMBINED_FILES}

echo ""
echo "================================================"
echo "PLOTS WRITTEN TO: ${OUTDIR}/"
echo "================================================"
echo "  all_individuals.eps   — all 8 samples, g=${GEN}"
echo "  ATL_only.eps          — Atlantic samples only"
echo "  GOM_only.eps          — Gulf of Mexico samples only"
echo "  all_individuals_g12.eps — sensitivity check at g=12"
echo ""
echo "To convert EPS to PDF for viewing:"
echo "  module load ghostscript"
echo "  gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=plot.pdf plot.eps"
echo ""
echo "Job finished: $(date)"
echo "================================================"
