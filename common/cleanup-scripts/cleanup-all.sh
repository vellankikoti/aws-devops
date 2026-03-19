#!/bin/bash
set -e
echo "=== Master Cleanup: All Days ==="
echo "Runs cleanup for each day in reverse order"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="${SCRIPT_DIR}/../.."

for day in 7 6 5 4 3 2 1; do
  script="${BASE}/day${day}-*/scripts/cleanup-day${day}.sh"
  if ls $script 1>/dev/null 2>&1; then
    echo "--- Day ${day} ---"
    bash $script 2>/dev/null || echo "Day ${day} cleanup had warnings (OK)"
    echo ""
  fi
done

echo "Master cleanup complete!"
