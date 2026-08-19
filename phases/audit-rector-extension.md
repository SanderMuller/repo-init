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
- [ ] `rector/type-perfect: ^2.1` — **PHP 8.3 floor ONLY**. On a PHP >= 8.4 floor this package MUST be ABSENT (`tomasvotruba/type-coverage: ^2.3` bundles its rules); present there = NON-CANONICAL, see the duplicate-registration rule below. Abandoned upstream. See `$REPO_INIT_HOME/references/shared-dev-deps.md` "Type-perfect dep".
- [ ] `spaze/phpstan-disallowed-calls`
- [ ] `symplify/phpstan-rules: ^14.11` (PHP floor >= 8.4) — PHP 8.3 floor: `symplify/phpstan-extensions: ^12.0` satisfies this line instead (abandoned upstream; ADVISORY: bump PHP floor to drop it). A `phpstan-rules` constraint that can resolve below 14.11 does NOT count (no error formatter before 14.11); `phpstan-extensions` on a PHP >= 8.4 floor = NON-CANONICAL. See `$REPO_INIT_HOME/references/shared-dev-deps.md` "Symplify formatter dep".
- [ ] `tomasvotruba/cognitive-complexity`
- [ ] `tomasvotruba/type-coverage` — constraint is PHP-floor-conditional: `>=2.2.0 <2.2.2` on a PHP 8.3 floor (the `<2.2.2` cap is MANDATORY — 2.2.2 and 2.3.0 both require PHP ^8.4), `^2.3` on a PHP >= 8.4 floor (`^2.2` does NOT satisfy the line there — 2.2.2 registers no `type_perfect` params). See "Type-perfect dep".
- [ ] `nunomaduro/collision`
- [ ] `sandermuller/package-boost-php`
- [ ] `orchestra/testbench`
- [ ] `sandermuller/boost-skills` — canonical floor `^2.27.0`, the version that ships the voice guideline the always-on `voice` tag needs. A constraint that can resolve below 2.27.0 does NOT count: flag it NON-CANONICAL on its own, even when `'voice'` is already in `withTags([...])` (the tag is a silent no-op there). See the voice-tag finding below.
- [ ] `nikic/php-parser` (AST traversal in rule tests)

Test-framework split:

