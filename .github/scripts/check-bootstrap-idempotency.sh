#!/usr/bin/env bash
# Idempotency conformance check (RQ41 contract).
#
# Asserts that every phases/bootstrap-<category>.md file:
#   (a) has the **Idempotent.** banner at the top
#   (b) has a `## Idempotency invariants (RQ41 contract)` section at the bottom
#   (c) has at least one `**Skip if:**` precondition block in the Steps section
#
# This is structural, not behavioural — verifying the agent ACTUALLY honors
# the preconditions requires an end-to-end harness that drives the agent
# against a fixture target dir. That's tracked as Open Q #1 in
# specs/repo-new-cli.md.
#
# Bash 3.2 compatible.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

EXIT_CODE=0

BOOTSTRAP_PHASES=(
    phases/bootstrap-laravel-package.md
    phases/bootstrap-laravel-project.md
    phases/bootstrap-php-package.md
    phases/bootstrap-phpstan-extension.md
    phases/bootstrap-rector-extension.md
)

echo "[check-bootstrap-idempotency] verifying ${#BOOTSTRAP_PHASES[@]} bootstrap phase files have idempotency structure..."

for phase in "${BOOTSTRAP_PHASES[@]}"; do
    if [[ ! -f "$phase" ]]; then
        echo "FAIL: phase file missing: $phase"
        EXIT_CODE=1
        continue
    fi

    # (a) Idempotent banner at top.
    if ! head -10 "$phase" | grep -qF '**Idempotent.**'; then
        echo "FAIL: $phase missing '**Idempotent.**' banner near the top (per RQ41)"
        EXIT_CODE=1
    fi

    # (b) Idempotency invariants section at bottom.
    if ! grep -qF '## Idempotency invariants (RQ41 contract)' "$phase"; then
        echo "FAIL: $phase missing '## Idempotency invariants (RQ41 contract)' section at the bottom"
        EXIT_CODE=1
    fi

    # (c) At least 2 precondition blocks (one of the supported forms).
    skip_if_count=$(grep -cF '**Skip if:**' "$phase" || true)
    skip_per_file_count=$(grep -cF '**Skip per-file if:**' "$phase" || true)
    precondition_count=$(grep -cF '**Precondition check:**' "$phase" || true)
    total=$((skip_if_count + skip_per_file_count + precondition_count))

    if [[ "$total" -lt 2 ]]; then
        echo "FAIL: $phase has only $total precondition blocks (Skip if: / Skip per-file if: / Precondition check:); expected at least 2 for mutating steps"
        EXIT_CODE=1
    fi
done

if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "[check-bootstrap-idempotency] OK — all ${#BOOTSTRAP_PHASES[@]} bootstrap phase files conform to RQ41 idempotency structure."
fi

exit "$EXIT_CODE"
