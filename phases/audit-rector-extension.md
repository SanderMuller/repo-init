# Audit: rector-extension

Read-only check of an existing `rector-extension` package against the canonical baseline.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`.

Verify detection per `$REPO_INIT_HOME/references/detection-rules.md`: target has `type: rector-extension` OR `extra.rector.includes` set.

## Opt-in confirmation

- **Laravel-aware (`--with-laravel-sets`)?** Default `y` if `driftingly/rector-laravel` already in `require` OR `require-dev`. If `y`: audit expects `driftingly/rector-laravel` in `require` (not `require-dev`).
- `test-framework` — detect from existing deps (`pestphp/pest` vs `phpunit/phpunit`). No default forcing for rector-extension.

## MISSING files

**Shared:** same list as audit-laravel-package.md, MINUS `.mcp.json` (the shared `.mcp.json` stub ships a Laravel/testbench MCP server config with no equivalent for framework-agnostic rector extensions; don't flag MISSING).

**Category-specific (rector-extension):**

- [ ] `composer.json` with `type: rector-extension` AND `extra.rector.includes: ["config/config.php"]` AND `config.allow-plugins.rector/extension-installer: true`
- [ ] `config/config.php` — Rector service registration file (even if rules array is empty)
- [ ] `src/Rector/` directory exists
- [ ] `tests/Rector/` directory exists

## MISSING runtime deps (must be in `require`)

From `$REPO_INIT_HOME/references/per-category-deps.md#rector-extension` MANDATORY:

- [ ] `rector/rector: ^2` (in `require`, not `require-dev` — per §5.1.1 exclusion)
- [ ] `symplify/rule-doc-generator-contracts`

OPTIONAL (Laravel-aware):

- [ ] If opt-in: `driftingly/rector-laravel` in `require`.

## MISSING dev deps (must be in `require-dev`)

**Follow `$REPO_INIT_HOME/references/shared-dev-deps.md#audit-verification-protocol-mandatory`.** Every bullet below gets an explicit PRESENT/MISSING verdict. Skimming is the failure mode.

