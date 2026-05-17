#!/usr/bin/env bash
# Path-integrity check: every relative path referenced from .ai/skills/repo-init/SKILL.md,
# every phase file, every checklist, and every reference doc must actually exist
# in the package. Fails CI on dead links.
#
# Per SPEC Phase 7 "Path-integrity check" + RQ33 layout-matches-RQs guard.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

EXIT_CODE=0

# Files that may contain references:
TARGETS=(
    ".ai/skills/repo-init/SKILL.md"
    "SPEC.md"
    phases/*.md
    checklists/*.md
    references/*.md
)

# Path prefixes we care about (relative to repo root):
PATH_PATTERNS=(
    '\$REPO_INIT_HOME/[a-zA-Z0-9_./-]\+'
    'vendor/sandermuller/repo-init/[a-zA-Z0-9_./-]\+'
    'phases/[a-zA-Z0-9_./-]\+\.md'
    'checklists/[a-zA-Z0-9_./-]\+\.md'
    'references/[a-zA-Z0-9_./-]\+\.\(md\|yml\)'
    'stubs/[a-zA-Z0-9_./-]\+'
)

echo "[check-paths] scanning targets for cross-references..."

for target in "${TARGETS[@]}"; do
    [[ -f "$target" ]] || continue

    for pattern in "${PATH_PATTERNS[@]}"; do
        # Extract matches via grep -oE; strip the $REPO_INIT_HOME or vendor/... prefix
        # to get a repo-root-relative path.
        matches=$(grep -oE "$pattern" "$target" 2>/dev/null | sort -u || true)

        while IFS= read -r match; do
            [[ -z "$match" ]] && continue

            # Normalize: strip $REPO_INIT_HOME/ and vendor/sandermuller/repo-init/ prefixes.
            normalized="${match#\$REPO_INIT_HOME/}"
            normalized="${normalized#vendor/sandermuller/repo-init/}"

            # Skip noise: substitution-style examples like "stubs/<category>/" or
            # patterns with literal angle brackets / placeholder vars.
            if [[ "$normalized" == *"<"* || "$normalized" == *"__"* ]]; then
                continue
            fi

            # Skip filename-only patterns that are intentionally generic (no slash).
            if [[ "$normalized" != *"/"* && "$normalized" != *.md && "$normalized" != *.yml ]]; then
                continue
            fi

            if [[ ! -e "$normalized" ]]; then
                echo "FAIL: $target references missing path '$normalized' (matched pattern '$pattern')"
                EXIT_CODE=1
            fi
        done <<< "$matches"
    done
done

if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "[check-paths] OK — all referenced paths exist."
fi

exit "$EXIT_CODE"
