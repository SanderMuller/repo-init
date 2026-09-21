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
- [ ] 5 shared workflows (`phpstan.yml`, `pint-check.yml`, `rector-check.yml`, `zizmor.yml`, `update-changelog.yml`) + `run-tests.yml` (PHP-only matrix)
- [ ] `.github/zizmor.yml` (zizmor rule config — disables `unpinned-uses`, since every workflow here is tag-pinned by convention)
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
- [ ] `spaze/phpstan-disallowed-calls`
- [ ] `symplify/phpstan-rules: ^14.12` — a constraint that can resolve below 14.11 does NOT count (no error formatter before 14.11). `symplify/phpstan-extensions` anywhere = NON-CANONICAL, it is abandoned upstream and superseded. See `$REPO_INIT_HOME/references/shared-dev-deps.md` "Symplify formatter dep".
- [ ] `tomasvotruba/cognitive-complexity`
- [ ] `tomasvotruba/type-coverage: ^2.3` — `^2.2` does NOT satisfy the line (2.2.2 registers no `type_perfect` params). It bundles the abandoned `rector/type-perfect`, which must NOT be installed alongside it. See "Type-perfect dep".
- [ ] `nunomaduro/collision`
- [ ] `sandermuller/package-boost-php`
- [ ] `orchestra/testbench`
- [ ] `sandermuller/boost-skills` — canonical floor `^2.27.0`, the version that ships the voice guideline the always-on `voice` tag needs. A constraint that can resolve below 2.27.0 does NOT count: flag it NON-CANONICAL on its own, even when `'voice'` is already in `withTags([...])` (the tag is a silent no-op there). See the voice-tag finding below.

Test-framework split:

- pest: `pestphp/pest: ^5.0`, `pestphp/pest-plugin-arch: ^5.0`, `pestphp/pest-plugin-rector: ^5.0`, `pestphp/pest-plugin-phpstan: ^5.0`, `pestphp/pest-plugin-agent: ^5.0`. (NOT `pestphp/pest-plugin-laravel` — this is framework-agnostic.) Pest 5 requires PHP `^8.4`, so a `pest` repo on a `^8.3` floor is NON-CANONICAL — see the Pest findings below. `mrpunyapal/rector-pest` present = NON-CANONICAL (replaced by `pestphp/pest-plugin-rector`).
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

