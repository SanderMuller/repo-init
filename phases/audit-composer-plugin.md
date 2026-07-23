# Audit: composer-plugin

Read-only check of an existing `composer-plugin` repo (framework-agnostic Composer plugin) against the canonical baseline.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`.

Verify detection per `$REPO_INIT_HOME/references/detection-rules.md`: target has `type: composer-plugin`. If `type:` is `library` or absent, this is `php-package` — re-route to `audit-php-package.md`.

## Opt-in confirmation

Detect sub-flags from the plugin's `src/`:

- **`command-provider`** — auto-`y` if the class named in `extra.class` implements `Composer\Plugin\Capable` AND `getCapabilities()` returns `CommandProvider::class`. Otherwise auto-`N`.
- **`event-subscriber`** — auto-`y` if the class named in `extra.class` implements `Composer\EventDispatcher\EventSubscriberInterface`. Otherwise auto-`N`.
- **`boost-skill-provider`** — auto-`y` if `resources/boost/skills/` dir exists. Otherwise auto-`N`.
- **`runtime-api`** — auto-`y` if `composer-runtime-api` is already in `require` OR source uses `Composer\InstalledVersions`. Otherwise auto-`N`.

Detect `test-framework` from existing deps (`pestphp/pest` vs `phpunit/phpunit`).

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
- [ ] 5 shared workflows (`phpstan.yml`, `pint-check.yml`, `rector-check.yml`, `zizmor.yml`, `update-changelog.yml`) + `run-tests.yml` (PHP-only matrix, no Laravel axis)
- [ ] `.github/zizmor.yml` (zizmor rule config — disables `unpinned-uses`, since every workflow here is tag-pinned by convention)
- [ ] `.github/dependabot.yml`

**Per-category exclusion**: `.mcp.json` from the shared stub set is SKIPPED for `composer-plugin`. The canonical `.mcp.json` ships a Laravel/testbench MCP server config (`vendor/bin/testbench boost:mcp`) which has no equivalent for framework-agnostic Composer plugins. Don't flag MISSING.

**Category-specific (composer-plugin):**

- [ ] `composer.json` with `type: composer-plugin`
- [ ] `composer.json` `extra.class` set to a FQCN
- [ ] `src/Plugin.php` (or whatever `extra.class` resolves to) — implements `Composer\Plugin\PluginInterface`

## MISSING runtime deps (must be in `require`)

- [ ] `composer-plugin-api: ^2.6` (the contract version the plugin targets). If absent, plugin won't be recognized as a composer plugin by Composer 2.6+. Flag MISSING.

If sub-flag `runtime-api` is `y`:

- [ ] `composer-runtime-api: ^2.2`

## MISSING dev deps (must be in `require-dev`)

**Follow `$REPO_INIT_HOME/references/shared-dev-deps.md#audit-verification-protocol-mandatory`.** Every bullet below gets an explicit PRESENT/MISSING verdict. Skimming is the failure mode.

