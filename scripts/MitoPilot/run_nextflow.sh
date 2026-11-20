#!/bin/bash
# =============================================================================
# run_nextflow.sh
# SLURM wrapper for a MitoPilot module (Assemble = WF1, Annotate = WF2).
# 1. In the MitoPilot GUI, choose the module, click Update, copy the Nextflow command.
# 2. Paste it as NF_CMD below (keep the single quotes), set PROJECT and the job name.
# 3. sbatch scripts/run_nextflow.sh   (from any directory)
# Add -resume to the command to reuse finished tasks after a failure.
# =============================================================================
#SBATCH --job-name=MitoPilot
#SBATCH --output=MitoPilot_%x_%j.out
#SBATCH --error=MitoPilot_%x_%j.err
#SBATCH -p standard
#SBATCH -c 1
#SBATCH --mem=8G
#SBATCH -t 24:00:00

PROJECT=/scratch2/nvollmer/MitoPilot/test_project
NF_CMD='PASTE_NEXTFLOW_COMMAND_FROM_GUI_HERE'

echo "Job $SLURM_JOB_ID started on $SLURM_JOB_NODELIST at $(date)"

source ~/.bashrc              # provides NXF_SINGULARITY_CACHEDIR
mamba activate MitoPilot_deps
cd "$PROJECT"

eval "$NF_CMD"

echo "Job finished at $(date)"

# Examples used for the test project:
#  Assemble:
#   nextflow -log $PROJECT/.runs/nextflow/assemble_<date>.nextflow.log run \
#     ~/.conda/envs/MitoPilot_deps/lib/R/library/MitoPilot/nextflow \
#     -c $PROJECT/.config -entry WF1 -resume
#  Annotate:
#   nextflow -log $PROJECT/.runs/nextflow/annotate_<date>.nextflow.log run \
#     ~/.conda/envs/MitoPilot_deps/lib/R/library/MitoPilot/nextflow \
#     -c $PROJECT/.config -entry WF2 -resume
#
# Monitor:
#   squeue -u $USER
#   tail -15 $(ls -t MitoPilot_*.out | head -1)
#   grep -E "Succeeded|Failed|ERROR|Completed" $(ls -t MitoPilot_*.out | head -1)
