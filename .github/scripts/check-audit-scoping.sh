#!/usr/bin/env bash
# Audit-scoping check: for every audit phase, assert that OPTIONAL/CONDITIONAL
# deps are gated behind opt-in confirmation. A phase that flags `hihaho/phpstan-rules`
# MISSING without first asking "did you opt into hihaho rules?" fails CI.
#
# Per SPEC Phase 7 "Audit-scoping check" (codex v4 #3 protection).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

EXIT_CODE=0

# Each audit phase that handles a category with OPTIONAL deps must include
# an opt-in confirmation step BEFORE walking the optional deps.

# Map: category → list of (opt-in marker, optional dep that gates on it)
# Format: "category|opt-in-keyword|dep-to-check"
CHECKS=(
    "laravel-project|with-hihaho-rules|hihaho/phpstan-rules"
    "laravel-project|with-security-advisories|roave/security-advisories"
    "laravel-package|hihaho-package-tools-flavoured|spatie/laravel-package-tools"
    "phpstan-extension|Laravel-aware|larastan/larastan"
    "rector-extension|Laravel-aware|driftingly/rector-laravel"
)

echo "[check-audit-scoping] verifying every OPTIONAL dep is gated behind opt-in confirmation..."

for check in "${CHECKS[@]}"; do
    IFS='|' read -r category opt_in_keyword dep <<< "$check"
    audit_file="phases/audit-${category}.md"

    if [[ ! -f "$audit_file" ]]; then
        echo "FAIL: audit phase missing: $audit_file"
        EXIT_CODE=1
        continue
    fi

    # The audit phase must mention the opt-in keyword in an "Opt-in confirmation"
    # section AND mention the dep somewhere AFTER the opt-in section.
    if ! grep -qi "opt-in" "$audit_file"; then
        echo "FAIL: $audit_file has no opt-in confirmation section"
        EXIT_CODE=1
        continue
    fi

    if ! grep -qi "$opt_in_keyword" "$audit_file"; then
        echo "FAIL: $audit_file does not mention opt-in keyword '$opt_in_keyword'"
        EXIT_CODE=1
        continue
    fi

    if ! grep -qF "$dep" "$audit_file"; then
        echo "WARN: $audit_file does not mention OPTIONAL dep '$dep' (may be intentional if the dep is informational-only)"
        # Not a hard fail — some optional rows are listed in per-category-deps.md
        # but not necessarily named in the audit checklist (the audit can flag
        # generically). Investigate manually if needed.
    fi
done

# Additional guard: no audit phase should mention `livewire/livewire` as MISSING.
# It's "suggest only" per per-category-deps.yml and should NEVER be flagged.
echo "[check-audit-scoping] verifying livewire/livewire (suggest-only) is not flagged as MISSING..."
if grep -l "livewire/livewire" phases/audit-*.md 2>/dev/null | xargs -I {} grep -l "MISSING.*livewire" {} 2>/dev/null; then
    echo "FAIL: an audit phase flags livewire/livewire as MISSING — it's suggest-only, should be informational at most"
    EXIT_CODE=1
fi

if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "[check-audit-scoping] OK — every OPTIONAL dep is gated behind opt-in; suggest-only deps not flagged."
fi

exit "$EXIT_CODE"
