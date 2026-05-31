# Audit: phpstan-extension

Read-only check of an existing `phpstan-extension` package against the canonical baseline.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`.

Verify detection per `$REPO_INIT_HOME/references/detection-rules.md`: target has `type: phpstan-extension` OR `extra.phpstan.includes` set.

## Opt-in confirmation

- **Laravel-aware?** Default `y` if any `illuminate/*` already in `require`. If `y`: audit expects `larastan/larastan` in `require-dev` (replacing bare `phpstan/phpstan` per §5.3 exclusivity) and `illuminate/support` in `require`.

`test-framework` is forced to `phpunit` for phpstan-extension (canonical for rule testing — PHPStan's `RuleTestCase` is PHPUnit-based). If the target uses Pest, tolerate it but mention it in the report under "Notes" — don't push to migrate.

## MISSING files

**Shared:** same list as audit-laravel-package.md but using `phpunit.xml` (never `tests/Pest.php`), MINUS `.mcp.json` (the shared `.mcp.json` stub ships a Laravel/testbench MCP server config with no equivalent for framework-agnostic phpstan extensions; don't flag MISSING).

**Category-specific (phpstan-extension):**

- [ ] `composer.json` with `type: phpstan-extension` AND `extra.phpstan.includes: ["extension.neon"]`
- [ ] `extension.neon` at repo root — with `parametersSchema`, `parameters`, and `services` blocks (even if empty / commented). If file exists but blocks are missing, flag as OUTDATED rather than MISSING.
- [ ] `src/Rules/` directory exists (may contain `.gitkeep` if no rules yet)
- [ ] `tests/Rules/` directory exists
- [ ] `tests/Rules/stubs/` directory exists — must be declared in `composer.json` `autoload-dev.classmap` (`["tests/Rules/stubs/"]`)

## MISSING runtime deps (must be in `require`)

From `$REPO_INIT_HOME/references/per-category-deps.md#phpstan-extension` MANDATORY:

- [ ] `phpstan/phpstan: ^2` (in `require`, not `require-dev` — per §5.1.1 exclusion)

OPTIONAL (Laravel-aware):

- [ ] If opt-in confirmed: `illuminate/support: __LARAVEL_VERSIONS__` in `require`.

## MISSING dev deps (must be in `require-dev`)

**Follow `$REPO_INIT_HOME/references/shared-dev-deps.md#audit-verification-protocol-mandatory`.** Every bullet below gets an explicit PRESENT/MISSING verdict. Skimming is the failure mode.

Apply per-category exclusion: drop bare `phpstan/phpstan` from the shared list (it's in `require`).

From shared (`$REPO_INIT_HOME/references/shared-dev-deps.md`):

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
- [ ] `phpunit/phpunit` (test-framework=phpunit, the default for phpstan-extension)
- [ ] `nikic/php-parser` (rule tests + AST traversal)

OPTIONAL (Laravel-aware):

- [ ] `larastan/larastan` (REPLACES bare `phpstan/phpstan` — never both; the require-side `phpstan/phpstan: ^2` stays so the extension declares its own dep cleanly for consumers).

## MISSING composer.json scripts

**Follow `$REPO_INIT_HOME/references/composer-scripts.md#audit-verification-protocol-mandatory`.** Every key below gets an explicit PRESENT / MISSING / MISMATCH verdict. Skimming is the failure mode — see the laravel-package upgrade incident (2026-05-25) where the agent shipped Windows-broken `post-install-cmd` and no `post-update-cmd` because it inferred the canonical block from training data.

Baseline (11 keys):

- [ ] `phpstan` → `vendor/bin/phpstan analyse --memory-limit=2G`
- [ ] `phpstan-simplified` → `vendor/bin/phpstan analyse --memory-limit=2G --error-format symplify`
- [ ] `phpstan-clear-cache` → `vendor/bin/phpstan clear-result-cache`
- [ ] `format` → `vendor/bin/pint`
- [ ] `rector` → `vendor/bin/rector process`
- [ ] `test` → `vendor/bin/phpunit` (phpstan-extension forces phpunit)
- [ ] `test-coverage` → `vendor/bin/phpunit --coverage-html=coverage`
- [ ] `sync-ai` → `vendor/bin/boost sync`
- [ ] `qa` → `["@rector", "@format", "@phpstan-simplified"]`
- [ ] `post-install-cmd` → `["SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"]`
- [ ] `post-update-cmd` → `["SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"]`
- [ ] **Floor coupling (ATOMIC)**: if either hook above is MISSING or MISMATCH, the fix MUST also bump `sandermuller/package-boost-php` in `require-dev` to `^0.16.0` in the same change — the façade class first ships in 0.16.0, and a façade callback below that floor silently no-ops the autosync hook (Composer skip-warns via its `class_exists()` guard). See the ATOMIC rule in this category's upgrade phase.

MISMATCH cases worth HIGH severity: POSIX-shell `post-install-cmd` (Windows-broken); `post-update-cmd` absent entirely.

## OUTDATED files (per merge mode)

Same logic as audit-laravel-package.md — apply each file's mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md`. Plus:

- `extension.neon` is `replace` mode for the skeleton structure (the `parametersSchema`/`parameters`/`services` block headers) but `notify-only` for the actual rule registrations inside. Bootstrap writes the skeleton; user fills it in.

## NON-CANONICAL findings

- [ ] **`config.allow-plugins` lists `sandermuller/package-boost-php`** (MEDIUM severity, stale post package-boost-php 0.9.0): from `sandermuller/package-boost-php` 0.9.0, the package is `type: library` (dropped the Composer plugin; subcommands moved to `vendor/bin/package-boost-php`). The `sandermuller/package-boost-php: true` entry is a leftover from pre-0.9.0 scaffolds — Composer ignores it, harmless but stale. Flag NON-CANONICAL; suggest removal.
- [ ] **`config.allow-plugins` lists `sandermuller/boost-core`** (MEDIUM severity, stale post boost-core 0.6.0): boost-core is `type: library` from 0.6.0, no longer a composer-plugin. The `sandermuller/boost-core: true` entry is a leftover from pre-0.6.0 scaffolds — Composer ignores it, harmless but stale. Flag NON-CANONICAL; suggest removal.
- [ ] `phpstan/phpstan` in BOTH `require` and `require-dev` (Composer rejects; should never happen but check). Flag — remove from `require-dev`.
- [ ] **POSIX-shell `post-install-cmd` / `post-update-cmd`** (HIGH severity): if either script's value is a shell conditional like `if [ "$COMPOSER_DEV_MODE" = "1" ]; then vendor/bin/boost sync; fi` (or older `vendor/bin/testbench package-boost:sync`), it is Windows-broken and predates boost-core 0.6's PHP callback. Canonical is the array `["SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"]` for BOTH keys. Flag NON-CANONICAL; suggest the merge-keys replace via `phases/upgrade-phpstan-extension.md`.
- [ ] `larastan/larastan` in `require-dev` BUT no `illuminate/*` in `require` — Laravel-aware claim without the actual Laravel runtime dep. Ask user: do you mean to be Laravel-aware? If yes, add `illuminate/support` to `require`.
- [ ] Test-framework is Pest for a phpstan-extension — tolerate but mention in Notes.
- [ ] `composer.lock` committed.
- [ ] `tests/Rules/stubs/` exists but NOT declared in `autoload-dev.classmap`. Phpstan extension test fixtures need classmap loading. Flag.
- [ ] PHP floor `^8.2` or below.
- [ ] **`phpunit.xml.dist` committed (with `.dist` suffix)**: canonical baseline as of repo-init 0.2.4 ships `phpunit.xml` (no `.dist`). Flag NON-CANONICAL.
- [ ] **PHPUnit cache rules** (phpstan-extension always uses phpunit): apply `$REPO_INIT_HOME/references/phpunit-config.md` Audit-rule section — flag `.phpunit.cache/` at root, missing/wrong `cacheDirectory` attribute in `phpunit.xml`, committed `.phpunit.cache`.
- [ ] **CI path filter drift — `phpstan.yml`** (MEDIUM severity): grep `.github/workflows/phpstan.yml` `paths:` blocks under `push` and `pull_request`; both MUST include `composer.json` AND `composer.lock`. Flag NON-CANONICAL if either missing.
- [ ] **`.gitattributes` managed block missing `.ai/ export-ignore`** (MEDIUM severity): per `$REPO_INIT_HOME/references/gitattributes-managed-block.md`, `.ai/` is the boost SOURCE/authoring dir and MUST be in the managed block. Without it, `boost sync`-populated dev skills leak into the published Composer archive. Flag NON-CANONICAL.
- [ ] **`.gitattributes` package-boost managed block MISSING** (HIGH severity): see audit-laravel-package.md for rationale + fix.
- [ ] **README badge row MISSING or incomplete** (HIGH severity): the first 30 lines of `README.md` MUST contain the canonical badge set — Packagist version, run-tests CI status, Total Downloads, License — each on its own line, all using `?style=flat-square` on shields.io URLs. Grep first 30 lines for `img.shields.io/packagist/v/`, `actions/workflow/status/.+/run-tests.yml`, `img.shields.io/packagist/dt/`, and `img.shields.io/packagist/l/`. Any missing → flag NON-CANONICAL with the specific badge(s) absent. Extra badges (PHPStan, Codecov, Laravel Compatibility, Sponsors, custom) are EXTRA-info only, never flagged. Rationale: badges are the at-a-glance trust signal for a Packagist library.
- [ ] **README missing PHPStan workflow badge** (LOW severity): for `phpstan-extension` / `rector-extension` flavours, the canonical row SHOULD also include a `phpstan.yml` workflow badge alongside `run-tests.yml`. Flag NON-CANONICAL (informational).

## EXTRA findings

Informational. Often: the extension ships extra `.neon` config files beyond `extension.neon` — totally legit, don't flag.

## Report

Same format as audit-laravel-package.md.

## What's next

- Apply fixes: `phases/upgrade-phpstan-extension.md`.
- Defer / done: stop.
