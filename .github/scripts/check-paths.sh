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

# Phase files reference stub files by RELATIVE path (e.g. `src/ToolServiceProvider.php`).
# Map each bootstrap phase to its matching stub tree and verify backtick-quoted
# relative paths in the phase exist in the corresponding stub tree.
#
# Format: "<phase-file>|<stub-tree>"
PHASE_STUB_PAIRS=(
    "phases/bootstrap-laravel-package.md|stubs/laravel-package"
    "phases/bootstrap-laravel-package.md|stubs/laravel-package-spatie"
    "phases/bootstrap-laravel-project.md|stubs/laravel-project"
    "phases/bootstrap-php-package.md|stubs/php-package"
    "phases/bootstrap-phpstan-extension.md|stubs/phpstan-extension"
    "phases/bootstrap-rector-extension.md|stubs/rector-extension"
    "phases/bootstrap-filament-plugin.md|stubs/filament-plugin"
    "phases/bootstrap-nova-tool.md|stubs/nova-tool"
)

# Patterns that signal "a stub-relative path the phase wants the agent to copy":
# `src/...`, `tests/...`, `config/...`, `resources/...`, `dist/...`, `routes/...`,
# `workbench/...`, `bin/...`. Backtick-quoted in markdown to be precise.
STUB_RELATIVE_PATTERN='`(src|tests|config|resources|dist|routes|workbench|bin)/[a-zA-Z0-9_./*-]+`'

for pair in "${PHASE_STUB_PAIRS[@]}"; do
    phase_file="${pair%|*}"
    stub_tree="${pair#*|}"

    [[ ! -f "$phase_file" ]] && continue
    [[ ! -d "$stub_tree" ]] && continue

    # Extract backtick-quoted relative paths matching the pattern.
    relative_paths=$(grep -oE "$STUB_RELATIVE_PATTERN" "$phase_file" 2>/dev/null | tr -d '`' | sort -u || true)

    while IFS= read -r relpath; do
        [[ -z "$relpath" ]] && continue

        # Skip wildcards and placeholder-bearing paths.
        [[ "$relpath" == *"*"* ]] && continue
        [[ "$relpath" == *"<"* ]] && continue

        # Skip dist/ paths — these are build outputs the user generates, never shipped in stubs.
        [[ "$relpath" == dist/* ]] && continue

        # Skip example-filled paths (StudlyCase names that aren't placeholder strings).
        # Heuristic: if the path contains uppercase letters BUT NOT the literal placeholder
        # string `__PACKAGE_STUDLY__`, it's likely an illustrative example.
        if [[ "$relpath" =~ [A-Z] && "$relpath" != *"__PACKAGE_STUDLY__"* && "$relpath" != *"__VENDOR_STUDLY__"* ]]; then
            continue
        fi

        # Check primary stub tree → fallback to stubs/shared → fallback to other variant trees for the phase.
        candidate_paths=(
            "$stub_tree/$relpath"
            "stubs/shared/$relpath"
        )
        for other_pair in "${PHASE_STUB_PAIRS[@]}"; do
            other_phase="${other_pair%|*}"
            other_stub="${other_pair#*|}"
            [[ "$other_phase" != "$phase_file" ]] && continue
            [[ "$other_stub" == "$stub_tree" ]] && continue
            candidate_paths+=("$other_stub/$relpath")
        done

        found=0
        for candidate in "${candidate_paths[@]}"; do
            if [[ -e "$candidate" ]]; then
                found=1
                break
            fi
        done

        if [[ "$found" -eq 0 ]]; then
            echo "FAIL: $phase_file references stub-relative '$relpath' but it doesn't exist in $stub_tree, stubs/shared/, or any variant stub tree"
            EXIT_CODE=1
        fi
    done <<< "$relative_paths"
done

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
