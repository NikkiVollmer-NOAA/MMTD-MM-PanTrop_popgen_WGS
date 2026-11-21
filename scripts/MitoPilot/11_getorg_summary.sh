#!/bin/bash
# =============================================================================
# 11_getorg_summary.sh
# One-line-per-sample summary of GetOrganelle results for a MitoPilot project:
#   sample, result status, average mito base coverage, estimated coverage.
# Must be run BEFORE deleting the project's work/ folder (logs live there).
# Sorted by coverage (lowest first) so problem samples appear at the top.
# Good: "circular genome" with coverage in the tens-hundreds.
# Bad:  "N scaffold(s)" and/or coverage ~10x (likely NUMT fragments).
# Usage: bash scripts/11_getorg_summary.sh /scratch2/nvollmer/MitoPilot/Stenella_batch1
# =============================================================================
set -uo pipefail
PROJECT=${1:?Usage: $0 /path/to/project}
cd "$PROJECT"

printf "sample\tstatus\tavg_cov\test_cov\n"
for LOG in $(find work -path "*/assemble/get_org.log.txt"); do
  s=$(basename "$(dirname "$(dirname "$LOG")")")
  st=$(grep "Result status" "$LOG" | tail -1 | sed 's/.*anonym: //; s/ /_/g')
  cov=$(grep "Average anonym base-coverage" "$LOG" | tail -1 | awk '{print $NF}')
  est=$(grep "Estimated anonym-hitting base-coverage" "$LOG" | tail -1 | awk '{print $NF}')
  printf "%s\t%s\t%s\t%s\n" "$s" "${st:-NA}" "${cov:-NA}" "${est:-NA}"
done | sort -t$'\t' -k3,3g

# Note: with -resume, a sample may have more than one log in work/ (e.g. a rerun);
# check the newest one if a sample appears twice.
