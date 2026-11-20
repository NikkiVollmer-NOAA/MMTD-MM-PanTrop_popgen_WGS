#!/bin/bash
# =============================================================================
# 05_fix_config.sh
# Workaround for a MitoPilot 1.6.0 bug: the default resource closures in the
# project .config fail for processes with no options in the database
# (e.g. WF1:SCAFFOLD_JOIN:write_scaffold_mappings), giving:
#   ERROR ~ Unknown method invocation `multiply` on ConfigObject type
# Original lines 20-21:
#   cpus = { opts.cpus }
#   memory = { opts.memory.GB * task.attempt }
# Usage: bash scripts/05_fix_config.sh /path/to/project
# =============================================================================
set -euo pipefail
PROJECT=${1:?Usage: $0 /path/to/project}
CFG="$PROJECT/.config"

[[ -f "$CFG.bak" ]] || cp "$CFG" "$CFG.bak"   # keep the original only once

# Replace by pattern (safer than fixed line numbers)
sed -i 's|^\(\s*\)cpus = { opts.cpus }.*|\1cpus = { (opts.cpus instanceof Number) ? opts.cpus : 1 }|' "$CFG"
sed -i 's|^\(\s*\)memory = { opts.memory.GB \* task.attempt }.*|\1memory = { def m = (opts.memory instanceof Number) ? opts.memory : 4; m.GB * task.attempt }|' "$CFG"

echo "Patched lines:"
grep -n -E "cpus = \{|memory = \{" "$CFG"
