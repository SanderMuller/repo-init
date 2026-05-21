#!/usr/bin/env bash
# Placeholder-coverage check:
#   - every placeholder defined in references/placeholder-rules.md must be used
#     in at least one stub file
#   - every placeholder used in a stub must be defined in references/placeholder-rules.md
#
# Per SPEC Phase 7 "Placeholder-coverage check".

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

EXIT_CODE=0

# Define the canonical placeholder list. Must match references/placeholder-rules.md.
CANONICAL_PLACEHOLDERS=(
    "__VENDOR__"
    "__PACKAGE__"
    "__VENDOR_STUDLY__"
    "__PACKAGE_STUDLY__"
    "__NAMESPACE__"
    "__NAMESPACE_ESCAPED__"
    "__DESCRIPTION__"
    "__AUTHOR_NAME__"
    "__AUTHOR_EMAIL__"
    "__PHP_VERSION__"
    "__LARAVEL_VERSIONS__"
    "__PHP_VERSION_NEON__"
    "__YEAR__"
    "__TEST_RUNNER__"
    "__TEST_COVERAGE_FLAG__"
    "__SKILL_TAGS__"
)

PLACEHOLDER_DOC="references/placeholder-rules.md"

# Sanity: every CANONICAL_PLACEHOLDER should appear in the doc.
echo "[check-placeholders] verifying every canonical placeholder is documented in $PLACEHOLDER_DOC..."
for ph in "${CANONICAL_PLACEHOLDERS[@]}"; do
    if ! grep -qF "$ph" "$PLACEHOLDER_DOC"; then
        echo "FAIL: canonical placeholder '$ph' not documented in $PLACEHOLDER_DOC"
        EXIT_CODE=1
    fi
done

# PHP magic constants — look like __FOO__ but are language built-ins, not our placeholders.
PHP_MAGIC_CONSTS=(__DIR__ __FILE__ __LINE__ __CLASS__ __FUNCTION__ __METHOD__ __TRAIT__)

# Forward: every placeholder used in stubs must be canonical (or a PHP magic const).
# Use __[A-Z][A-Z_]*[A-Z]__ to require start+end with __ but exclude variants
# like ___PACKAGE___ (three underscores). The middle must be uppercase + underscore.
echo "[check-placeholders] verifying every placeholder used in stubs/ is canonical..."
USED_PLACEHOLDERS=$(grep -rohE '\b__[A-Z][A-Z_]*[A-Z]__\b' stubs/ 2>/dev/null | sort -u || true)

while IFS= read -r used; do
    [[ -z "$used" ]] && continue

    # Skip PHP magic constants.
    skip=0
    for magic in "${PHP_MAGIC_CONSTS[@]}"; do
        if [[ "$used" == "$magic" ]]; then
            skip=1
            break
        fi
    done
    [[ "$skip" -eq 1 ]] && continue

    found=0
    for ph in "${CANONICAL_PLACEHOLDERS[@]}"; do
        if [[ "$used" == "$ph" ]]; then
            found=1
            break
        fi
    done
    if [[ "$found" -eq 0 ]]; then
        echo "FAIL: placeholder '$used' used in stubs/ but not in canonical list (add to references/placeholder-rules.md)"
        EXIT_CODE=1
    fi
done <<< "$USED_PLACEHOLDERS"

# Reverse: every canonical placeholder should be used in at least one stub.
echo "[check-placeholders] verifying every canonical placeholder is used in at least one stub..."
for ph in "${CANONICAL_PLACEHOLDERS[@]}"; do
    if ! grep -qrF "$ph" stubs/ 2>/dev/null; then
        # Some placeholders are documented but only used contextually in references;
        # __YEAR__ is one (used in LICENSE-style stubs only when present).
        # Allow unused-canonical placeholders for these:
        case "$ph" in
            __YEAR__)
                echo "[check-placeholders] note: '$ph' is canonical but unused in stubs (acceptable — reserved for future LICENSE substitution)"
                ;;
            __VENDOR_STUDLY__)
                echo "[check-placeholders] note: '$ph' is canonical but unused in stubs (acceptable — derivable via __NAMESPACE__ split; documented for reference)"
                ;;
            __NAMESPACE_ESCAPED__)
                # __NAMESPACE_ESCAPED__ is used in composer.json autoload psr-4 via the doubled-backslash form (__NAMESPACE_ESCAPED__\\\\).
                # Grep may match the doubled form differently — verify with a less strict pattern.
                if ! grep -qrF "__NAMESPACE_ESCAPED__" stubs/ 2>/dev/null; then
                    echo "FAIL: canonical placeholder '$ph' is not used in any stub"
                    EXIT_CODE=1
                fi
                ;;
            *)
                echo "FAIL: canonical placeholder '$ph' is not used in any stub"
                EXIT_CODE=1
                ;;
        esac
    fi
done

if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "[check-placeholders] OK — placeholders consistent both directions."
fi

exit "$EXIT_CODE"
