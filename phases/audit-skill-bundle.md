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
- [ ] `.config/boost.php` (boost-core agent config — pins claude-code / copilot / codex; canonical location, boost-core ≥ 0.17). A legacy root `boost.php` does NOT satisfy this — see NON-CANONICAL findings (it is flagged as drift to migrate).
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
- [ ] `sandermuller/boost-skills`
- [ ] `stolt/lean-package-validator`

A skill-bundle ships no PHP source — it carries no test runner (no `pestphp/pest` / `phpunit/phpunit`) and the shared dev-dep list (PHPStan / Rector packs) does not apply. Only the two above are mandatory.

## MISSING composer.json scripts

**Read `$REPO_INIT_HOME/references/composer-scripts.md` and follow its audit verification protocol** — one explicit PRESENT / MISSING / MISMATCH verdict per key. `skill-bundle` takes the lean **6-key** set (NOT the baseline 11 — it ships no PHP toolchain), per `references/composer-scripts.md#skill-bundle`:

- [ ] `format` → `vendor/bin/pint`
- [ ] `validate-gitattributes` → `vendor/bin/lean-package-validator validate`
- [ ] `qa` → `["@format", "@validate-gitattributes"]`
- [ ] `qa-check` → `["vendor/bin/pint --test", "@validate-gitattributes"]`
- [ ] `post-install-cmd` → `["SanderMuller\\BoostCore\\Scripts\\BoostAutoSync::run"]`
- [ ] `post-update-cmd` → `["SanderMuller\\BoostCore\\Scripts\\BoostAutoSync::run"]`

skill-bundle keeps the **direct boost-core** callback `BoostCore\Scripts\BoostAutoSync::run` (NOT a wrapper façade) — it depends on `sandermuller/boost-core` directly, so that callback is a direct-dep class. This is the correct post-1.4.0 canonical for skill-bundle; do NOT flag it as a stale `BoostAutoSync` reference. MISMATCH cases (POSIX-shell, `::runWithSummary`, or a wrapper façade) are detailed in NON-CANONICAL findings below.

## OUTDATED files (per merge mode)

For each file present, apply its merge mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md` — same logic as `audit-php-package.md`, with `skill-bundle` / `shared` stub paths.

## NON-CANONICAL findings

- [ ] **`minimum-stability` / `prefer-stable` deviation** (LOW severity): canonical `composer.json` declares `"minimum-stability": "stable"` and `"prefer-stable": true` (see `references/version-defaults.md`). Flag NON-CANONICAL if either key is absent, if `prefer-stable` is not `true`, or if `minimum-stability` is looser than `stable` (`dev` / `alpha` / `beta` / `RC`). **Exception:** an early-stage v0.x package MAY intentionally set `minimum-stability: dev` WITH `prefer-stable: true` — confirm intent before flagging; that documented combination is not drift. Fix: add/normalise both keys via the matching `upgrade-<category>.md` (don't loosen a passing `stable` baseline).
- [ ] **Legacy root `boost.php` (boost config not under `.config/`)** (MEDIUM severity, DRIFT): boost-core ≥ 0.17's canonical location is `.config/boost.php`. A root `boost.php` still works but is non-canonical. Flag NON-CANONICAL; suggest migration via `phases/upgrade-skill-bundle.md` (MOVE the file — never copy).
- [ ] **BOTH `.config/boost.php` AND root `boost.php` present** (HIGH severity, URGENT): two configs is a hard error in boost-core ≥ 0.17 (`AmbiguousBoostConfigException`) — `vendor/bin/boost sync` / `install` / any config resolve will throw. Flag NON-CANONICAL; fix = remove the root `boost.php`, keep `.config/boost.php`.
- [ ] **`config.allow-plugins` lists `sandermuller/boost-core`** (MEDIUM severity, stale post boost-core 0.6.0): from boost-core 0.6.0, `sandermuller/boost-core` is `type: library`, no longer a composer-plugin. The `sandermuller/boost-core: true` allow-plugins entry is a leftover from pre-0.6.0 scaffolds — Composer ignores it, harmless but stale. Flag NON-CANONICAL; suggest removal. (For `skill-bundle`, `config.allow-plugins` is typically empty post-0.6.0 — the category ships no other composer-plugin dev deps.)
- [ ] **`sandermuller/boost-core` in `require-dev` instead of `require`** (HIGH severity): `require-dev` is not transitive — consumers of the skill-bundle would not receive boost-core and could not sync the shipped skills. Flag; move to `require`.
- [ ] **`pestphp/pest` / `phpunit/phpunit` in `require-dev`** (LOW severity): a skill-bundle ships no PHP source — a test runner has nothing to run. Note it; suggest removal unless the bundle ships a genuine helper test suite (then it's EXTRA, not flagged).
- [ ] **Outdated `post-install-cmd`** (MEDIUM severity): if `composer.json` `scripts.post-install-cmd` is a POSIX-shell conditional (`if [ "$COMPOSER_DEV_MODE" = "1" ]; then ...`) it is Windows-broken. Canonical is the boost-core callback `SanderMuller\BoostCore\Scripts\BoostAutoSync::run` for both `post-install-cmd` and `post-update-cmd` (auto-firing hooks → silent-by-default `run()`; from boost-core 0.6.0, `run()` prints the one-line sync summary only when `wrote>0`). Flag if missing, stale (POSIX-shell), or still wired to `::runWithSummary` (which is for user-invoked scripts only).
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
