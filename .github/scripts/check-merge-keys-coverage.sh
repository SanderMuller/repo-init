#!/usr/bin/env bash
# Merge-keys-covers-extras check: assert each upgrade phase covers every
# documented composer.json key in §9 / references/composer-scripts.md, not
# just `scripts`.
#
# Per SPEC Phase 7 "Merge-keys covers extras check" (codex v4 #4 protection).
#
# Bash 3.2 compatible (macOS) — uses parallel arrays.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

EXIT_CODE=0

# Each upgrade phase must mention these composer.json keys in its merge-keys step.

# Common keys ALL upgrade phases must cover:
COMMON_KEYS="scripts config.allow-plugins config.sort-packages"

# Per-category-specific keys (parallel arrays).
PHASE_NAMES=(
    "upgrade-laravel-package.md"
    "upgrade-laravel-project.md"
    "upgrade-php-package.md"
    "upgrade-phpstan-extension.md"
    "upgrade-rector-extension.md"
)
SPECIFIC_KEYS=(
    "extra.laravel.providers autoload-dev.psr-4"
    ""
    ""
    "extra.phpstan.includes autoload-dev.classmap"
    "extra.rector.includes"
)

echo "[check-merge-keys-coverage] checking 5 upgrade phase files..."

i=0
while [[ "$i" -lt "${#PHASE_NAMES[@]}" ]]; do
    phase_name="${PHASE_NAMES[$i]}"
    specific="${SPECIFIC_KEYS[$i]}"
    phase_file="phases/${phase_name}"

    # All common keys:
    for key in $COMMON_KEYS; do
        if ! grep -qF "$key" "$phase_file"; then
            echo "FAIL: $phase_name does not mention common merge-key '$key' in its merge-keys section"
            EXIT_CODE=1
        fi
    done

    # Per-category specific keys:
    if [[ -n "$specific" ]]; then
        for key in $specific; do
            if ! grep -qF "$key" "$phase_file"; then
                echo "FAIL: $phase_name does not mention category-specific merge-key '$key'"
                EXIT_CODE=1
            fi
        done
    fi

    i=$((i + 1))
done

if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "[check-merge-keys-coverage] OK — every upgrade phase covers its required composer.json keys."
fi

exit "$EXIT_CODE"
