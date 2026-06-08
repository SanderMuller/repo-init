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
- [ ] `.config/boost.php` (boost-core agent config — pins claude-code / copilot / codex; canonical location, boost-core ≥ 0.17). A legacy root `boost.php` does NOT satisfy this — see NON-CANONICAL findings (it is flagged as drift to migrate).
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

## MISSING composer.json scripts

**Follow `$REPO_INIT_HOME/references/composer-scripts.md#audit-verification-protocol-mandatory`.** Every key below gets an explicit PRESENT / MISSING / MISMATCH verdict. Skimming is the failure mode — see the laravel-package upgrade incident (2026-05-25) where the agent shipped Windows-broken `post-install-cmd` and no `post-update-cmd` because it inferred the canonical block from training data.

Baseline + php-package additions (12 keys):

- [ ] `phpstan` → `vendor/bin/phpstan analyse --memory-limit=2G`
- [ ] `phpstan-simplified` → `vendor/bin/phpstan analyse --memory-limit=2G --error-format symplify`
- [ ] `phpstan-clear-cache` → `vendor/bin/phpstan clear-result-cache`
- [ ] `format` → `vendor/bin/pint`
- [ ] `rector` → `vendor/bin/rector process`
- [ ] `test` → `vendor/bin/pest` (or `vendor/bin/phpunit` if `test-framework=phpunit`)
- [ ] `test-coverage` → `vendor/bin/pest --coverage` (or `vendor/bin/phpunit --coverage-html=coverage`)
- [ ] `sync-ai` → `vendor/bin/boost sync`
- [ ] `validate-gitattributes` → `vendor/bin/lean-package-validator validate`
- [ ] `qa` → `["@rector", "@format", "@phpstan-simplified", "@validate-gitattributes"]` (php-package appends `@validate-gitattributes`)
- [ ] `post-install-cmd` → `["SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"]`
- [ ] `post-update-cmd` → `["SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"]`
- [ ] **Floor coupling (ATOMIC)**: if either hook above is MISSING or MISMATCH, the fix MUST also bump `sandermuller/package-boost-php` in `require-dev` to `^1.0` (repo-init's canonical floor) in the same change — the façade class ships from 0.16.0, so a pre-0.16 floor leaves the autosync hook referencing a non-autoloadable class that Composer skip-warns (`class_exists()` guard) and silently no-ops; `^1.0` keeps the scaffold on the current line. See the ATOMIC rule in this category's upgrade phase.

MISMATCH cases worth HIGH severity:

- `post-install-cmd` is a POSIX-shell conditional referencing `vendor/bin/boost sync` (or older `vendor/bin/testbench package-boost:sync`). Windows-broken; predates boost-core 0.6.
- `post-update-cmd` absent entirely — common companion to the above.

## OUTDATED files (per merge mode)

Same logic as audit-laravel-package.md, with php-package stub paths. Apply each file's mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md`.

## NON-CANONICAL findings

- [ ] **`minimum-stability` / `prefer-stable`** (LOW severity; MEDIUM if the package has downstream / production dependents): canonical `composer.json` declares `"minimum-stability": "stable"` and `"prefer-stable": true` (see `references/version-defaults.md`). Flag NON-CANONICAL if either key is absent, if `prefer-stable` is not `true`, or if `minimum-stability` is looser than `stable` (`dev` / `alpha` / `beta` / `RC`). **`stable` is the default expectation — recommend tightening to it.** A looser `minimum-stability` (typically `dev` + `prefer-stable: true`) is an allowed *but justified* exception, NOT a free pass: legitimate only when the package is actively co-developed against UNRELEASED sibling packages and the author deliberately opted in. Being on `0.x` is **not** by itself a justification — and a package with downstream / production dependents should lean `stable` (`prefer-stable` narrows but does not remove the risk of resolving unreleased code into a tagged release). Default recommendation: tighten to `stable` unless the author confirms an active co-development reason to keep `dev`. Fix via the matching `upgrade-<category>.md`; never loosen a passing `stable` baseline.
- [ ] **Legacy root `boost.php` (boost config not under `.config/`)** (MEDIUM severity, DRIFT): boost-core ≥ 0.17's canonical location is `.config/boost.php`. A root `boost.php` still works but is non-canonical. Flag NON-CANONICAL; suggest migration via `phases/upgrade-php-package.md` (MOVE the file — never copy).
- [ ] **BOTH `.config/boost.php` AND root `boost.php` present** (HIGH severity, URGENT): two configs is a hard error in boost-core ≥ 0.17 (`AmbiguousBoostConfigException`) — `vendor/bin/boost sync` / `install` / any config resolve will throw. Flag NON-CANONICAL; fix = remove the root `boost.php`, keep `.config/boost.php`.
- [ ] **Variadic `withTags(...)` / `withAgents(...)` in the boost config** (HIGH severity, DRIFT): boost-core 0.20 made every `BoostConfig` builder method take a single `array`. A pre-0.20 variadic call (`->withTags(Tag::Php, Tag::Github)`) throws when `boost.php` / `.config/boost.php` loads under boost-core ≥ 0.20 (`TypeError` on 0.20–0.22; catchable `InvalidBoostConfigException` on ≥ 0.23) — `composer install`/`update` autosync and every `boost` command fail. Flag NON-CANONICAL; fix = wrap the arguments in brackets (`->withTags([...])`). `boost sync` cannot auto-migrate it (loading the config runs the call first); `upgrade-<category>` does the hand-edit. Especially relevant when bumping the boost floor to the `1.x` line, which crosses 0.20.
- [ ] **`config.allow-plugins` lists `sandermuller/package-boost-php`** (MEDIUM severity, stale post package-boost-php 0.9.0): from `sandermuller/package-boost-php` 0.9.0, the package is `type: library` (dropped the Composer plugin; subcommands moved to `vendor/bin/package-boost-php`). The `sandermuller/package-boost-php: true` entry is a leftover from pre-0.9.0 scaffolds — Composer ignores it, harmless but stale. Flag NON-CANONICAL; suggest removal.
- [ ] **`config.allow-plugins` lists `sandermuller/boost-core`** (MEDIUM severity, stale post boost-core 0.6.0): boost-core is `type: library` from 0.6.0, no longer a composer-plugin. The `sandermuller/boost-core: true` entry is a leftover from pre-0.6.0 scaffolds — Composer ignores it, harmless but stale. Flag NON-CANONICAL; suggest removal.
- [ ] `composer.lock` committed (libraries should not commit lockfiles).
- [ ] **`phpunit.xml.dist` committed (with `.dist` suffix)**: canonical baseline as of repo-init 0.2.4 ships `phpunit.xml` (no `.dist`). Flag NON-CANONICAL.
- [ ] **PHPUnit cache rules** (if a `phpunit.xml` is present — Pest reuses PHPUnit's config, so these rules apply to Pest repos too; see `phpunit-config.md` Pest exception): apply `$REPO_INIT_HOME/references/phpunit-config.md` Audit-rule section — flag `.phpunit.cache/` at root, missing/wrong `cacheDirectory` attribute in `phpunit.xml`, committed `.phpunit.cache`.
- [ ] **CI path filter drift — `phpstan.yml`** (MEDIUM severity): grep `.github/workflows/phpstan.yml` `paths:` blocks under `push` and `pull_request`; both MUST include `composer.json` AND `composer.lock` (dep bumps can silently break static analysis without these). Flag NON-CANONICAL if either missing.
- [ ] **`.gitattributes` managed block missing `.ai/ export-ignore`** (MEDIUM severity): per `$REPO_INIT_HOME/references/gitattributes-managed-block.md`, `.ai/` is the boost SOURCE/authoring dir and MUST be in the managed block. Without it, `boost sync`-populated dev skills leak into the published Composer archive. Flag NON-CANONICAL.
- [ ] `larastan/larastan` in `require-dev` for a php-package — Laravel-aware deps in a framework-agnostic category. Flag and ask: "is this actually a `laravel-package`? Re-detect."
- [ ] `illuminate/*` in `require` — same. Re-route to `audit-laravel-package.md`.
- [ ] PHP floor `^8.2` (or below).
- [ ] Missing `validate-gitattributes` script in `composer.json` — php-package should have it.
- [ ] **POSIX-shell `post-install-cmd` / `post-update-cmd`** (HIGH severity): if either script's value is a shell conditional like `if [ "$COMPOSER_DEV_MODE" = "1" ]; then vendor/bin/boost sync; fi` (or older `vendor/bin/testbench package-boost:sync`), it is Windows-broken and predates boost-core 0.6's PHP callback. Canonical is the array `["SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"]` for BOTH keys. Flag NON-CANONICAL; suggest the merge-keys replace via `phases/upgrade-php-package.md`.
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
