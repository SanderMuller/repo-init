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

CATEGORIES=(laravel-project laravel-package php-package phpstan-extension rector-extension composer-plugin skill-bundle)
MODES=(bootstrap audit upgrade)

# Phase 8 LOW categories: bootstrap-only in v0.1 (audit/upgrade fall through to laravel-package phases).
BOOTSTRAP_ONLY_CATEGORIES=(filament-plugin nova-tool)

# Required references per mode (space-separated). Parallel to MODES.
REQUIRED_BOOTSTRAP="checklists/preflight.md checklists/post-bootstrap-verification.md references/detection-rules.md references/per-category-deps.md references/composer-failure-modes.md references/placeholder-rules.md"
REQUIRED_AUDIT="checklists/preflight.md references/detection-rules.md references/per-category-deps.md references/upgrade-merge-modes.md"
REQUIRED_UPGRADE="checklists/preflight.md checklists/per-category-never-touch.md checklists/post-upgrade-verification.md references/detection-rules.md references/per-category-deps.md references/upgrade-merge-modes.md references/composer-failure-modes.md references/composer-scripts.md"

# Phase 8 bootstrap-only phases use a relaxed required list (composer-failure-modes
# isn't strictly required since these phases delegate to bootstrap-laravel-package
# patterns; but they still must cite preflight + detection + deps + placeholders).
REQUIRED_BOOTSTRAP_ONLY="checklists/preflight.md checklists/post-bootstrap-verification.md references/detection-rules.md references/per-category-deps.md references/composer-failure-modes.md references/placeholder-rules.md"

echo "[check-phase-coverage] checking every (category × mode) phase file + 2 Phase 8 bootstrap-only..."

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

# Phase 8 bootstrap-only categories.
for category in "${BOOTSTRAP_ONLY_CATEGORIES[@]}"; do
    phase_file="phases/bootstrap-${category}.md"

    if [[ ! -f "$phase_file" ]]; then
        echo "FAIL: Phase 8 bootstrap phase missing: $phase_file"
        EXIT_CODE=1
        continue
    fi

    for ref in $REQUIRED_BOOTSTRAP_ONLY; do
        if ! grep -qE "(\\\$REPO_INIT_HOME/)?${ref//\//\\/}" "$phase_file"; then
            echo "FAIL: $phase_file does not reference $ref"
            EXIT_CODE=1
        fi
    done
done

# Phase 8 fall-through contract: each bootstrap-only category must declare
# `audit-via:` and `upgrade-via:` in the YAML, those targets must have real
# phase files, and SKILL.md must document the routing so the agent doesn't
# guess.
YML="references/per-category-deps.yml"
SKILL="resources/boost/skills/repo-init/SKILL.md"

if [[ ! -f "$YML" ]]; then
    echo "FAIL: $YML missing — can't verify Phase 8 fall-through contract."
    EXIT_CODE=1
fi

if [[ ! -f "$SKILL" ]]; then
    echo "FAIL: $SKILL missing — can't verify Phase 8 fall-through routing."
    EXIT_CODE=1
fi

for category in "${BOOTSTRAP_ONLY_CATEGORIES[@]}"; do
    # Extract audit-via / upgrade-via values from the YAML category block.
    # Match the category header line, then read forward until the next
    # top-level (2-space-indented) sibling category.
    audit_via=$(awk -v cat="  ${category}:" '
        $0 == cat { in_block=1; next }
        in_block && /^  [a-zA-Z]/ { in_block=0 }
        in_block && /^    audit-via:/ { sub(/^    audit-via: */, ""); print; exit }
    ' "$YML")

    upgrade_via=$(awk -v cat="  ${category}:" '
        $0 == cat { in_block=1; next }
        in_block && /^  [a-zA-Z]/ { in_block=0 }
        in_block && /^    upgrade-via:/ { sub(/^    upgrade-via: */, ""); print; exit }
    ' "$YML")

    if [[ -z "$audit_via" ]]; then
        echo "FAIL: $YML category '$category' missing 'audit-via:' (Phase 8 fall-through contract)"
        EXIT_CODE=1
    elif [[ ! -f "phases/audit-${audit_via}.md" ]]; then
        echo "FAIL: $YML category '$category' → audit-via: $audit_via, but phases/audit-${audit_via}.md missing"
        EXIT_CODE=1
    fi

    if [[ -z "$upgrade_via" ]]; then
        echo "FAIL: $YML category '$category' missing 'upgrade-via:' (Phase 8 fall-through contract)"
        EXIT_CODE=1
    elif [[ ! -f "phases/upgrade-${upgrade_via}.md" ]]; then
        echo "FAIL: $YML category '$category' → upgrade-via: $upgrade_via, but phases/upgrade-${upgrade_via}.md missing"
        EXIT_CODE=1
    fi

    # SKILL.md must mention the bootstrap-only category by name AND make
    # the fall-through explicit (so the agent doesn't try to open a
    # nonexistent audit-<category>.md).
    if ! grep -q "$category" "$SKILL"; then
        echo "FAIL: $SKILL does not mention bootstrap-only category '$category'"
        EXIT_CODE=1
    fi
    if ! grep -qE "Audit.*(fall through|fall-through|route).*laravel-package|$category.*laravel-package" "$SKILL"; then
        echo "FAIL: $SKILL does not document audit/upgrade fall-through for '$category' → laravel-package"
        EXIT_CODE=1
    fi
done

if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "[check-phase-coverage] OK — every (category × mode) phase references its required checklists + refs; Phase 8 fall-through contract honoured."
fi

exit "$EXIT_CODE"