- [ ] **`orchestra/testbench: ^10.0||^11.0` on a Pest 5 repo** (HIGH severity, any category that carries testbench): Pest 5 needs `symfony/process: ^8.1` and testbench 10 pins `^7.2`, so `composer update` cannot resolve a testbench 10 cell. Fix = `orchestra/testbench: ^11.0` in `require-dev`; for a Laravel package category also keep Laravel 13 CI cells only. The runtime `illuminate/*` range stays as it is.
- [ ] **Pest below `^5.0`** (HIGH severity, applies only when the repo uses Pest): canonical Pest is `pestphp/pest: ^5.0` with every `pestphp/*` plugin on `^5.0`. Pest 5 requires PHP `^8.4` and PHPUnit 13, so the fix is ATOMIC — raise `require.php` to `^8.4`, raise `pestphp/*` to `^5.0`, and apply the canonical dep set in the same pass — REMOVE `rector/type-perfect`, and SET `tomasvotruba/type-coverage: ^2.3` and `symplify/phpstan-rules: ^14.12` (those two are the mandatory replacements, never dropped). Also drop every matrix cell below the repo's floor from `run-tests.yml`. See `$REPO_INIT_HOME/references/version-defaults.md` "Pest" and the matching `upgrade-<category>.md`.
- [ ] **`mrpunyapal/rector-pest` in `require-dev`** (MEDIUM severity): replaced by the first-party `pestphp/pest-plugin-rector: ^5.0`. Companion finding: `rector.php` importing `RectorPest\Set\PestSetList` or using `PestSetList::PEST_CODE_QUALITY` / `PEST_CHAIN` / `PEST_LARAVEL`. Canonical is `use Pest\Rector\Set\PestSetList;` with the single set `PestSetList::CODING_STYLE`.
- [ ] **`phpstan.neon.dist` registers no Symplify rule** (MEDIUM severity, DRIFT): `symplify/phpstan-rules` spreads its rules over opt-in config files, and its `extra.phpstan.includes` auto-loads only `services.neon`, `ctor-rules.neon`, `mock-rules.neon` and `phpstan-extensions.neon` (the error formatter). `phpstan/extension-installer` therefore registers NONE of the rules. Flag NON-CANONICAL when the `rules:` block is missing or short of the canonical list. Fix = add the block from `$REPO_INIT_HOME/references/phpstan-config.md` → "Symplify rules".
- [ ] **`type_coverage.constant` below 100** (LOW severity, DRIFT): the canonical `phpstan.neon.dist` runs every `type_coverage` dial at 100, constants included. Both reference apps do too. Flag NON-CANONICAL; fix = `constant: 100`, then baseline what the repo cannot reach yet.
- [ ] **`type_perfect` missing `narrow_param: true`** (LOW severity, DRIFT): the canonical block is `null_over_false`, `narrow_return` and `narrow_param`, all `true`. `no_mixed` stays absent on purpose — it rejects `mixed` a framework or PSR interface forces on an implementer. Flag NON-CANONICAL; fix = add the one line.
- [ ] **`phpstan.neon.dist` declares `phpVersion:`** (LOW severity, DRIFT): PHPStan 2 derives the analysed version range from `composer.json` `require.php` whenever `phpVersion` is null, so a declared value only adds a second source that can drift. Flag NON-CANONICAL; fix = delete the key and let `require.php` decide. See `$REPO_INIT_HOME/references/phpstan-config.md` → "PHP version".
- [ ] **`.cache` not excluded in the IDE project model** (LOW severity, ADVISORY, report only): PhpStorm indexes `.cache/` (the PHPStan and Rector cache) unless the module marks it excluded. repo-init NEVER writes under `.idea/` — see `$REPO_INIT_HOME/checklists/per-category-never-touch.md`. Report it and leave the fix to the user: right-click `.cache` → Mark Directory as → Excluded, which adds an `<excludeFolder>` to `.idea/<project>.iml`. Skip the check entirely when no `.idea/` directory exists.
- [ ] **`rector.php` in the legacy closure format** (HIGH severity, DRIFT): a config shaped `return static function (RectorConfig $rectorConfig): void { $rectorConfig->sets([...]); }`, or one calling `$rectorConfig->rule()` / `->ruleWithConfiguration()` / `->paths()` / `->skip()` / `->parallel()`. Canonical is the fluent `RectorConfig::configure()` builder. `rector.php` is `notify-only` (see `$REPO_INIT_HOME/references/upgrade-merge-modes.md`), so nothing rewrites it automatically — flag NON-CANONICAL and port it by hand against `$REPO_INIT_HOME/references/rector-config.md`, carrying every existing `skip` entry across.
- [ ] **`rector.php` calling `withPhp53Sets()` … `withPhp74Sets()`** (MEDIUM severity, DRIFT): Rector 2.6 marks every `withPhp5xSets()` / `withPhp7xSets()` method `@deprecated`. Each one now routes to `reportDeprecatedPhpSetsMethod()`, which only records the call name and adds NO rules — so the config keeps running and silently applies no PHP set. Flag NON-CANONICAL; fix = one `withPhpSets()` call naming the repo's `require.php` floor, for example `withPhpSets(php84: true)`.
- [ ] **`rector.php` passing `instanceOf:` / `if:` / `earlyReturn:` to `withPreparedSets()`** (MEDIUM severity, DRIFT): Rector 2.6 marks all three parameters `@deprecated` — the instanceof and early-return rules moved into `codeQuality`, and the `if` rules moved into `codeQuality` / `codingStyle` or were dropped. Flag NON-CANONICAL; fix = delete the three lines. `codeQuality: true` already covers them. See `$REPO_INIT_HOME/references/rector-config.md`.
- [ ] **`rector.php` missing a `withComposerBased(...)` flag the repo qualifies for** (MEDIUM severity, DRIFT): `withComposerBased()` is the only builder path that pushes `PHPUnitSetList::COMPOSER_BASED` / `LaravelSetList::COMPOSER_BASED` into the set list, and `withSetProviders()` is `@deprecated` in favour of it. Each flag is conditional: `phpunit: true` on a PHPUnit repo ONLY (its rules rewrite `TestCase` subclasses, which a Pest suite does not have), `laravel: true` on `laravel-project` ONLY. Flag NON-CANONICAL when a flag the repo qualifies for is absent, AND when a flag it does not qualify for is present. A repo that qualifies for neither omits the call — an argument-less `withComposerBased()` registers nothing. See `$REPO_INIT_HOME/references/rector-config.md`. Flag NON-CANONICAL; fix = add `->withComposerBased(phpunit: true)`.
- [ ] **`tests/Pest.php` without `pest()->tia()->locally()`** (LOW severity, applies only when the repo uses Pest): the Tia engine re-runs only the tests a change touched, on developer machines only. Fix = add the call to `tests/Pest.php`. Do NOT add `--tia` to any composer script or CI step. See `$REPO_INIT_HOME/references/pest-vs-phpunit.md` "Tia engine".
- [ ] **`stolt/lean-package-validator: ^6.0`** (LOW severity, applies only when the repo carries the validator AND uses Pest): 6.0.0 caps `sebastian/diff` at `^7` and cannot install next to PHPUnit 13. Composer backtracks to 6.0.1 on its own, `--prefer-lowest` included, so nothing breaks — but `^6.0.1` states the real floor. Fix = tighten the constraint.