- pest: `pestphp/pest: ^5.0`, `pestphp/pest-plugin-arch: ^5.0`, `pestphp/pest-plugin-rector: ^5.0`, `pestphp/pest-plugin-phpstan: ^5.0`, `pestphp/pest-plugin-agent: ^5.0`. Pest 5 requires PHP `^8.4`, so a `pest` repo on a `^8.3` floor is NON-CANONICAL — see the Pest findings below. `mrpunyapal/rector-pest` present = NON-CANONICAL (replaced by `pestphp/pest-plugin-rector`).
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
- [ ] `post-install-cmd` → `["SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"]`
- [ ] `post-update-cmd` → `["SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"]`
- [ ] **Floor coupling (ATOMIC)**: if either hook above is MISSING or MISMATCH, the fix MUST also bump `sandermuller/package-boost-php` in `require-dev` to `^1.0` (repo-init's canonical floor) in the same change — the façade class ships from 0.16.0, so a pre-0.16 floor leaves the autosync hook referencing a non-autoloadable class that Composer skip-warns (`class_exists()` guard) and silently no-ops; `^1.0` keeps the scaffold on the current line. See the ATOMIC rule in this category's upgrade phase.

MISMATCH cases worth HIGH severity: POSIX-shell `post-install-cmd` (Windows-broken); `post-update-cmd` absent entirely.

## OUTDATED files (per merge mode)

For each file present, apply the merge mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md` — same logic as `audit-laravel-package.md`. `config/config.php` is `notify-only` once rules are registered (user owns it); `replace` mode applies only to the skeleton if the file is empty/missing.

## NON-CANONICAL findings

- [ ] **Pest below `^5.0`** (HIGH severity, applies only when the repo uses Pest): canonical Pest is `pestphp/pest: ^5.0` with every `pestphp/*` plugin on `^5.0`. Pest 5 requires PHP `^8.4` and PHPUnit 13, so the fix is ATOMIC — raise `require.php` to `^8.4`, raise `pestphp/*` to `^5.0`, and apply the PHP >= 8.4 dep set in the same pass (drop `rector/type-perfect`, `tomasvotruba/type-coverage: ^2.3`, `symplify/phpstan-rules: ^14.12`). Also drop the PHP 8.3 cells from `run-tests.yml`. See `$REPO_INIT_HOME/references/version-defaults.md` "Pest" and the matching `upgrade-<category>.md`.
- [ ] **`mrpunyapal/rector-pest` in `require-dev`** (MEDIUM severity): replaced by the first-party `pestphp/pest-plugin-rector: ^5.0`. Companion finding: `rector.php` importing `RectorPest\Set\PestSetList` or using `PestSetList::PEST_CODE_QUALITY` / `PEST_CHAIN` / `PEST_LARAVEL`. Canonical is `use Pest\Rector\Set\PestSetList;` with the single set `PestSetList::CODING_STYLE`.
- [ ] **`tests/Pest.php` without `pest()->tia()->locally()`** (LOW severity, applies only when the repo uses Pest): the Tia engine re-runs only the tests a change touched, on developer machines only. Fix = add the call to `tests/Pest.php`. Do NOT add `--tia` to any composer script or CI step. See `$REPO_INIT_HOME/references/pest-vs-phpunit.md` "Tia engine".
- [ ] **`stolt/lean-package-validator: ^6.0`** (LOW severity, applies only when the repo carries the validator AND uses Pest): 6.0.0 caps `sebastian/diff` at `^7` and cannot install next to PHPUnit 13. Composer backtracks to 6.0.1 on its own, `--prefer-lowest` included, so nothing breaks — but `^6.0.1` states the real floor. Fix = tighten the constraint.

- [ ] **`rector/type-perfect` present alongside a `tomasvotruba/type-coverage` constraint that can resolve to >= 2.3** (HIGH severity, PHPStan does not boot): `tomasvotruba/type-coverage` 2.3.0 absorbed type-perfect and now includes `packages/type-perfect/config/extension.neon` itself. With both installed, `phpstan/extension-installer` includes that file twice and PHPStan aborts at startup on the duplicate `MethodNodeAnalyser` service. Composer resolves against the **runtime** PHP, not `require.php` — so an uncapped `^2.2` (what every repo scaffolded before this rule landed carries) is green on the PHP 8.3 CI cell and dead on the 8.4 cell. Flag NON-CANONICAL: on a PHP 8.3 floor, cap the constraint to `>=2.2.0 <2.2.2`; on a PHP >= 8.4 floor, remove `rector/type-perfect` and move to `tomasvotruba/type-coverage: ^2.3`. The fix is ATOMIC — see the matching `upgrade-<category>.md`.

- [ ] **`minimum-stability` / `prefer-stable`** (LOW severity; MEDIUM if the package has downstream / production dependents): canonical `composer.json` declares `"minimum-stability": "stable"` and `"prefer-stable": true` (see `references/version-defaults.md`). Flag NON-CANONICAL if either key is absent, if `prefer-stable` is not `true`, or if `minimum-stability` is looser than `stable` (`dev` / `alpha` / `beta` / `RC`). **`stable` is the default expectation — recommend tightening to it.** A looser `minimum-stability` (typically `dev` + `prefer-stable: true`) is an allowed *but justified* exception, NOT a free pass: legitimate only when the package is actively co-developed against UNRELEASED sibling packages and the author deliberately opted in. Being on `0.x` is **not** by itself a justification — and a package with downstream / production dependents should lean `stable` (`prefer-stable` narrows but does not remove the risk of resolving unreleased code into a tagged release). Default recommendation: tighten to `stable` unless the author confirms an active co-development reason to keep `dev`. Fix via the matching `upgrade-<category>.md`; never loosen a passing `stable` baseline.
- [ ] **Legacy root `boost.php` (boost config not under `.config/`)** (MEDIUM severity, DRIFT): boost-core ≥ 0.17's canonical location is `.config/boost.php`. A root `boost.php` still works but is non-canonical. Flag NON-CANONICAL; suggest migration via `phases/upgrade-rector-extension.md` (MOVE the file — never copy).
- [ ] **BOTH `.config/boost.php` AND root `boost.php` present** (HIGH severity, URGENT): two configs is a hard error in boost-core ≥ 0.17 (`AmbiguousBoostConfigException`) — `vendor/bin/boost sync` / `install` / any config resolve will throw. Flag NON-CANONICAL; fix = remove the root `boost.php`, keep `.config/boost.php`.
- [ ] **Variadic `withTags(...)` / `withAgents(...)` in the boost config** (HIGH severity, DRIFT): boost-core 0.20 made every `BoostConfig` builder method take a single `array`. A pre-0.20 variadic call (`->withTags(Tag::Php, Tag::Github)`) throws when `boost.php` / `.config/boost.php` loads under boost-core ≥ 0.20 (`TypeError` on 0.20–0.22; catchable `InvalidBoostConfigException` on ≥ 0.23) — `composer install`/`update` autosync and every `boost` command fail. Flag NON-CANONICAL; fix = wrap the arguments in brackets (`->withTags([...])`). `boost sync` cannot auto-migrate it (loading the config runs the call first); `upgrade-<category>` does the hand-edit. Especially relevant when bumping the boost floor to the `1.x` line, which crosses 0.20.
- [ ] **`'voice'` missing from `withTags(...)` in the boost config** (MEDIUM severity, DRIFT): the canonical setup keeps the `voice` tag on in EVERY repo that carries `sandermuller/boost-skills` — the tag ships that package's writing-voice guideline (`resources/boost/guidelines/voice.md`, mapped to `voice` in its `resources/boost/guidelines/.boost-tags.yaml`). Without the tag the guideline never syncs into `AGENTS.md` / `CLAUDE.md`. It is structural, not a knob — see `$REPO_INIT_HOME/references/placeholder-rules.md` (`__SKILL_TAGS__`). Flag NON-CANONICAL; fix = add `'voice'` to the `withTags([...])` array and re-run `vendor/bin/boost sync`. **A config with NO `withTags(...)` call at all is the same finding** — `vendor/bin/boost install` removes the call when the operator selects no tags (`BoostConfigWriter`, empty-tags branch), so an absent call is drift, not an opt-out; fix = add `->withTags(['voice'])` to the chain. **Floor coupling:** the tag resolves to nothing unless the installed `sandermuller/boost-skills` ships the guideline — the same change MUST ensure the `require-dev` constraint is `^2.27.0` (repo-init's canonical floor).
- [ ] **`config.allow-plugins` lists `sandermuller/package-boost-php`** (MEDIUM severity, stale post package-boost-php 0.9.0): from `sandermuller/package-boost-php` 0.9.0, the package is `type: library` (dropped the Composer plugin; subcommands moved to `vendor/bin/package-boost-php`). The `sandermuller/package-boost-php: true` entry is a leftover from pre-0.9.0 scaffolds — Composer ignores it, harmless but stale. Flag NON-CANONICAL; suggest removal.
- [ ] **`config.allow-plugins` lists `sandermuller/boost-core`** (MEDIUM severity, stale post boost-core 0.6.0): boost-core is `type: library` from 0.6.0, no longer a composer-plugin. The `sandermuller/boost-core: true` entry is a leftover from pre-0.6.0 scaffolds — Composer ignores it, harmless but stale. Flag NON-CANONICAL; suggest removal.
- [ ] `rector/rector` in `require-dev` instead of `require` — should be in `require` for rector-extension. Flag.
- [ ] **POSIX-shell `post-install-cmd` / `post-update-cmd`** (HIGH severity): if either script's value is a shell conditional like `if [ "$COMPOSER_DEV_MODE" = "1" ]; then vendor/bin/boost sync; fi` (or older `vendor/bin/testbench package-boost:sync`), it is Windows-broken and predates boost-core 0.6's PHP callback. Canonical is the array `["SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"]` for BOTH keys. Flag NON-CANONICAL; suggest the merge-keys replace via `phases/upgrade-rector-extension.md`.
- [ ] `rector/rector` in BOTH `require` and `require-dev` — Composer rejects; should never happen.
- [ ] Missing `rector/extension-installer` in `config.allow-plugins` — auto-discovery breaks without it.
- [ ] `composer.lock` committed.
- [ ] PHP floor `^8.2` or below.
- [ ] `extra.rector.includes` points to a file that doesn't exist.
- [ ] **`phpunit.xml.dist` committed (with `.dist` suffix)**: canonical baseline as of repo-init 0.2.4 ships `phpunit.xml` (no `.dist`). Flag NON-CANONICAL.
- [ ] **PHPUnit cache rules** (if a `phpunit.xml` is present — Pest reuses PHPUnit's config, so these rules apply to Pest repos too; see `phpunit-config.md` Pest exception): apply `$REPO_INIT_HOME/references/phpunit-config.md` Audit-rule section — flag `.phpunit.cache/` at root, missing/wrong `cacheDirectory` attribute in `phpunit.xml`, committed `.phpunit.cache`.
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
