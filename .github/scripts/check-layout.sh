#!/usr/bin/env bash
# Layout-matches-Resolved-Qs check: assert the package layout matches what the
# SPEC's Resolved Questions claim. Specifically guards against drift in:
#   - stubs/laravel-package-spatie/ (RQ18 — separate stub tree, not in-flight mutation)
#   - references/upgrade-merge-modes.md (RQ25)
#   - references/composer-failure-modes.md (RQ27)
#   - references/placeholder-rules.md (RQ26)
#   - references/per-category-deps.yml (RQ38 — structured source of truth)
#
# Per SPEC Phase 7 "Layout-matches-Resolved-Qs check" (codex v4 #5 protection).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

EXIT_CODE=0

REQUIRED_PATHS=(
    # Skill + checklists
    "resources/boost/skills/repo-init/SKILL.md"
    "checklists/preflight.md"
    "checklists/per-category-never-touch.md"
    "checklists/post-bootstrap-verification.md"
    "checklists/post-upgrade-verification.md"
    "checklists/self-removal.md"

    # All 14 references (incl. .yml parallel)
    "references/canonical-repos.md"
    "references/composer-failure-modes.md"
    "references/composer-scripts.md"
    "references/detection-rules.md"
    "references/gitattributes-managed-block.md"
    "references/per-category-deps.md"
    "references/per-category-deps.yml"
    "references/pest-vs-phpunit.md"
    "references/phpstan-config.md"
    "references/placeholder-rules.md"
    "references/rector-config.md"
    "references/shared-dev-deps.md"
    "references/upgrade-merge-modes.md"
    "references/version-defaults.md"

    # All 15 phase files (5 categories × 3 modes)
    "phases/bootstrap-laravel-package.md"
    "phases/bootstrap-laravel-project.md"
    "phases/bootstrap-php-package.md"
    "phases/bootstrap-phpstan-extension.md"
    "phases/bootstrap-rector-extension.md"
    "phases/audit-laravel-package.md"
    "phases/audit-laravel-project.md"
    "phases/audit-php-package.md"
    "phases/audit-phpstan-extension.md"
    "phases/audit-rector-extension.md"
    "phases/upgrade-laravel-package.md"
    "phases/upgrade-laravel-project.md"
    "phases/upgrade-php-package.md"
    "phases/upgrade-phpstan-extension.md"
    "phases/upgrade-rector-extension.md"

    # composer-plugin category (added in 0.3.0)
    "phases/bootstrap-composer-plugin.md"
    "phases/audit-composer-plugin.md"
    "phases/upgrade-composer-plugin.md"
    "references/phpunit-config.md"

    # skill-bundle category (added in 0.5.0)
    "phases/bootstrap-skill-bundle.md"
    "phases/audit-skill-bundle.md"
    "phases/upgrade-skill-bundle.md"
    "stubs/skill-bundle/composer.json"

    # Stub trees — directories, not files (one sentinel file checked per tree)
    "stubs/shared/pint.json"
    "stubs/shared/.config/boost.php"
    "stubs/laravel-package/composer.json"
    "stubs/laravel-package-spatie/composer.json"
    "stubs/php-package/composer.json"
    "stubs/phpstan-extension/composer.json"
    "stubs/rector-extension/composer.json"
    "stubs/laravel-project/boost.json"
    "stubs/composer-plugin/composer.json"
    "stubs/composer-plugin/src/Plugin.none.php"
    "stubs/composer-plugin/src/Plugin.command-provider.php"
    "stubs/composer-plugin/src/Plugin.event-subscriber.php"
    "stubs/composer-plugin/src/Plugin.both.php"
    "stubs/composer-plugin/src/CommandProvider.php"

    # Phase 8 LOW-priority bootstrap-only categories (added in Phase 8)
    "stubs/filament-plugin/composer.json"
    "stubs/nova-tool/composer.json"
    "phases/bootstrap-filament-plugin.md"
    "phases/bootstrap-nova-tool.md"
    "references/branch-alias.md"
    "references/bin-scripts.md"

    # Meta docs
    "README.md"
    "CHANGELOG.md"
    "UPGRADING.md"
    "SECURITY.md"
    "CONTRIBUTING.md"
    "RELEASING.md"
    "LICENSE"
    "SPEC.md"
    "composer.json"
)

echo "[check-layout] verifying all ${#REQUIRED_PATHS[@]} required paths exist..."

for path in "${REQUIRED_PATHS[@]}"; do
    if [[ ! -e "$path" ]]; then
        echo "FAIL: required path missing: $path"
        EXIT_CODE=1
    fi
done

if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "[check-layout] OK — all required paths present per SPEC Resolved Questions."
fi

exit "$EXIT_CODE"