Apply per-category exclusions for `composer-plugin`: DROP `orchestra/testbench` (plugins don't fit testbench). `composer-plugin` is a framework-agnostic Composer package, so it DOES get `sandermuller/package-boost-php` like the other agnostic categories (the pre-0.5.0 exclusion that dropped it was removed in repo-init 0.5.0).

From `$REPO_INIT_HOME/references/per-category-deps.md#composer-plugin` MANDATORY:

- [ ] `composer/composer: ^2.6` (for BaseCommand parent class, type hints, test fixtures — dev-only; never promote to `require`)

Plus shared (minus exclusions above):

- [ ] `laravel/pao`
- [ ] `laravel/pint`
- [ ] `phpstan/extension-installer`
- [ ] `phpstan/phpstan` (NEVER also `larastan/larastan` — composer-plugin is framework-agnostic)
- [ ] `phpstan/phpstan-strict-rules`
- [ ] `phpstan/phpstan-deprecation-rules`
- [ ] `phpstan/phpstan-phpunit`
- [ ] `rector/rector`
- [ ] `rector/type-perfect`
- [ ] `spaze/phpstan-disallowed-calls`
- [ ] `symplify/phpstan-rules: ^14.11` (PHP floor >= 8.4) — PHP 8.3 floor: `symplify/phpstan-extensions: ^12.0` satisfies this line instead (abandoned upstream; ADVISORY: bump PHP floor to drop it). A `phpstan-rules` constraint that can resolve below 14.11 does NOT count (no error formatter before 14.11); `phpstan-extensions` on a PHP >= 8.4 floor = NON-CANONICAL. See `$REPO_INIT_HOME/references/shared-dev-deps.md` "Symplify formatter dep".
- [ ] `tomasvotruba/cognitive-complexity`
- [ ] `tomasvotruba/type-coverage`
- [ ] `nunomaduro/collision`
- [ ] `sandermuller/package-boost-php`
- [ ] `sandermuller/boost-skills`
- [ ] `stolt/lean-package-validator`

Test-framework split:

- pest: `pestphp/pest`, `pestphp/pest-plugin-arch`, `mrpunyapal/rector-pest`. (NOT `pestphp/pest-plugin-laravel` — this is framework-agnostic.)
- phpunit: `phpunit/phpunit`.

## MISSING composer.json scripts

**Follow `$REPO_INIT_HOME/references/composer-scripts.md#audit-verification-protocol-mandatory`.** Every key below gets an explicit PRESENT / MISSING / MISMATCH verdict. Skimming is the failure mode — see the laravel-package upgrade incident (2026-05-25) where the agent shipped Windows-broken `post-install-cmd` and no `post-update-cmd` because it inferred the canonical block from training data.

Baseline minus `sync-ai` + composer-plugin additions (11 keys). The composer-plugin stub deliberately omits `sync-ai` — `post-install-cmd` / `post-update-cmd` already trigger boost sync via the PHP callback:

- [ ] `phpstan` → `vendor/bin/phpstan analyse --memory-limit=2G`
- [ ] `phpstan-simplified` → `vendor/bin/phpstan analyse --memory-limit=2G --error-format symplify`
- [ ] `phpstan-clear-cache` → `vendor/bin/phpstan clear-result-cache`
- [ ] `format` → `vendor/bin/pint`
- [ ] `rector` → `vendor/bin/rector process`
- [ ] `test` → `vendor/bin/pest` (or `vendor/bin/phpunit` if `test-framework=phpunit`)
- [ ] `test-coverage` → `vendor/bin/pest --coverage` (or `vendor/bin/phpunit --coverage-html=coverage`)
- [ ] `validate-gitattributes` → `vendor/bin/lean-package-validator validate`
- [ ] `qa` → `["@rector", "@format", "@phpstan-simplified", "@validate-gitattributes"]`
- [ ] `post-install-cmd` → `["SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"]`
- [ ] `post-update-cmd` → `["SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"]`
- [ ] **Floor coupling (ATOMIC)**: if either hook above is MISSING or MISMATCH, the fix MUST also bump `sandermuller/package-boost-php` in `require-dev` to `^1.0` (repo-init's canonical floor) in the same change — the façade class ships from 0.16.0, so a pre-0.16 floor leaves the autosync hook referencing a non-autoloadable class that Composer skip-warns (`class_exists()` guard) and silently no-ops; `^1.0` keeps the scaffold on the current line. See the ATOMIC rule in this category's upgrade phase.

MISMATCH cases worth HIGH severity: POSIX-shell `post-install-cmd` (Windows-broken; predates boost-core 0.6); `post-update-cmd` absent entirely.

## OUTDATED files (per merge mode)

Same logic as audit-php-package.md, with composer-plugin stub paths from `$REPO_INIT_HOME/stubs/composer-plugin/`. Apply each file's mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md`.

## NON-CANONICAL findings

- [ ] **`minimum-stability` / `prefer-stable`** (LOW severity; MEDIUM if the package has downstream / production dependents): canonical `composer.json` declares `"minimum-stability": "stable"` and `"prefer-stable": true` (see `references/version-defaults.md`). Flag NON-CANONICAL if either key is absent, if `prefer-stable` is not `true`, or if `minimum-stability` is looser than `stable` (`dev` / `alpha` / `beta` / `RC`). **`stable` is the default expectation — recommend tightening to it.** A looser `minimum-stability` (typically `dev` + `prefer-stable: true`) is an allowed *but justified* exception, NOT a free pass: legitimate only when the package is actively co-developed against UNRELEASED sibling packages and the author deliberately opted in. Being on `0.x` is **not** by itself a justification — and a package with downstream / production dependents should lean `stable` (`prefer-stable` narrows but does not remove the risk of resolving unreleased code into a tagged release). Default recommendation: tighten to `stable` unless the author confirms an active co-development reason to keep `dev`. Fix via the matching `upgrade-<category>.md`; never loosen a passing `stable` baseline.
- [ ] **Legacy root `boost.php` (boost config not under `.config/`)** (MEDIUM severity, DRIFT): boost-core ≥ 0.17's canonical location is `.config/boost.php`. A root `boost.php` still works but is non-canonical. Flag NON-CANONICAL; suggest migration via `phases/upgrade-composer-plugin.md` (MOVE the file — never copy).
- [ ] **BOTH `.config/boost.php` AND root `boost.php` present** (HIGH severity, URGENT): two configs is a hard error in boost-core ≥ 0.17 (`AmbiguousBoostConfigException`) — `vendor/bin/boost sync` / `install` / any config resolve will throw. Flag NON-CANONICAL; fix = remove the root `boost.php`, keep `.config/boost.php`.
- [ ] **Variadic `withTags(...)` / `withAgents(...)` in the boost config** (HIGH severity, DRIFT): boost-core 0.20 made every `BoostConfig` builder method take a single `array`. A pre-0.20 variadic call (`->withTags(Tag::Php, Tag::Github)`) throws when `boost.php` / `.config/boost.php` loads under boost-core ≥ 0.20 (`TypeError` on 0.20–0.22; catchable `InvalidBoostConfigException` on ≥ 0.23) — `composer install`/`update` autosync and every `boost` command fail. Flag NON-CANONICAL; fix = wrap the arguments in brackets (`->withTags([...])`). `boost sync` cannot auto-migrate it (loading the config runs the call first); `upgrade-<category>` does the hand-edit. Especially relevant when bumping the boost floor to the `1.x` line, which crosses 0.20.
- [ ] **`config.allow-plugins` lists `sandermuller/package-boost-php`** (MEDIUM severity, stale post package-boost-php 0.9.0): from `sandermuller/package-boost-php` 0.9.0, the package is `type: library` (dropped the Composer plugin; subcommands moved to `vendor/bin/package-boost-php`). The `sandermuller/package-boost-php: true` entry is a leftover from pre-0.9.0 scaffolds — Composer ignores it, harmless but stale. Flag NON-CANONICAL; suggest removal. (Distinct from the self-allow rule below, which still applies.)
- [ ] **`config.allow-plugins` lists `sandermuller/boost-core`** (MEDIUM severity, stale post boost-core 0.6.0): boost-core is `type: library` from 0.6.0, no longer a composer-plugin. The `sandermuller/boost-core: true` entry is a leftover from pre-0.6.0 scaffolds — Composer ignores it, harmless but stale. Flag NON-CANONICAL; suggest removal.
- [ ] `composer.lock` committed (libraries should not commit lockfiles).
- [ ] **`extra.class` missing** (HIGH severity): Composer rejects the plugin at install time with "no class found". Flag NON-CANONICAL.
- [ ] **`extra.class` points to a class that does NOT exist in autoload** (HIGH severity): grep PSR-4 mapping + verify file. If class missing or namespace mismatched, plugin won't load.
- [ ] **`extra.class` resolves to a class that does NOT implement `PluginInterface`** (HIGH severity): Composer rejects at activation.
- [ ] **`composer/composer` in `require` instead of `require-dev`** (HIGH severity): pulls Composer at runtime into consumers (~5 MB bloat + transitive). Flag NON-CANONICAL; move to require-dev.
- [ ] **Self-allow missing in `config.allow-plugins`** (MEDIUM severity): if the plugin has itself in `require-dev` for dogfooding (common pattern), or if any other composer-plugin is in deps, those entries MUST be in `config.allow-plugins`. Otherwise `composer install` here errors with "blocked by allow-plugins config". Flag missing entries.
- [ ] **`command-provider` shape declared but commands extend wrong parent** (HIGH severity, only when sub-flag `command-provider=y`): Composer's CommandProvider capability validates instances are `Composer\Command\BaseCommand`. If commands extend plain `Symfony\Component\Console\Command\Command`, plugin throws "invalid value, we expected an array of Composer\Command\BaseCommand objects" at install. Verify: `getCommands()` returns `Composer\Command\BaseCommand` instances.
- [ ] **`event-subscriber` shape declared but `getSubscribedEvents()` returns empty array** (LOW severity, only when sub-flag `event-subscriber=y`): plugin will load silently but hook nothing. Flag as suspicious — confirm intent.
- [ ] **PHPUnit cache rules** (if a `phpunit.xml` is present — Pest reuses PHPUnit's config, so these rules apply to Pest repos too; see `phpunit-config.md` Pest exception): apply `$REPO_INIT_HOME/references/phpunit-config.md` Audit-rule section — flag `.phpunit.cache/` at root, missing/wrong `cacheDirectory` attribute in `phpunit.xml`, committed `.phpunit.cache`.
- [ ] **CI path filter drift — `phpstan.yml`** (MEDIUM severity): grep `.github/workflows/phpstan.yml` `paths:` blocks under `push` and `pull_request`; both MUST include `composer.json` AND `composer.lock`. Flag NON-CANONICAL if either missing.
- [ ] **`.gitattributes` managed block missing `.ai/ export-ignore`** (MEDIUM severity): per `$REPO_INIT_HOME/references/gitattributes-managed-block.md`, `.ai/` is the boost SOURCE/authoring dir and MUST be in the managed block. Without it, `boost sync`-populated dev skills leak into the published Composer archive. Flag NON-CANONICAL.
- [ ] `larastan/larastan` in `require-dev` for a composer-plugin — Laravel-aware deps don't belong in a framework-agnostic plugin. Flag and ask: "does this plugin actually need Laravel runtime? Most composer plugins don't."
- [ ] `illuminate/*` in `require` — same. composer-plugin is framework-agnostic by definition; flag as misalignment.
- [ ] `orchestra/testbench` in `require-dev` — composer-plugin category excludes testbench (no Laravel runtime to bootstrap). Flag NON-CANONICAL; suggest removal.
- [ ] PHP floor `^8.2` (or below).
- [ ] **`phpunit.xml.dist` committed (with `.dist` suffix)**: canonical baseline ships `phpunit.xml` (no `.dist`). Flag NON-CANONICAL.
- [ ] Missing `validate-gitattributes` script in `composer.json` — composer-plugin should have it (same lean-archive reasoning as php-package).
- [ ] **POSIX-shell `post-install-cmd` / `post-update-cmd`** (HIGH severity): if either script's value is a shell conditional like `if [ "$COMPOSER_DEV_MODE" = "1" ]; then vendor/bin/boost sync; fi` (or older `vendor/bin/testbench package-boost:sync`), it is Windows-broken and predates boost-core 0.6's PHP callback. Canonical is the array `["SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"]` for BOTH keys. Flag NON-CANONICAL; suggest the merge-keys replace via `phases/upgrade-composer-plugin.md`.
- [ ] `.lpv` exists but no `vendor/bin/lean-package-validator validate` clean.
- [ ] **`.gitattributes` package-boost managed block MISSING** (HIGH severity): without it, `composer archive` ships local-only files. Flag NON-CANONICAL.
- [ ] **README badge row MISSING or incomplete** (HIGH severity): the first 30 lines of `README.md` MUST contain the canonical badge set — Packagist version, run-tests CI status, Total Downloads, License — each on its own line, all using `?style=flat-square` on shields.io URLs. Any missing → flag NON-CANONICAL with the specific badge(s) absent.

## EXTRA findings

Informational. Example: plugin ships its own `bin/<binary>` for standalone invocation (e.g. `sandermuller/boost-core` ships `bin/boost`) — legitimate when the plugin also offers a standalone CLI surface. Don't flag. If present alongside `command-provider=y`, note: the standalone bin and the plugin command path should share a CommandRegistry to avoid drift.

## Report

Same format as audit-php-package.md. Conversation-scoped.

## What's next

- Apply fixes: `phases/upgrade-composer-plugin.md`.
- Defer / done: stop.
