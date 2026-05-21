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
- [ ] `boost.php` (boost-core agent config — pins claude-code / copilot / codex)
- [ ] `pint.json`
- [ ] `phpstan.neon.dist`
- [ ] `phpstan-baseline.neon`
- [ ] `rector.php`
- [ ] `phpunit.xml` (if test-framework=phpunit) OR `tests/Pest.php` (if pest)
- [ ] 4 shared workflows + `run-tests.yml` (PHP-only matrix)
- [ ] `.github/dependabot.yml`

**Per-category exclusion**: `.mcp.json` from the shared stub set is SKIPPED for `php-package`. The canonical `.mcp.json` ships a Laravel/testbench MCP server config (`vendor/bin/testbench boost:mcp`) which has no equivalent for framework-agnostic php-package code. Don't flag MISSING.

**Category-specific (php-package):**

- [ ] `composer.json` with `type: library`
- [ ] `.lpv` — lean-package-validator config
- [ ] `PUBLIC_API.md` — semver-protected surface doc
- [ ] `src/<PackageStudly>.php` — at least one public class file (or any file under `src/` if user has scaffolded their own)

## MISSING runtime deps (must be in `require`)

php-package has no mandatory runtime deps from repo-init's side. The user owns their `require` block. Skip flagging.

## MISSING dev deps (must be in `require-dev`)

**Follow `$REPO_INIT_HOME/references/shared-dev-deps.md#audit-verification-protocol-mandatory`.** Every bullet below gets an explicit PRESENT/MISSING verdict. Skimming is the failure mode (real audits have missed `laravel/pao`).

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
- [ ] `sandermuller/package-boost-php`
- [ ] `orchestra/testbench`
- [ ] `sandermuller/boost-skills`

Test-framework split:

- pest: `pestphp/pest`, `pestphp/pest-plugin-arch`, `mrpunyapal/rector-pest`. (NOT `pestphp/pest-plugin-laravel` — this is framework-agnostic.)
- phpunit: `phpunit/phpunit`.

## OUTDATED files (per merge mode)

Same logic as audit-laravel-package.md, with php-package stub paths. Apply each file's mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md`.

## NON-CANONICAL findings

- [ ] **`config.allow-plugins` missing the boost plugins** (HIGH severity): `sandermuller/package-boost-php` transitively pulls `sandermuller/boost-core` — a `composer-plugin`. `config.allow-plugins` MUST list BOTH `sandermuller/boost-core` and `sandermuller/package-boost-php` (both are `type: composer-plugin`). Missing either → the first non-interactive `composer install` fails with "blocked by your allow-plugins config". Flag NON-CANONICAL.
- [ ] `composer.lock` committed (libraries should not commit lockfiles).
- [ ] **`phpunit.xml.dist` committed (with `.dist` suffix)**: canonical baseline as of repo-init 0.2.4 ships `phpunit.xml` (no `.dist`). Flag NON-CANONICAL.
- [ ] **PHPUnit cache rules** (if `test-framework=phpunit`): apply `$REPO_INIT_HOME/references/phpunit-config.md` Audit-rule section — flag `.phpunit.cache/` at root, missing/wrong `cacheDirectory` attribute in `phpunit.xml`, committed `.phpunit.cache`.
- [ ] **CI path filter drift — `phpstan.yml`** (MEDIUM severity): grep `.github/workflows/phpstan.yml` `paths:` blocks under `push` and `pull_request`; both MUST include `composer.json` AND `composer.lock` (dep bumps can silently break static analysis without these). Flag NON-CANONICAL if either missing.
- [ ] **`.gitattributes` managed block missing `.ai/ export-ignore`** (MEDIUM severity): per `$REPO_INIT_HOME/references/gitattributes-managed-block.md`, `.ai/` is the boost SOURCE/authoring dir and MUST be in the managed block. Without it, `boost sync`-populated dev skills leak into the published Composer archive. Flag NON-CANONICAL.
- [ ] `larastan/larastan` in `require-dev` for a php-package — Laravel-aware deps in a framework-agnostic category. Flag and ask: "is this actually a `laravel-package`? Re-detect."
- [ ] `illuminate/*` in `require` — same. Re-route to `audit-laravel-package.md`.
- [ ] PHP floor `^8.2` (or below).
- [ ] Missing `validate-gitattributes` script in `composer.json` — php-package should have it.
- [ ] `.lpv` exists but no `vendor/bin/lean-package-validator validate` clean. Run the validator; if it warns, flag NON-CANONICAL with the specific missing export-ignore lines.
- [ ] **`.gitattributes` package-boost managed block MISSING** (HIGH severity): same as laravel-package — without it, `composer archive` ships local-only files. Flag NON-CANONICAL; suggest `vendor/bin/testbench package-boost:sync` (requires `orchestra/testbench` to be in require-dev, which `shared/always` mandates).
- [ ] **README badge row MISSING or incomplete** (HIGH severity): the first 30 lines of `README.md` MUST contain the canonical badge set — Packagist version, run-tests CI status, Total Downloads, License — each on its own line, all using `?style=flat-square` on shields.io URLs. Grep first 30 lines for `img.shields.io/packagist/v/`, `actions/workflow/status/.+/run-tests.yml`, `img.shields.io/packagist/dt/`, and `img.shields.io/packagist/l/`. Any missing → flag NON-CANONICAL with the specific badge(s) absent. Extra badges (PHPStan, Codecov, Laravel Compatibility, Sponsors, custom) are EXTRA-info only, never flagged. Rationale: badges are the at-a-glance trust signal for a Packagist library.

## EXTRA findings

Informational. Example: package ships its own `bin/<binary>` — totally legit for php-package (e.g. `php-x402` ships `bin/x402`). Don't flag.

## Report

Same format as audit-laravel-package.md. Conversation-scoped.

## What's next

- Apply fixes: `phases/upgrade-php-package.md`.
- Defer / done: stop.
