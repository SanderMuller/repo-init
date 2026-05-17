#!/usr/bin/env bash
# Stub-drift detection. Fetches each canonical reference repo via `gh api`,
# diffs the equivalent file against our stub (with placeholders substituted to
# the canonical's actual values for vendor/name/etc.), warns when drift exceeds
# a per-file threshold.
#
# Per SPEC Phase 7 "Stub drift detection". Runs weekly via stub-drift.yml.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Map: canonical-repo → category → reverse-substitution token pair.
# Format per line: "<owner>/<repo> <category> <repo-path-to-stub-eq> <stub-path>"
CANONICAL_CHECKS=(
    "SanderMuller/laravel-queue-insights laravel-package pint.json stubs/shared/pint.json"
    "SanderMuller/laravel-queue-insights laravel-package phpstan.neon.dist stubs/laravel-package/phpstan.neon.dist"
    "SanderMuller/laravel-queue-insights laravel-package testbench.yaml stubs/laravel-package/testbench.yaml"
    "SanderMuller/laravel-queue-insights laravel-package .editorconfig stubs/shared/.editorconfig"
    "SanderMuller/laravel-queue-insights laravel-package .github/dependabot.yml stubs/shared/.github/dependabot.yml"
    "SanderMuller/laravel-queue-insights laravel-package .github/workflows/phpstan.yml stubs/shared/.github/workflows/phpstan.yml"
    "SanderMuller/laravel-queue-insights laravel-package .github/workflows/pint-check.yml stubs/shared/.github/workflows/pint-check.yml"
    "SanderMuller/laravel-queue-insights laravel-package .github/workflows/rector-check.yml stubs/shared/.github/workflows/rector-check.yml"
    "SanderMuller/laravel-queue-insights laravel-package .github/workflows/update-changelog.yml stubs/shared/.github/workflows/update-changelog.yml"

    "SanderMuller/solana-pubkey php-package .lpv stubs/php-package/.lpv"
    "SanderMuller/solana-pubkey php-package pint.json stubs/shared/pint.json"

    "SanderMuller/laravel-fluent-validation-phpstan phpstan-extension pint.json stubs/shared/pint.json"

    "SanderMuller/laravel-fluent-validation-rector rector-extension pint.json stubs/shared/pint.json"
)

# Drift threshold (in changed lines). Exceeding triggers a warning.
THRESHOLD="${DRIFT_THRESHOLD:-5}"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

WARN_COUNT=0
DRIFT_REPORT="$TMP/drift-report.txt"
: > "$DRIFT_REPORT"

# Check if gh CLI is available + authenticated:
if ! command -v gh >/dev/null 2>&1; then
    echo "FAIL: gh CLI not installed. Stub-drift check needs `gh api` to fetch canonical refs."
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "FAIL: gh CLI not authenticated. Run `gh auth login` or set GH_TOKEN."
    exit 1
fi

echo "[stub-drift] checking ${#CANONICAL_CHECKS[@]} canonical-file ↔ stub pairs against drift threshold $THRESHOLD..."

for check in "${CANONICAL_CHECKS[@]}"; do
    read -r owner_repo category canonical_path stub_path <<< "$check"

    if [[ ! -f "$stub_path" ]]; then
        echo "WARN: local stub missing: $stub_path (skipping drift check)"
        continue
    fi

    # Fetch canonical file via gh api.
    canonical_url="repos/${owner_repo}/contents/${canonical_path}"
    canonical_content="$TMP/$(echo "$owner_repo/$canonical_path" | tr '/' '_')"

    if ! gh api "$canonical_url" --jq '.content' 2>/dev/null | base64 -d > "$canonical_content" 2>/dev/null; then
        echo "WARN: failed to fetch $owner_repo/$canonical_path (404 or rate-limit?)"
        continue
    fi

    # Substitute the canonical's vendor/package values back into our stub for fair comparison.
    vendor=$(echo "$owner_repo" | cut -d/ -f1 | tr '[:upper:]' '[:lower:]')
    package=$(echo "$owner_repo" | cut -d/ -f2)
    vendor_studly=$(echo "$owner_repo" | cut -d/ -f1)
    package_studly=$(echo "$package" | sed -E 's/(^|[-_])([a-z])/\U\2/g; s/[-_]//g')

    substituted="$TMP/stub-substituted-$(echo "$stub_path" | tr '/' '_')"
    sed \
        -e "s/__VENDOR__/$vendor/g" \
        -e "s/__PACKAGE__/$package/g" \
        -e "s/__VENDOR_STUDLY__/$vendor_studly/g" \
        -e "s/__PACKAGE_STUDLY__/$package_studly/g" \
        "$stub_path" > "$substituted"

    # Diff with unified output; count changed lines.
    if diff_output=$(diff -u "$substituted" "$canonical_content" 2>/dev/null); then
        # No drift.
        true
    else
        changed_lines=$(echo "$diff_output" | grep -cE '^[+-][^+-]' || echo 0)

        if [[ "$changed_lines" -gt "$THRESHOLD" ]]; then
            WARN_COUNT=$((WARN_COUNT + 1))
            {
                echo "## $stub_path vs $owner_repo/$canonical_path"
                echo ""
                echo "Drift: $changed_lines lines changed (threshold: $THRESHOLD)"
                echo ""
                echo '```diff'
                echo "$diff_output" | head -50
                echo '```'
                echo ""
            } >> "$DRIFT_REPORT"
        fi
    fi
done

if [[ "$WARN_COUNT" -gt 0 ]]; then
    echo ""
    echo "[stub-drift] $WARN_COUNT stub(s) drifted beyond threshold."
    echo "[stub-drift] Drift report:"
    echo ""
    cat "$DRIFT_REPORT"

    # If running in CI and DRIFT_OPEN_ISSUE=1, open a GitHub issue.
    if [[ "${DRIFT_OPEN_ISSUE:-0}" == "1" ]]; then
        echo "[stub-drift] opening tracking issue..."
        gh issue create \
            --title "Stub drift detected ($(date +%Y-%m-%d))" \
            --body-file "$DRIFT_REPORT" \
            --label drift,automated || true
    fi

    # Don't fail CI on drift — it's informational. Exit 0.
    exit 0
fi

echo "[stub-drift] OK — all stubs within drift threshold of canonical references."
