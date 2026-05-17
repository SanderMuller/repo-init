#!/usr/bin/env bash
# Phase-coverage check: every (category × mode) phase file must reference the
# shared checklists it needs (preflight, never-touch, post-*-verification, self-removal)
# and the category-specific reference docs.
#
# Per SPEC Phase 7 "Phase-coverage check".
#
# Bash 3.2 compatible (macOS) — uses parallel arrays instead of associative arrays.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

EXIT_CODE=0

CATEGORIES=(laravel-project laravel-package php-package phpstan-extension rector-extension)
MODES=(bootstrap audit upgrade)

# Required references per mode (space-separated). Parallel to MODES.
REQUIRED_BOOTSTRAP="checklists/preflight.md checklists/post-bootstrap-verification.md references/detection-rules.md references/per-category-deps.md references/composer-failure-modes.md references/placeholder-rules.md"
REQUIRED_AUDIT="checklists/preflight.md references/detection-rules.md references/per-category-deps.md references/upgrade-merge-modes.md"
REQUIRED_UPGRADE="checklists/preflight.md checklists/per-category-never-touch.md checklists/post-upgrade-verification.md references/detection-rules.md references/per-category-deps.md references/upgrade-merge-modes.md references/composer-failure-modes.md references/composer-scripts.md"

echo "[check-phase-coverage] checking 15 phase files..."

for category in "${CATEGORIES[@]}"; do
    for mode in "${MODES[@]}"; do
        phase_file="phases/${mode}-${category}.md"

        if [[ ! -f "$phase_file" ]]; then
            echo "FAIL: phase file missing: $phase_file"
            EXIT_CODE=1
            continue
        fi

        case "$mode" in
            bootstrap) required="$REQUIRED_BOOTSTRAP" ;;
            audit)     required="$REQUIRED_AUDIT" ;;
            upgrade)   required="$REQUIRED_UPGRADE" ;;
        esac

        # Check each required ref is cited in the phase file.
        for ref in $required; do
            # Match either bare path or path with $REPO_INIT_HOME/ prefix.
            if ! grep -qE "(\\\$REPO_INIT_HOME/)?${ref//\//\\/}" "$phase_file"; then
                echo "FAIL: $phase_file does not reference $ref"
                EXIT_CODE=1
            fi
        done
    done
done

if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "[check-phase-coverage] OK — every (category × mode) phase references its required checklists + refs."
fi

exit "$EXIT_CODE"
