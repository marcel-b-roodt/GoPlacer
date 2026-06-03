#!/usr/bin/env bash
# run_tests.sh — Run GdUnit4 tests headlessly via Godot.
#
# Usage:
#   ./scripts/run_tests/run_tests.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

GODOT="${GODOT:-godot}"

if ! command -v "$GODOT" &>/dev/null; then
    echo "ERROR: godot not found in PATH. Set GODOT=/path/to/godot or install Godot." >&2
    exit 1
fi

echo "Running GdUnit4 tests headlessly..."
"$GODOT" --headless --path "$REPO_ROOT" -s res://addons/gdUnit4/src/GdUnitRunner.tscn 2>&1
echo "Done."