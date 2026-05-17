# Audit: php-package

Read-only check of an existing `php-package` repo (framework-agnostic library) against the canonical baseline.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`.

Verify detection per `$REPO_INIT_HOME/references/detection-rules.md`: target has `type: library` (or missing) AND no `illuminate/*` / `socialiteproviders/manager` / `spatie/laravel-package-tools` in `require` AND no `extra.laravel.providers`. If any Laravel signal is present, this is actually `laravel-package` — re-route to `audit-laravel-package.md`.

## Opt-in confirmation

None for `php-package`. The category has no Laravel-aware sub-flag. Detect `test-framework` from existing deps (`pestphp/pest` vs `phpunit/phpunit`).

## MISSING files

**Shared:**

- [ ] `.editorconfig`
- [ ] `.gitattributes` (with package-boost managed block)
- [ ] `.gitignore`
- [ ] `.mcp.json`
- [ ] `pint.json`
- [ ] `phpstan.neon.dist`
- [ ] `phpstan-baseline.neon`
- [ ] `rector.php`
- [ ] `phpunit.xml.dist` (if test-framework=phpunit) OR `tests/Pest.php` (if pest)
- [ ] 4 shared workflows + `run-tests.yml` (PHP-only matrix)
- [ ] `.github/dependabot.yml`

**Category-specific (php-package):**

- [ ] `composer.json` with `type: library`
- [ ] `.lpv` — lean-package-validator config
- [ ] `PUBLIC_API.md` — semver-protected surface doc
- [ ] `src/<PackageStudly>.php` — at least one public class file (or any file under `src/` if user has scaffolded their own)

## MISSING runtime deps (must be in `require`)

php-package has no mandatory runtime deps from repo-init's side. The user owns their `require` block. Skip flagging.

## MISSING dev deps (must be in `require-dev`)

Apply per-category exclusion: php-package category does NOT include `larastan/larastan` (it's framework-agnostic). Bare `phpstan/phpstan` instead.

From `$REPO_INIT_HOME/references/per-category-deps.md#php-package` MANDATORY:

- [ ] `phpstan/phpstan` (NEVER also `larastan/larastan` per §5.3 exclusivity)
- [ ] `stolt/lean-package-validator`

Plus shared:

- [ ] `laravel/pao`
- [ ] `laravel/pint`
- [ ] `phpstan/extension-installer`
- [ ] `phpstan/phpstan-strict-rules`
- [ ] `phpstan/phpstan-deprecation-rules`
- [ ] `phpstan/phpstan-phpunit`
- [ ] `rector/rector`
- [ ] `rector/type-perfect`
- [ ] `spaze/phpstan-disallowed-calls`
- [ ] `symplify/phpstan-extensions`
- [ ] `tomasvotruba/cognitive-complexity`
- [ ] `tomasvotruba/type-coverage`
- [ ] `nunomaduro/collision`
- [ ] `sandermuller/package-boost`
- [ ] `orchestra/testbench`

Test-framework split:

- pest: `pestphp/pest`, `pestphp/pest-plugin-arch`, `mrpunyapal/rector-pest`. (NOT `pestphp/pest-plugin-laravel` — this is framework-agnostic.)
- phpunit: `phpunit/phpunit`.

## OUTDATED files (per merge mode)

Same logic as audit-laravel-package.md, with php-package stub paths.

## NON-CANONICAL findings

- [ ] `composer.lock` committed (libraries should not commit lockfiles).
- [ ] `phpunit.xml` without `.dist`.
- [ ] `larastan/larastan` in `require-dev` for a php-package — Laravel-aware deps in a framework-agnostic category. Flag and ask: "is this actually a `laravel-package`? Re-detect."
- [ ] `illuminate/*` in `require` — same. Re-route to `audit-laravel-package.md`.
- [ ] PHP floor `^8.2` (or below).
- [ ] Missing `validate-gitattributes` script in `composer.json` — php-package should have it.
- [ ] `.lpv` exists but no `vendor/bin/lean-package-validator validate` clean. Run the validator; if it warns, flag NON-CANONICAL with the specific missing export-ignore lines.

## EXTRA findings

Informational. Example: package ships its own `bin/<binary>` — totally legit for php-package (e.g. `php-x402` ships `bin/x402`). Don't flag.

## Report

Same format as audit-laravel-package.md. Conversation-scoped.

## What's next

- Apply fixes: `phases/upgrade-php-package.md`.
- Defer / done: stop.
