#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/rclone_transfer
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=12:00:00
#SBATCH --job-name=rclone_transfer
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err

#####script used to transfer batches of fastqs back to sedna#####

module load tools/rclone/1.73.0

# --- Edit these as needed ---
REMOTE_PATH='test_shared:"Genetics Raw Data/NGS_Data/PanTrop_WGS_GreenCanyon_rawdata/250103_NOA015_RERUN_PanTrop_WGS"'
DEST_PATH="/scratch2/nvollmer/analysis/NOA015rerun"
INCLUDE_FILE="/scratch2/nvollmer/analysis/NOA015rerun/sample_ids_1.txt"
BWLIMIT="8.5M"
# -----------------------------

echo "Job started: $(date)"
echo "Running on host: $(hostname)"

# Make sure the destination directory exists
mkdir -p "$DEST_PATH"

# Sanity check: confirm filtered size before transferring
echo "Checking filtered file count/size..."
eval rclone size $REMOTE_PATH --include-from "$INCLUDE_FILE"

echo "Starting transfer..."
eval rclone copy -P --bwlimit $BWLIMIT $REMOTE_PATH $DEST_PATH \
  --include-from "$INCLUDE_FILE" \
  --log-file=rclone_transfer_${SLURM_JOB_ID}.rclonelog \
  --log-level INFO

echo "Job finished: $(date)"
