#!/bin/bash
# =============================================================================
# 11_getorg_summary.sh
# One-line-per-sample summary of GetOrganelle results for a MitoPilot project:
#   sample, result status, average mito base coverage, estimated coverage.
# Uses the NEWEST log per sample (after a rerun with -resume, a sample has
# more than one log in work/; the newest is the one that counts).
# Also copies each sample's newest log to <project>/getorg_logs/.
# Must be run BEFORE deleting the project's work/ folder (logs live there).
# Sorted by coverage (lowest first) so problem samples appear at the top.
# Good: "circular_genome" with coverage in the tens-hundreds.
# Bad:  "N_scaffold(s)" with coverage ~10x (NUMT fragments; see
#       15_getorg_rescue_test.sh and the 200x read-cap fix).
# Usage: bash scripts/11_getorg_summary.sh /scratch2/nvollmer/MitoPilot/Stenella_batch3
# Output: <project>/getorg_summary.tsv (also printed) and <project>/getorg_logs/
# =============================================================================
set -uo pipefail
PROJECT=${1:?Usage: $0 /path/to/project}
cd "$PROJECT"
mkdir -p getorg_logs

{
printf "sample\tstatus\tavg_cov\test_cov\n"
for s in $(awk -F, 'NR>1{print $1}' mapping.csv); do
  LOGS=$(find work -path "*/$s/assemble/get_org.log.txt" 2>/dev/null)
  if [[ -z "$LOGS" ]]; then printf "%s\tNO_LOG\tNA\tNA\n" "$s"; continue; fi
  LOG=$(ls -t $LOGS | head -1)
  cp "$LOG" "getorg_logs/${s}_get_org.log.txt"
  st=$(grep "Result status" "$LOG" | tail -1 | sed 's/.*anonym: //; s/ /_/g')
  cov=$(grep "Average anonym base-coverage" "$LOG" | tail -1 | awk '{print $NF}')
  est=$(grep "Estimated anonym-hitting base-coverage" "$LOG" | tail -1 | awk '{print $NF}')
  printf "%s\t%s\t%s\t%s\n" "$s" "${st:-NA}" "${cov:-NA}" "${est:-NA}"
done | sort -t$'\t' -k3,3g
} | tee getorg_summary.tsv

echo; cut -f2 getorg_summary.tsv | tail -n +2 | sort | uniq -c
