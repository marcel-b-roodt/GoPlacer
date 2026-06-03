#!/usr/bin/env bash
# prepare_release_notes.sh — helper to prepare changelog entries before a release.
#
# Usage:
#   ./scripts/release/prepare_release_notes.sh
#
# Opens CHANGELOG.md in your default editor with instructions for adding
# entries to the [Unreleased] section.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

if [ ! -f CHANGELOG.md ]; then
    echo "Error: CHANGELOG.md not found in repo root." >&2
    exit 1
fi

echo "Add your release notes under the [Unreleased] section in CHANGELOG.md."
echo "Example format:"
echo ""
echo "### Added"
echo "- New feature description"
echo ""
echo "### Fixed"
echo "- Bug fix description"
echo ""
echo "Then run:  scripts/release.sh <version>"

if command -v nano &>/dev/null; then
    nano CHANGELOG.md
elif command -v vim &>/dev/null; then
    vim CHANGELOG.md
else
    echo "No editor found. Edit CHANGELOG.md manually." >&2
fi