Apply per-category exclusion: drop `rector/rector` from the shared list (it's in `require`).

From shared:

- [ ] `laravel/pao`
- [ ] `laravel/pint`
- [ ] `phpstan/extension-installer`
- [ ] `phpstan/phpstan` (rector-extension is framework-agnostic by default — uses bare phpstan, not larastan)
- [ ] `phpstan/phpstan-strict-rules`
- [ ] `phpstan/phpstan-deprecation-rules`
- [ ] `phpstan/phpstan-phpunit`
- [ ] `rector/type-perfect`
- [ ] `spaze/phpstan-disallowed-calls`
- [ ] `symplify/phpstan-extensions`
- [ ] `tomasvotruba/cognitive-complexity`
- [ ] `tomasvotruba/type-coverage`
- [ ] `nunomaduro/collision`
- [ ] `sandermuller/package-boost-php`
- [ ] `orchestra/testbench`
- [ ] `sandermuller/boost-skills`
- [ ] `nikic/php-parser` (AST traversal in rule tests)

Test-framework split:

- pest: `pestphp/pest`, `pestphp/pest-plugin-arch`, `mrpunyapal/rector-pest`.
- phpunit: `phpunit/phpunit`.

## MISSING composer.json scripts

**Follow `$REPO_INIT_HOME/references/composer-scripts.md#audit-verification-protocol-mandatory`.** Every key below gets an explicit PRESENT / MISSING / MISMATCH verdict. Skimming is the failure mode — see the laravel-package upgrade incident (2026-05-25) where the agent shipped Windows-broken `post-install-cmd` and no `post-update-cmd` because it inferred the canonical block from training data.

Baseline (11 keys):

- [ ] `phpstan` → `vendor/bin/phpstan analyse --memory-limit=2G`
- [ ] `phpstan-simplified` → `vendor/bin/phpstan analyse --memory-limit=2G --error-format symplify`
- [ ] `phpstan-clear-cache` → `vendor/bin/phpstan clear-result-cache`
- [ ] `format` → `vendor/bin/pint`
- [ ] `rector` → `vendor/bin/rector process`
- [ ] `test` → `vendor/bin/pest` (or `vendor/bin/phpunit` if `test-framework=phpunit`)
- [ ] `test-coverage` → `vendor/bin/pest --coverage` (or `vendor/bin/phpunit --coverage-html=coverage`)
- [ ] `sync-ai` → `vendor/bin/boost sync`
- [ ] `qa` → `["@rector", "@format", "@phpstan-simplified", "@test"]` (rector-extension appends `@test` — full QA runs the rule tests)
- [ ] `post-install-cmd` → `["SanderMuller\\BoostCore\\Scripts\\BoostAutoSync::run"]`
- [ ] `post-update-cmd` → `["SanderMuller\\BoostCore\\Scripts\\BoostAutoSync::run"]`

MISMATCH cases worth HIGH severity: POSIX-shell `post-install-cmd` (Windows-broken); `post-update-cmd` absent entirely.

## OUTDATED files (per merge mode)

For each file present, apply the merge mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md` — same logic as `audit-laravel-package.md`. `config/config.php` is `notify-only` once rules are registered (user owns it); `replace` mode applies only to the skeleton if the file is empty/missing.

## NON-CANONICAL findings

- [ ] **`config.allow-plugins` missing `sandermuller/package-boost-php`** (HIGH severity): `sandermuller/package-boost-php` is `type: composer-plugin` — `config.allow-plugins` MUST list `sandermuller/package-boost-php: true` or the first non-interactive `composer install` fails with "blocked by your allow-plugins config". Flag NON-CANONICAL.
- [ ] **`config.allow-plugins` lists `sandermuller/boost-core`** (MEDIUM severity, stale post boost-core 0.6.0): boost-core is `type: library` from 0.6.0, no longer a composer-plugin. The `sandermuller/boost-core: true` entry is a leftover from pre-0.6.0 scaffolds — Composer ignores it, harmless but stale. Flag NON-CANONICAL; suggest removal.
- [ ] `rector/rector` in `require-dev` instead of `require` — should be in `require` for rector-extension. Flag.
- [ ] **POSIX-shell `post-install-cmd` / `post-update-cmd`** (HIGH severity): if either script's value is a shell conditional like `if [ "$COMPOSER_DEV_MODE" = "1" ]; then vendor/bin/boost sync; fi` (or older `vendor/bin/testbench package-boost:sync`), it is Windows-broken and predates boost-core 0.6's PHP callback. Canonical is the array `["SanderMuller\\BoostCore\\Scripts\\BoostAutoSync::run"]` for BOTH keys. Flag NON-CANONICAL; suggest the merge-keys replace via `phases/upgrade-rector-extension.md`.
- [ ] `rector/rector` in BOTH `require` and `require-dev` — Composer rejects; should never happen.
- [ ] Missing `rector/extension-installer` in `config.allow-plugins` — auto-discovery breaks without it.
- [ ] `composer.lock` committed.
- [ ] PHP floor `^8.2` or below.
- [ ] `extra.rector.includes` points to a file that doesn't exist.
- [ ] **`phpunit.xml.dist` committed (with `.dist` suffix)**: canonical baseline as of repo-init 0.2.4 ships `phpunit.xml` (no `.dist`). Flag NON-CANONICAL.
- [ ] **PHPUnit cache rules** (if `test-framework=phpunit`): apply `$REPO_INIT_HOME/references/phpunit-config.md` Audit-rule section — flag `.phpunit.cache/` at root, missing/wrong `cacheDirectory` attribute in `phpunit.xml`, committed `.phpunit.cache`.
- [ ] **CI path filter drift — `phpstan.yml`** (MEDIUM severity): grep `.github/workflows/phpstan.yml` `paths:` blocks under `push` and `pull_request`; both MUST include `composer.json` AND `composer.lock`. Flag NON-CANONICAL if either missing.
- [ ] **`.gitattributes` managed block missing `.ai/ export-ignore`** (MEDIUM severity): per `$REPO_INIT_HOME/references/gitattributes-managed-block.md`, `.ai/` is the boost SOURCE/authoring dir and MUST be in the managed block. Without it, `boost sync`-populated dev skills leak into the published Composer archive. Flag NON-CANONICAL.
- [ ] **`.gitattributes` package-boost managed block MISSING** (HIGH severity): see audit-laravel-package.md for rationale + fix.
- [ ] **README badge row MISSING or incomplete** (HIGH severity): the first 30 lines of `README.md` MUST contain the canonical badge set — Packagist version, run-tests CI status, Total Downloads, License — each on its own line, all using `?style=flat-square` on shields.io URLs. Grep first 30 lines for `img.shields.io/packagist/v/`, `actions/workflow/status/.+/run-tests.yml`, `img.shields.io/packagist/dt/`, and `img.shields.io/packagist/l/`. Any missing → flag NON-CANONICAL with the specific badge(s) absent. Extra badges (PHPStan, Codecov, Laravel Compatibility, Sponsors, custom) are EXTRA-info only, never flagged. Rationale: badges are the at-a-glance trust signal for a Packagist library.
- [ ] **README missing PHPStan workflow badge** (LOW severity): for `phpstan-extension` / `rector-extension` flavours, the canonical row SHOULD also include a `phpstan.yml` workflow badge alongside `run-tests.yml`. Flag NON-CANONICAL (informational).

## EXTRA findings

Informational. Often: the extension ships rule-doc generators, custom set lists — legit, don't flag.

## Report

Same format as audit-laravel-package.md.

## What's next

- Apply fixes: `phases/upgrade-rector-extension.md`.
- Defer / done: stop.
