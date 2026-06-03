#!/usr/bin/env bash
# release.sh — GoPlacer release automation script.
#
# Usage:
#   ./scripts/release.sh <version>
#   ./scripts/release.sh <version> --dev
#   ./scripts/release.sh 0.1.0
#   ./scripts/release.sh 0.2.0-dev1 --dev
#
# What it does:
#   1. Validates git state (on main, clean working tree, tag does not exist)
#      and validates version format:
#        stable: X.Y.Z
#        dev:    X.Y.Z-devN
#   2. Creates release/vX.Y.Z branch from main
#   3. Requires a non-empty [Unreleased] section (prepare it first with
#      scripts/release/prepare_release_notes.sh)
#   4. Updates CHANGELOG.md — promotes [Unreleased] → [VERSION] — DATE and
#      inserts a fresh empty [Unreleased] section above it
#   5. Bumps version= in addons/go_placer/plugin.cfg
#   6. Runs verify.sh (GDScript syntax + lint)
#   7. Commits both files: "chore: bump version to vVERSION"
#   8. Creates annotated tag vVERSION on the release branch
#   9. Merges release branch back to main with --no-ff
#  10. Pushes main, release branch, and tag to origin

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

VERSION="${1:-}"
CHANNEL="${2:-stable}"

if [[ -z "$VERSION" ]]; then
    echo "Usage: scripts/release.sh <version> [--dev]  (e.g. 0.1.0 or 0.2.0-dev1 --dev)" >&2
    exit 1
fi

if [[ "$CHANNEL" != "stable" && "$CHANNEL" != "--dev" ]]; then
    echo "Error: unknown second argument '$CHANNEL' (expected '--dev' or omitted)" >&2
    exit 1
fi

IS_DEV=false
if [[ "$CHANNEL" == "--dev" ]]; then
    IS_DEV=true
fi

if $IS_DEV; then
    if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+-dev[0-9]+$ ]]; then
        echo "Error: dev version must match X.Y.Z-devN (e.g. 0.2.0-dev1)" >&2
        exit 1
    fi
else
    if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: stable version must match X.Y.Z (e.g. 0.1.0)" >&2
        exit 1
    fi
fi

TAG="v${VERSION}"
DATE=$(date +%Y-%m-%d)

echo "GoPlacer — Release $TAG ($DATE)"
echo "────────────────────────────────────────"

RELEASE_BRANCH="release/${TAG}"

BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" != "main" ]]; then
    echo "Error: must be on main (currently on '$BRANCH')" >&2
    exit 1
fi

if ! git diff --quiet HEAD 2>/dev/null; then
    echo "Error: working tree has uncommitted changes — commit or stash first" >&2
    git status --short >&2
    exit 1
fi

if git rev-parse "$TAG" &>/dev/null; then
    echo "Error: tag '$TAG' already exists" >&2
    exit 1
fi

if git rev-parse --verify "$RELEASE_BRANCH" &>/dev/null; then
    echo "Error: branch '$RELEASE_BRANCH' already exists" >&2
    exit 1
fi

if ! grep -q "^## \[Unreleased\]" CHANGELOG.md; then
    echo "Error: no '## [Unreleased]' section found in CHANGELOG.md" >&2
    exit 1
fi

if ! awk '
    /^## \[Unreleased\]/ { in_unreleased=1; next }
    in_unreleased && /^## \[/ { in_unreleased=0 }
    in_unreleased {
        if ($0 !~ /^[[:space:]]*$/ && $0 !~ /^---$/) {
            found=1
            exit 0
        }
    }
    END { exit found ? 0 : 1 }
' CHANGELOG.md; then
    echo "Error: [Unreleased] section is empty. Run scripts/release/prepare_release_notes.sh first." >&2
    exit 1
fi

echo "→ Creating branch $RELEASE_BRANCH from main..."
git checkout -b "$RELEASE_BRANCH"

echo "→ Updating CHANGELOG.md..."
sed -i "s/^## \[Unreleased\]/## [Unreleased]\n\n---\n\n## [${VERSION}] — ${DATE}/" CHANGELOG.md
echo "  ✓ [Unreleased] → [${VERSION}] — ${DATE}"

echo "→ Updating addons/go_placer/plugin.cfg..."
sed -i "s/^version=.*/version=\"${VERSION}\"/" addons/go_placer/plugin.cfg
echo "  ✓ version → ${VERSION}"

echo "→ Running verify.sh..."
if ! ./verify.sh; then
    echo "Error: verification failed. Fix issues before releasing." >&2
    git checkout -- CHANGELOG.md addons/go_placer/plugin.cfg
    git checkout main
    git branch -d "$RELEASE_BRANCH"
    exit 1
fi

echo "→ Committing..."
git add CHANGELOG.md addons/go_placer/plugin.cfg
git commit -m "chore: bump version to v${VERSION}"

echo "→ Tagging v${VERSION}..."
git tag -a "$TAG" -m "GoPlacer v${VERSION}"

echo "→ Merging back to main..."
git checkout main
git merge --no-ff "$RELEASE_BRANCH" -m "chore: merge release/${TAG} into main"

echo "→ Pushing..."
git push origin main
git push origin "$RELEASE_BRANCH"
git push origin "$TAG"

echo ""
echo "────────────────────────────────────────"
echo "✓ GoPlacer v${VERSION} released!"
echo "  Tag:     $TAG"
echo "  Branch:  $RELEASE_BRANCH"
echo ""
echo "Next steps:"
echo "  1. Wait for CI to pass on the tag."
echo "  2. Review and publish the draft GitHub Release."
echo "  3. Submit to the Godot Asset Library (if applicable)."