- [ ] **`rector/type-perfect` present alongside a `tomasvotruba/type-coverage` constraint that can resolve to >= 2.3** (HIGH severity, PHPStan does not boot): `tomasvotruba/type-coverage` 2.3.0 absorbed type-perfect and now includes `packages/type-perfect/config/extension.neon` itself. With both installed, `phpstan/extension-installer` includes that file twice and PHPStan aborts at startup on the duplicate `MethodNodeAnalyser` service. Composer resolves against the **runtime** PHP, not `require.php` — so an uncapped `^2.2` (what every repo scaffolded before this rule landed carries) was green on a PHP 8.3 CI cell and is dead on 8.4. Flag NON-CANONICAL: remove `rector/type-perfect` and move to `tomasvotruba/type-coverage: ^2.3`. A repo below the `^8.4` floor cannot take that move — both successors need PHP `^8.4` — so the floor bump is part of the same atomic pass. The fix is ATOMIC — see the matching `upgrade-<category>.md`.

- [ ] **`minimum-stability` / `prefer-stable`** (LOW severity; MEDIUM if the package has downstream / production dependents): canonical `composer.json` declares `"minimum-stability": "stable"` and `"prefer-stable": true` (see `references/version-defaults.md`). Flag NON-CANONICAL if either key is absent, if `prefer-stable` is not `true`, or if `minimum-stability` is looser than `stable` (`dev` / `alpha` / `beta` / `RC`). **`stable` is the default expectation — recommend tightening to it.** A looser `minimum-stability` (typically `dev` + `prefer-stable: true`) is an allowed *but justified* exception, NOT a free pass: legitimate only when the package is actively co-developed against UNRELEASED sibling packages and the author deliberately opted in. Being on `0.x` is **not** by itself a justification — and a package with downstream / production dependents should lean `stable` (`prefer-stable` narrows but does not remove the risk of resolving unreleased code into a tagged release). Default recommendation: tighten to `stable` unless the author confirms an active co-development reason to keep `dev`. Fix via the matching `upgrade-<category>.md`; never loosen a passing `stable` baseline.
- [ ] **Legacy root `boost.php` (boost config not under `.config/`)** (MEDIUM severity, DRIFT): boost-core ≥ 0.17's canonical location is `.config/boost.php`. A root `boost.php` still works but is non-canonical. Flag NON-CANONICAL; suggest migration via `phases/upgrade-php-package.md` (MOVE the file — never copy).
- [ ] **BOTH `.config/boost.php` AND root `boost.php` present** (HIGH severity, URGENT): two configs is a hard error in boost-core ≥ 0.17 (`AmbiguousBoostConfigException`) — `vendor/bin/boost sync` / `install` / any config resolve will throw. Flag NON-CANONICAL; fix = remove the root `boost.php`, keep `.config/boost.php`.
- [ ] **Variadic `withTags(...)` / `withAgents(...)` in the boost config** (HIGH severity, DRIFT): boost-core 0.20 made every `BoostConfig` builder method take a single `array`. A pre-0.20 variadic call (`->withTags(Tag::Php, Tag::Github)`) throws when `boost.php` / `.config/boost.php` loads under boost-core ≥ 0.20 (`TypeError` on 0.20–0.22; catchable `InvalidBoostConfigException` on ≥ 0.23) — `composer install`/`update` autosync and every `boost` command fail. Flag NON-CANONICAL; fix = wrap the arguments in brackets (`->withTags([...])`). `boost sync` cannot auto-migrate it (loading the config runs the call first); `upgrade-<category>` does the hand-edit. Especially relevant when bumping the boost floor to the `1.x` line, which crosses 0.20.
- [ ] **`'voice'` missing from `withTags(...)` in the boost config** (MEDIUM severity, DRIFT): the canonical setup keeps the `voice` tag on in EVERY repo that carries `sandermuller/boost-skills` — the tag ships that package's writing-voice guideline (`resources/boost/guidelines/voice.md`, mapped to `voice` in its `resources/boost/guidelines/.boost-tags.yaml`). Without the tag the guideline never syncs into `AGENTS.md` / `CLAUDE.md`. It is structural, not a knob — see `$REPO_INIT_HOME/references/placeholder-rules.md` (`__SKILL_TAGS__`). Flag NON-CANONICAL; fix = add `'voice'` to the `withTags([...])` array and re-run `vendor/bin/boost sync`. **A config with NO `withTags(...)` call at all is the same finding** — `vendor/bin/boost install` removes the call when the operator selects no tags (`BoostConfigWriter`, empty-tags branch), so an absent call is drift, not an opt-out; fix = add `->withTags(['voice'])` to the chain. **Floor coupling:** the tag resolves to nothing unless the installed `sandermuller/boost-skills` ships the guideline — the same change MUST ensure the `require-dev` constraint is `^2.27.0` (repo-init's canonical floor).
- [ ] **`config.allow-plugins` lists `sandermuller/package-boost-php`** (MEDIUM severity, stale post package-boost-php 0.9.0): from `sandermuller/package-boost-php` 0.9.0, the package is `type: library` (dropped the Composer plugin; subcommands moved to `vendor/bin/package-boost-php`). The `sandermuller/package-boost-php: true` entry is a leftover from pre-0.9.0 scaffolds — Composer ignores it, harmless but stale. Flag NON-CANONICAL; suggest removal.
- [ ] **`config.allow-plugins` lists `sandermuller/boost-core`** (MEDIUM severity, stale post boost-core 0.6.0): boost-core is `type: library` from 0.6.0, no longer a composer-plugin. The `sandermuller/boost-core: true` entry is a leftover from pre-0.6.0 scaffolds — Composer ignores it, harmless but stale. Flag NON-CANONICAL; suggest removal.
- [ ] `composer.lock` committed (libraries should not commit lockfiles).
- [ ] **`phpunit.xml.dist` committed (with `.dist` suffix)**: canonical baseline as of repo-init 0.2.4 ships `phpunit.xml` (no `.dist`). Flag NON-CANONICAL.
- [ ] **PHPUnit cache rules** (if a `phpunit.xml` is present — Pest reuses PHPUnit's config, so these rules apply to Pest repos too; see `phpunit-config.md` Pest exception): apply `$REPO_INIT_HOME/references/phpunit-config.md` Audit-rule section — flag `.phpunit.cache/` at root, missing/wrong `cacheDirectory` attribute in `phpunit.xml`, committed `.phpunit.cache`.
- [ ] **CI path filter drift — `phpstan.yml`** (MEDIUM severity): grep `.github/workflows/phpstan.yml` `paths:` blocks under `push` and `pull_request`; both MUST include `composer.json` AND `composer.lock` (dep bumps can silently break static analysis without these). Flag NON-CANONICAL if either missing.
- [ ] **`.gitattributes` managed block missing `.ai/ export-ignore`** (MEDIUM severity): per `$REPO_INIT_HOME/references/gitattributes-managed-block.md`, `.ai/` is the boost SOURCE/authoring dir and MUST be in the managed block. Without it, `boost sync`-populated dev skills leak into the published Composer archive. Flag NON-CANONICAL.
- [ ] `larastan/larastan` in `require-dev` for a php-package — Laravel-aware deps in a framework-agnostic category. Flag and ask: "is this actually a `laravel-package`? Re-detect."
- [ ] `illuminate/*` in `require` — same. Re-route to `audit-laravel-package.md`.
- [ ] **PHP floor below the category floor in `require.php`** (`^8.4` for a package, `^8.5` for `laravel-project`): NON-CANONICAL. The bump is ATOMIC with dropping `rector/type-perfect` and `symplify/phpstan-extensions` — both successors need PHP `^8.4`. See `$REPO_INIT_HOME/references/version-defaults.md` "PHP".
- [ ] Missing `validate-gitattributes` script in `composer.json` — php-package should have it.
- [ ] **POSIX-shell `post-install-cmd` / `post-update-cmd`** (HIGH severity): if either script's value is a shell conditional like `if [ "$COMPOSER_DEV_MODE" = "1" ]; then vendor/bin/boost sync; fi` (or older `vendor/bin/testbench package-boost:sync`), it is Windows-broken and predates boost-core 0.6's PHP callback. Canonical is the array `["SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"]` for BOTH keys. Flag NON-CANONICAL; suggest the merge-keys replace via `phases/upgrade-php-package.md`.
- [ ] `.lpv` exists but no `vendor/bin/lean-package-validator validate` clean. Run the validator; if it warns, flag NON-CANONICAL with the specific missing export-ignore lines.
- [ ] **`.gitattributes` package-boost managed block MISSING** (HIGH severity): same as laravel-package — without it, `composer archive` ships local-only files. Flag NON-CANONICAL; suggest `vendor/bin/package-boost-php gitattributes` (boost-core's standalone bin family; maintains the `# >>> package-boost (managed) >>>` block, preserving foreign lines).
- [ ] **README badge row MISSING or incomplete** (HIGH severity): the first 30 lines of `README.md` MUST contain the canonical badge set — Packagist version, run-tests CI status, Total Downloads, License — each on its own line, all using `?style=flat-square` on shields.io URLs. Grep first 30 lines for `img.shields.io/packagist/v/`, `actions/workflow/status/.+/run-tests.yml`, `img.shields.io/packagist/dt/`, and `img.shields.io/packagist/l/`. Any missing → flag NON-CANONICAL with the specific badge(s) absent. Extra badges (PHPStan, Codecov, Laravel Compatibility, Sponsors, custom) are EXTRA-info only, never flagged. Rationale: badges are the at-a-glance trust signal for a Packagist library.

## EXTRA findings

Informational. Example: package ships its own `bin/<binary>` — totally legit for php-package (e.g. `php-x402` ships `bin/x402`). Don't flag.

## Report

Same format as audit-laravel-package.md. Conversation-scoped.

## What's next

- Apply fixes: `phases/upgrade-php-package.md`.
- Defer / done: stop.
