# Audit: skill-bundle

Read-only check of an existing `skill-bundle` repo (a distributable package whose product is AI agent skills) against the canonical baseline. Conversation-scoped — no state file written to the target.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`.

Verify detection per `$REPO_INIT_HOME/references/detection-rules.md`: target has `type: library`, `sandermuller/boost-core` in `require` (runtime), ships `resources/boost/skills/`, and has no `src/` PHP source. If `sandermuller/boost-core` is in `require-dev` (not `require`) and the package ships `src/`, this is a `php-package` — re-route to `audit-php-package.md`.

## Opt-in confirmation

None for `skill-bundle`. The category has no sub-flags.

## MISSING files

**Shared:**

- [ ] `.editorconfig`
- [ ] `.gitattributes` (with the `# >>> package-boost (managed) >>>` block)
- [ ] `.gitignore`
- [ ] `pint.json`
- [ ] `.github/workflows/pint-check.yml`
- [ ] `.github/workflows/update-changelog.yml`
- [ ] `.github/dependabot.yml`

**Per-category exclusion**: `phpstan.neon.dist`, `phpstan-baseline.neon`, `rector.php`, `.mcp.json`, `run-tests.yml`, `phpstan.yml`, `rector-check.yml` are SKIPPED for `skill-bundle` — it ships no `src/` PHP, so there is nothing for PHPStan / Rector / the testbench MCP server to act on. Don't flag MISSING.

**Category-specific (skill-bundle):**

- [ ] `composer.json` with `type: library` and `sandermuller/boost-core` in `require`
- [ ] `.lpv` — lean-package-validator config
- [ ] `resources/boost/skills/` directory with at least one `<skill-name>/SKILL.md`

## MISSING runtime deps (must be in `require`)

From `$REPO_INIT_HOME/references/per-category-deps.md#skill-bundle` MANDATORY:

- [ ] `sandermuller/boost-core` — in `require` (runtime, NOT `require-dev`). A skill-bundle's consumers need boost-core present to discover and sync the shipped skills; `require-dev` is not transitive.

## MISSING dev deps (must be in `require-dev`)

**Follow `$REPO_INIT_HOME/references/shared-dev-deps.md#audit-verification-protocol-mandatory`.** Every bullet gets an explicit PRESENT/MISSING verdict.

From `$REPO_INIT_HOME/references/per-category-deps.md#skill-bundle` MANDATORY `require-dev`:

- [ ] `laravel/pint`
- [ ] `stolt/lean-package-validator`

A skill-bundle ships no PHP source — it carries no test runner (no `pestphp/pest` / `phpunit/phpunit`) and the shared dev-dep list (PHPStan / Rector packs) does not apply. Only the two above are mandatory.

## OUTDATED files (per merge mode)

For each file present, apply its merge mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md` — same logic as `audit-php-package.md`, with `skill-bundle` / `shared` stub paths.

## NON-CANONICAL findings

- [ ] **`config.allow-plugins` missing `sandermuller/boost-core`** (HIGH severity): `boost-core` is in `require` and is a `composer-plugin`. `config.allow-plugins` MUST list `sandermuller/boost-core: true`. Missing it → the first non-interactive `composer install` fails with "blocked by your allow-plugins config". Flag NON-CANONICAL.
- [ ] **`sandermuller/boost-core` in `require-dev` instead of `require`** (HIGH severity): `require-dev` is not transitive — consumers of the skill-bundle would not receive boost-core and could not sync the shipped skills. Flag; move to `require`.
- [ ] **`pestphp/pest` / `phpunit/phpunit` in `require-dev`** (LOW severity): a skill-bundle ships no PHP source — a test runner has nothing to run. Note it; suggest removal unless the bundle ships a genuine helper test suite (then it's EXTRA, not flagged).
- [ ] **Outdated `post-install-cmd`** (MEDIUM severity): if `composer.json` `scripts.post-install-cmd` is a POSIX-shell conditional (`if [ "$COMPOSER_DEV_MODE" = "1" ]; then ...`) it is Windows-broken. Canonical is the boost-core callback `SanderMuller\BoostCore\Scripts\BoostAutoSync::runWithSummary` for both `post-install-cmd` and `post-update-cmd`. Flag if missing or stale.
- [ ] `composer.lock` committed (libraries should not commit lockfiles).
- [ ] `src/` directory with PHP source — a skill-bundle ships no PHP. Flag and ask: "is this actually a `php-package`? Re-detect."
- [ ] PHP floor `^8.2` (or below) in `require.php` — repo-init floors at `^8.3`.
- [ ] **`.gitattributes` package-boost managed block MISSING** (HIGH severity): without it, `composer archive` ships local-only files into the published tarball.
- [ ] Missing `validate-gitattributes` script in `composer.json`.
- [ ] **README badge row MISSING or incomplete** (MEDIUM severity): the first 30 lines of `README.md` SHOULD carry the universal badges — Packagist version, Total Downloads, License — each on its own line, shields.io with `?style=flat-square`. A skill-bundle ships **no `run-tests.yml`** (it has no test suite), so a run-tests CI-status badge is NOT required — do not flag its absence; a `pint-check.yml` workflow badge is optional EXTRA. Flag only the three universal badges when absent.

## EXTRA findings

Informational only. A skill-bundle that also ships a small helper `bin/` or a `tests/` arch suite is fine — don't flag.

## Report

Same format as `audit-php-package.md`. Conversation-scoped.

## What's next

- Apply fixes: `$REPO_INIT_HOME/phases/upgrade-skill-bundle.md`.
- Defer / done: stop.
