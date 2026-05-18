# Changelog

All notable changes to `sandermuller/repo-init` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Pre-`1.0.0` releases may introduce breaking changes in MINOR bumps; we surface those here clearly.

## [Unreleased]

### Removed

- **Dropped Laravel 11 support from default constraints** (BREAKING for new
  bootstraps of Laravel-aware categories — existing repos untouched).
  Root cause: `laravel/pao 1.0.5+` declares `conflict: laravel/framework <12.0.0`,
  which broke the `prefer-lowest` CI matrix leg with `laravel: '11.*'`. Caught
  by package-boost-laravel peer on first push of a downstream Laravel package.
  Changes:
  - 4 Laravel-aware run-tests.yml stubs: `prefer-lowest` matrix leg moved from
    `{ laravel: '11.*', testbench: '9.*' }` to `{ laravel: '12.*', testbench: '10.*' }`.
  - 7 stub composer.json + repo-init own composer.json:
    `orchestra/testbench: ^9.0||^10.0||^11.0` → `^10.0||^11.0`.
  - Default `illuminate/*` constraint: `^11.0||^12.0||^13.0` → `^12.0||^13.0`.
    Updated in `references/{version-defaults,per-category-deps,canonical-repos}.md`,
    `phases/{bootstrap-laravel-package,bootstrap-filament-plugin,bootstrap-nova-tool,audit-laravel-package}.md`,
    and `resources/boost/skills/repo-init/SKILL.md`.
  - `references/version-defaults.md` PHPUnit floor: `^11.0||^12.0` → `^12.0` (matches Laravel 12's shipped phpunit).
  - Existing Laravel 11 repos audited by repo-init are NOT flagged — audit
    doesn't second-guess the range (per per-category-deps.md). Only NEW
    bootstraps get the bumped default.

### Fixed

- **`.gitattributes` managed block stubs missing `.ai/ export-ignore`** (codex
  review surface via package-boost-laravel peer): added `.ai/ export-ignore`
  to `stubs/{shared,laravel-package,laravel-package-spatie,filament-plugin,nova-tool}/_gitattributes`
  inside the `# >>> package-boost (managed) >>>` block, right after
  `.agents/ export-ignore` (alphabetical). Without this, `boost sync`-populated
  dev skills under `.ai/` leak into the published Composer archive
  (per `references/gitattributes-managed-block.md` line 11, the reference
  already documented `.ai/` as part of the canonical block — stubs had drifted).
  Matching audit rule added across all 5 audit phases; upgrade fix added
  to all 5 upgrade phases (insert `.ai/ export-ignore` after `.agents/` line).
- **CI workflow stub path-filter gaps** (codex review surface):
  - `stubs/shared/.github/workflows/phpstan.yml`: added `composer.json` +
    `composer.lock` to `push.paths` and `pull_request.paths`. Dep bumps
    (PHPStan extension updates, framework version changes, autoloaded files)
    no longer slip past static analysis without triggering a run.
  - `stubs/{laravel-package,laravel-package-spatie,filament-plugin,nova-tool}/.github/workflows/run-tests.yml`:
    added `testbench.yaml` + `workbench/**` to both path blocks. A typo in
    testbench.yaml can no longer merge silently without a test run.
    `laravel-project` left as-is (apps don't ship testbench.yaml/workbench).

### Added

- **`composer-plugin` is now a first-class category** (6 total). Previously
  flagged out-of-scope per `references/detection-rules.md` with a "run
  audit-php-package.md manually" workaround. Now ships:
  - Decision-table row in `references/detection-rules.md`: `type: composer-plugin` → `composer-plugin`.
  - Sub-flags: `command-provider` (plugin implements `Capable` + `CommandProvider`),
    `event-subscriber` (`EventSubscriberInterface`), `boost-skill-provider`
    (`resources/boost/skills/` present), `runtime-api`
    (`composer-runtime-api` in require).
  - `stubs/composer-plugin/`: composer.json (type: composer-plugin,
    composer-plugin-api ^2.6 in require, composer/composer ^2.6 in
    require-dev, extra.class, self-allow in config.allow-plugins) + four
    `src/Plugin.{none,command-provider,event-subscriber,both}.php`
    variants resolved per `plugin-shape` knob + `src/CommandProvider.php`
    (copied only for command-provider/both shapes). Deterministic file
    selection (no post-copy patching). Coordinated with `sandermuller/repo-new`'s
    wizard implementation.
  - `phases/bootstrap-composer-plugin.md`: greenfield wizard with
    `plugin-shape` knob (command-provider / event-subscriber / both / none).
  - `phases/audit-composer-plugin.md`: read-only category audit. Flags
    missing `composer-plugin-api`, missing `extra.class`, `extra.class`
    pointing at nonexistent class, `composer/composer` in `require`
    instead of `require-dev`, command-provider commands extending wrong
    parent (Symfony Command instead of Composer BaseCommand — the
    BaseCommandAdapter pattern from `sandermuller/boost-core` is cited
    as reference), self-allow missing from `config.allow-plugins`.
  - `phases/upgrade-composer-plugin.md`: matching fixes.
  - `references/per-category-deps.{md,yml}`: composer-plugin section with
    shared-exclusions (drops `orchestra/testbench` and
    `sandermuller/package-boost`).
  - `resources/boost/skills/repo-init/SKILL.md`: 5→6 category table +
    composer-plugin sub-flag notes.
  - `references/detection-rules.md`: removed `composer-plugin` from
    "Out-of-scope `type:` values".
- **Audit verification protocol** for the MISSING dev-deps check.
  `references/shared-dev-deps.md` gains a MANDATORY protocol section
  requiring every bullet to get an explicit PRESENT/MISSING verdict
  (not a skim). Real audits had missed `laravel/pao` because the agent
  read the structure and assumed compliance. Each `## MISSING dev deps`
  section in all 6 audit phases now cites the protocol upfront.
- **CI path-filter audit/upgrade rule** across audit/upgrade phases.
  Audit flags `phpstan.yml` missing `composer.json`/`composer.lock` in path
  filters (all 5 categories). Audit also flags `run-tests.yml` missing
  `testbench.yaml`/`workbench/**` (laravel-package only — covers the
  spatie/filament/nova fall-through too). Upgrade fixes insert the missing
  lines under matching indentation.
- **PHPUnit cache audit/upgrade rule** across all 5 categories (`php-package`,
  `laravel-package`, `laravel-project`, `phpstan-extension`, `rector-extension`).
  New `references/phpunit-config.md` defines the canonical `phpunit.xml`
  cache shape: `cacheDirectory=".cache/phpunit"` (so all tool caches live
  under `.cache/`, single `.gitignore` entry). Audit flags `.phpunit.cache/`
  at repo root, missing/wrong `cacheDirectory` attribute, and committed
  `.phpunit.cache`. Upgrade fixes `cacheDirectory`, removes the leaked dir,
  and `git rm -r --cached` if previously committed.

### Changed

- **Bumped `sandermuller/package-boost-php` from `^0.2.0` to `^0.3.0`**
  in repo-init's own composer.json + all 7 stub composer.jsons. Pulls
  `sandermuller/boost-core: ^0.3.1` transitively, which ships
  `SanderMuller\BoostCore\Scripts\BoostAutoSync::run` — the Composer
  script callback that replaces shell-out invocations in
  `post-install-cmd` / `post-update-cmd`. Verified end-to-end:
  `composer update` clean, script callback runs without error,
  boost-core 0.3.1 + package-boost-php 0.3.0 both installed.
- **Stubs migrated from `sandermuller/package-boost: ^0.15` to
  `sandermuller/package-boost-php: ^0.3.0`** (rolled up the prior
  `^0.2.0` migration into the same bump). All 7 stub composer.json files
  (`php-package`, `laravel-package`, `laravel-package-spatie`, `filament-plugin`,
  `nova-tool`, `rector-extension`, `phpstan-extension`) plus `references/shared-dev-deps.md`,
  `references/per-category-deps.yml`, and all 6 audit + 4 upgrade phase bullets
  renamed. `package-boost` (no -php suffix) was the testbench-based predecessor;
  `package-boost-php` is the new umbrella that depends on boost-core and ships
  the standalone `vendor/bin/boost` binary. **Without this**, scaffolded
  targets would NOT have boost-core in their tree, and downstream tooling
  (e.g. `sandermuller/repo-new`'s wizard) couldn't swap from
  `vendor/bin/testbench package-boost:sync` to `vendor/bin/boost sync` —
  the new bin didn't exist in fresh scaffolds. Caught by repo-new peer
  during composer-plugin integration coordination. Bug was present in
  repo-init 0.2.0+ stubs; only repo-init's own composer.json got the
  migration earlier this session.
- **Stubs composer scripts swap `vendor/bin/testbench package-boost:sync` →
  `vendor/bin/boost sync`** for both `post-install-cmd` and `sync-ai`
  entries across all 7 stub composer.json files. Other testbench commands
  (`testbench package:purge-skeleton`, `package:discover`, `serve`,
  `workbench:build`) are unchanged — those are legit testbench-runtime
  invocations, not AI sync.
- **Switched from direct `sandermuller/boost-core` require to transitive via
  `sandermuller/package-boost-php: ^0.2.0`.** boost-core 0.2.0 ships
  global-context auto-sync (POST_AUTOLOAD_DUMP under `composer global` writes
  to `~/.{agent}/skills/{package}/`), `BOOST_SKIP_GITIGNORE=1` env opt-out,
  and `BaseCommandAdapter` restoring the `composer boost:*` plugin path.
  Removed repo-init's own `post-install-cmd` / `post-update-cmd` scripts —
  end-user propagation is handled by boost-core's plugin; dogfooders run
  `vendor/bin/boost sync --scope=user` manually.
- **Skill moved to canonical package location**: `.ai/skills/repo-init/SKILL.md`
  → `resources/boost/skills/repo-init/SKILL.md`. `resources/boost/skills/`
  is what boost-core's `VendorScanner` reads; `.ai/skills/` is for
  repo-local dev convention skills only.
- **SKILL.md pre-flight step 3** updated: boost-core 0.2.0 auto-syncs on
  `composer global require` / `composer global update`. The manual
  `vendor/bin/boost sync --scope=user` is now a fallback, not the primary
  path. "Updating repo-init" section updated similarly.

## [0.2.14] - 2026-05-17

### Changed

- **`--scope=user` shipped — repo-init now uses boost-core's binary.**
  The deferred feature (was Open Question #3) landed in
  [`sandermuller/boost-core` commit `bebd046b`](https://github.com/SanderMuller/boost-core/commit/bebd046bbcc14d8ca3f7184b911d467b04bc27bb)
  as `vendor/bin/boost sync --scope=user`. New
  `references/boost-core-user-scope.md` documents how repo-init uses it
  (replaces the old `package-boost-user-scope.md` contract file).
  `bin/post-install-sync.php` now invokes `vendor/bin/boost sync --scope=user`
  instead of the never-shipped `vendor/bin/testbench package-boost:sync --scope=user`.
- Bulk updates across `README.md`, `SPEC.md`, `tests/self-removal-contract.md`,
  and `.ai/skills/repo-init/SKILL.md` reflect the boost-core attribution.

### Added

- **README badge audit rule** in all 4 audit phase files (HIGH severity).
  Surfaced via a 20-repo survey: 9/20 SanderMuller PHP repos ship a bare
  README with no badges at all. Canonical set required: Packagist version,
  run-tests CI status, Total Downloads, License (each on its own line,
  shields.io with `?style=flat-square`). Extra badges (PHPStan, Codecov,
  Laravel Compatibility) are EXTRA-info — never flagged.
- **phpstan-extension / rector-extension audit phases** get a LOW-severity
  bullet recommending a `phpstan.yml` workflow badge alongside `run-tests.yml`.

## [0.2.13] - 2026-05-17

### Fixed

- **`stubs/php-package/.lpv`**: line 13 was a duplicate of line 12
  (`phpunit.xml export-ignore` listed twice). Surfaced via php-x402 upgrade
  dogfood where the sub-agent had to hand-write `.lpv` instead of copying
  the stub. Lean-package-validator would warn on the duplicate.

## [0.2.12] - 2026-05-17

Surfaced via an audit pass over 9 SanderMuller PHP repos against the
canonical baseline. Two spec bugs + three audit gaps fixed; the same
audit now flags every drift correctly.

### Fixed

- **audit-laravel-package.md L114** + **audit-php-package.md L81**:
  phpunit.xml/.dist wording was self-contradictory (text said "prefer
  phpunit.xml" while flagging `phpunit.xml`). After 0.2.4 the canonical
  baseline ships `phpunit.xml` (no `.dist`); the rule now correctly flags
  `phpunit.xml.dist`-committed targets and suggests rename. Mirror fix
  in audit-phpstan-extension.md + audit-rector-extension.md.

### Added

- **audit-laravel-package.md category-mandatory list**: `laravel/boost`
  added (was added to per-category-deps.yml in 0.2.5 but audit doc never
  updated). Recurs in 6/6 audited laravel-packages.
- **`.gitattributes` package-boost managed block** is now a HIGH-severity
  NON-CANONICAL flag across all 4 audit phases (was soft mention). 5 of
  9 audited repos missing entirely; without the block, `composer archive`
  ships `.cache/`, `.claude/`, workbench/, AGENTS.md into the published
  tarball.
- **`.lpv` ↔ `validate-gitattributes` cross-script check** in
  audit-laravel-package.md: if `.lpv` is present, composer scripts must
  include `validate-gitattributes`. Caught by laravel-x402 in the audit.
- **detection-rules.md out-of-scope section**: documents `composer-plugin`
  (boost-core in the audit), `metapackage`, `drupal-*`/`wordpress-*`/
  `magento-*` `type:` values. Audit now stops cleanly with "category out
  of scope" instead of trying to fit them into the five-category model.

## [0.2.11] - 2026-05-17

### Fixed

- **sander-variant ServiceProvider stub missing `#[Override]`**: same N2c
  miss as 0.2.10's spatie + workbench fix.
  `stubs/laravel-package/src/__PACKAGE_STUDLY__ServiceProvider.php`
  `register()` now ships with `use Override; #[Override]` so
  `rector --dry-run` exits 0 on fresh `--variant=sander` scaffolds. nova-tool
  and filament-plugin SP stubs intentionally unchanged: their `boot()` /
  custom-signature `register()` aren't overrides of the parent ServiceProvider.

## [0.2.10] - 2026-05-17

### Fixed

Three follow-ups from peer's strict-verify dogfood of 0.2.9:

- **N1 import order in laravel-flavor rector.php**: 0.2.9 inserted
  `use RectorPest\Set\PestSetList;` BEFORE `use RectorLaravel\Set\LaravelSetList;`.
  Pint's `ordered_imports` requires alphabetical (`RectorLaravel` before
  `RectorPest`). Swapped in 4 laravel-flavor stubs.
- **N2b spatie ServiceProvider `#[\Override]` FQN form**: 0.2.9 added the
  attribute as inline FQN. Rector's `AddOverrideAttributeToOverriddenMethodsRector`
  rewrites this to `use Override; #[Override]`. Updated stub to ship the
  imported form directly.
- **N2c workbench WorkbenchServiceProvider missing `#[Override]`**: same
  rector rule fires on `register()`. Added `use Override; #[Override]` to
  4 workbench SP stubs. `boot()` does NOT get the attribute (parent
  `Illuminate\Support\ServiceProvider::boot()` doesn't exist; `#[Override]`
  on a non-overriding method is a compile error).

Strategy going forward: always import, never inline FQN. `pint --test` +
`rector --dry-run` now exit 0 on a fresh scaffold.

## [0.2.9] - 2026-05-17

### Fixed

- **N1**: rector.php stubs (7 categories) now `use RectorPest\Set\PestSetList;`
  plus short-form refs (`PestSetList::class`, `PestSetList::PEST_CODE_QUALITY`)
  instead of inline FQN. Pint's `fully_qualified_strict_types` was rewriting
  the FQN to the import on every run, so `pint --test` flagged the stub
  state as dirty out of the box. Class autoload still gated by
  `class_exists(PestSetList::class) ? [...] : []` — the array only
  evaluates when class is present.
- **N2**: `stubs/laravel-package-spatie/src/__PACKAGE_STUDLY__ServiceProvider.php`
  now declares `#[\Override]` on `configurePackage()`. Without it,
  `rector --dry-run` flagged `AddOverrideAttributeToOverriddenMethodsRector`
  on a fresh scaffold (1 file would change).
- **N3**: `checklists/post-bootstrap-verification.md` no longer requires
  `.ai/` and `.codex/` directories in target — `package-boost:sync`
  doesn't generate either. Correct expected set is
  `.claude/.agents/.cursor/.junie/.kiro/` + `AGENTS.md/CLAUDE.md/GEMINI.md`.

### Added

- `qa-check` composer script in 7 stubs — no-mutate verification gate
  for CI / pre-PR. Runs `rector process --dry-run`, `pint --test`,
  `@phpstan-simplified`, `@test`. Complements existing `qa` which is
  mutating (`rector process` + `pint`) and meant for local fix-up.

## [0.2.8] - 2026-05-17

### Changed

- **Phase 5 precondition gaps closed.** `phases/bootstrap-laravel-package.md`
  step 5 now checks that pest deps are absent from `composer.json` when
  test-framework=phpunit (and vice versa); that `config.allow-plugins`
  doesn't carry stale `pestphp/pest-plugin` on phpunit scaffolds; that
  test files don't use pest syntax (`grep -rE '^(test|it)\(|^expect\('`)
  on phpunit scaffolds. Without these, scaffolder bugs could produce a
  "phase 5 no-op" verdict on a broken target.
- **Phase 9 precondition tightened.** Now requires both the repo-init
  skill check AND `.claude/`/`AGENTS.md` presence in target (from
  `package-boost:sync`). When only the skill check passes, `sync` is
  mandatory regardless of repo-init install scope. Fixes the case where
  `composer install --no-scripts` left target without AI tooling.

### Audit nudge for users with pre-0.2.5 scaffolds

If your scaffold was produced before 0.2.5, it may be missing
`laravel/boost` in `require-dev` and have stale pest/phpunit drift.
Run `phases/audit-laravel-package.md` against the target to detect.
Symptoms: `package-boost:sync` fatals with
`Class "Laravel\Boost\BoostServiceProvider" not found`; both pest+phpunit
deps installed; `tests/Pest.php` present despite `--test-framework=phpunit`.

## [0.2.7] - 2026-05-17

### Fixed

- `stubs/{laravel-package, laravel-package-spatie, filament-plugin,
  nova-tool}/rector.php` — `withSets([...])` block mixed `LaravelSetList`
  and `PestSetList` entries; earlier conditional-wrap missed this 7-entry
  variant. Now: `array_merge([laravel-sets], class_exists(PestSetList) ?
  [pest-sets] : [])` so phpunit-only scaffolds don't fatal on
  `Class "PestSetList" not found`.

## [0.2.6] - 2026-05-17

### Fixed

- `__TEST_RUNNER__` + `__TEST_COVERAGE_FLAG__` placeholders added to 5
  stub `composer.json` scripts (`laravel-package`,
  `laravel-package-spatie`, `filament-plugin`, `nova-tool`, `php-package`).
  Previously hardcoded `vendor/bin/pest` or `vendor/bin/phpunit`, so the
  chosen `--test-framework` was only half-applied. `phpstan-extension` +
  `rector-extension` remain phpunit-hardcoded by spec.

## [0.2.5] - 2026-05-17

### Fixed

- **Add `laravel/boost` to laravel-package + laravel-package-spatie +
  filament-plugin + nova-tool require-dev**. All four categories' stub
  `testbench.yaml` lists `Laravel\Boost\BoostServiceProvider` as a provider,
  so `package-boost:sync` (which boots testbench) fatals with
  `Class "Laravel\Boost\BoostServiceProvider" not found` if Boost isn't in
  require-dev. Discovered when a real user scaffolded a laravel-package
  interactively and hit the fatal at sync time. Updated both
  `per-category-deps.yml` and the per-category stub `composer.json` so
  fresh scaffolds + audits both surface it.

## [0.2.4] - 2026-05-17

Critical packaging fix plus the round-3/4 dogfood-surfaced parity fixes.

### Fixed

- **Source archive stripped its own stubs**: `stubs/*/.gitattributes` files
  are templates for SCAFFOLDED projects, but git also honored them when
  building the Packagist tarball — removing every dotfile and managed-block
  entry they listed (`.editorconfig`, `.gitignore`, `.mcp.json`,
  `.github/workflows/*`, `rector.php`, `phpstan.neon.dist`, `phpunit.xml`,
  `testbench.yaml`, `workbench/`, etc.). Renamed all 5 stub `.gitattributes`
  → `_gitattributes`; companion `repo-new` 0.2+ release renames back to
  `.gitattributes` on scaffold-time copy.
- **PSR-4 double-trailing-backslash** in 7 stub `composer.json` (`\\\\` → `\\`).
- **`phpunit.xml.dist` → `phpunit.xml`** (file rename + 30 ref updates across
  workflows, gitattributes, .lpv, docs).
- **Test-framework conditional stubs**: `tests/Pest.php` moved to new
  `stubs/test-framework-pest/`; phpunit-only packages no longer ship the
  Pest bootstrap. Added `stubs/test-framework-{pest,phpunit}/tests/Unit/ExampleTest.php`
  so `composer test` passes on fresh scaffold.
- **rector.php in 8 stubs**: dropped `containerCacheDirectory` (path doesn't
  exist pre-run); `PestSetList` now wrapped in `class_exists()` so
  phpunit-only categories don't crash.
- **phpstan.neon.dist in 8 stubs**: ignore `method.internalClass` in
  `tests/*` with `reportUnmatched: false` (Pest's `expect()` API is
  `@internal` but the intended public surface for tests).
- **rector-extension stub**: stripped pest deps + allow-plugin; added
  `phpunit/phpunit ^11.0||^12.0`; switched test scripts to `vendor/bin/phpunit`.

### Added

- `stubs/shared/{README,LICENSE,CHANGELOG,SECURITY}.md` baseline meta files
  with placeholder substitution.
- `stubs/laravel-project/.github/workflows/run-tests.yml` (PHP-only matrix).

## [0.2.3] - 2026-05-17

Dogfooded via `sandermuller/repo-new` CLI scaffolding both a fictional `php-package` AND `laravel-project`. Two real data bugs surfaced in `per-category-deps.yml`:

### Fixed

- **`pestphp/pest-plugin-laravel` constraint** bumped to `^4.1` (only ^4.1+ supports Laravel 13). Previously unconstrained → resolved to old versions incompatible with Laravel 13's `^13.x` framework.
- **`laravel-project` mandatory `require-dev` documentation** explicitly notes that CLI implementations MUST filter or move packages Laravel already shipped. Laravel 13+ ships `laravel/tinker` in `require` historically (was `require-dev`); a blanket `composer require --dev` errors with "currently present in the require key". The fix is two-step: `composer remove --no-update <pkg>` then `composer require --dev <list>` so packages end up in the right scope. Documented inline in per-category-deps.yml.

## [0.2.2] - 2026-05-17

### Fixed

- **`run-tests.yml` watches the right PHPUnit config file.** All 7 category stubs (`stubs/<cat>/.github/workflows/run-tests.yml`) had path filter watching `phpunit.xml`, but scaffold ships `phpunit.xml`. Result: PHPUnit config changes in generated repos wouldn't trigger CI. Fixed across `php-package`, `laravel-package`, `laravel-package-spatie`, `phpstan-extension`, `rector-extension`, `filament-plugin`, `nova-tool`. Surfaced by codex post-fix review of 0.2.1.

## [0.2.1] - 2026-05-17

Dogfood-surfaced bug fixes from scaffolding sandermuller/repo-new via the agent path.

### Fixed

- **`stubs/shared/.gitattributes` slimmed to validator-passing set.** The previous shipped file listed entries for files that don't always exist post-scaffold (e.g. `.ai/`, `.cursorrules`, `.windsurfrules`, `testbench.yaml`, `workbench/`, `phpunit.xml`, `CHANGELOG.md`). `stolt/lean-package-validator` inspects the working tree and flagged the mismatch as invalid. Slimmed to the validator-approved set: only files that always exist after scaffold + `package-boost:sync`. Category-specific extras (`testbench.yaml`, `workbench/`) moved to per-category `.gitattributes` overrides for `laravel-package`, `laravel-package-spatie`, `filament-plugin`, `nova-tool`.
- **Idempotency precondition wording for renamed-on-substitution stubs.** `bootstrap-php-package.md` step 3 + `bootstrap-laravel-package.md` step 4 now explicitly tell the agent to derive the SUBSTITUTED target filename FIRST (e.g. `src/RepoNew.php`) before checking existence, not check the literal stub filename (e.g. `src/__PACKAGE_STUDLY__.php`). Without this clarification, re-runs would re-copy + re-substitute renamed stubs incorrectly.

### Why these bugs existed

Both surfaced during the dogfood scaffold of `sandermuller/repo-new` (a future package whose CLI is designed in `specs/repo-new-cli.md`). The validator bug existed because the shipped `.gitattributes` was max-everything (covering all categories' file sets). The idempotency wording bug was a subtle slip in the v0.2 rework — the spec was correct in intent but the implementation hint was missing.

## [0.2.0] - 2026-05-17

Bootstrap phase idempotency rework. Enables forthcoming `sandermuller/repo-new` CLI to do mechanical scaffolding without conflicting with the agent path.

### Added

- **RQ41 in SPEC.md** documenting the bootstrap-phase idempotency contract.
- `**Idempotent.**` header banner on every `phases/bootstrap-<category>.md`.
- `**Skip if:** <precondition>` block on each mutating step (steps 3-9 in laravel-package, equivalent in other categories). Read-only steps (pre-flight, verification, print) always run.
- `## Idempotency invariants (RQ41 contract)` section at the bottom of every bootstrap phase file documenting the per-step skip preconditions for review.
- `check-bootstrap-idempotency.sh` CI script asserting every phase file has the required structure.

### Changed

- **All 5 `bootstrap-<category>.md` phase files** rewritten with idempotency guards. Functional behaviour unchanged for first-time runs; second-runs (and CLI-then-agent runs) are now no-ops.
- Open Q #1 (`--ai` flag on `laravel new`) resolved to use `--boost` (the actual Laravel installer flag). `bootstrap-laravel-project.md` + related docs updated.

### Why

`sandermuller/repo-new` CLI (separate package, in design at `specs/repo-new-cli.md`) does mechanical scaffolding for new repos — composer init, stub copy, composer require, etc. After CLI scaffolding, the user asks the agent to "finish" the bootstrap. Without idempotency, the agent re-reading the bootstrap phase file would re-do work the CLI already did — double-installs, redundant stub copies, lockfile thrash. Idempotency makes the agent path a no-op when CLI ran first, AND makes manual mid-run aborts safe to retry.

### Compatibility

- Phase file structure is backwards-compatible: a fresh repo run (no prior state) follows the same step list as before. Skip preconditions just add up-front guards that NEVER fire on fresh runs.
- repo-init `^0.1` consumers can upgrade to `0.2` with no migration. Their existing repos are unaffected (audit/upgrade phase files unchanged).

## [0.1.0] - 2026-05-17

Initial release. Global-install model (`composer global require sandermuller/repo-init`).

### Added

- **Skill** — `.ai/skills/repo-init/SKILL.md` single entry point. Routes the agent through 3 steps: decide intent (bootstrap/audit/upgrade), decide category (5 options), open the matching phase file.
- **5 categories supported**: `laravel-project`, `laravel-package` (sander-style + spatie-style variants), `php-package`, `phpstan-extension`, `rector-extension`.
- **15 phase playbooks** under `phases/` — one per (category × mode), each self-contained.
- **14 reference docs** under `references/` covering detection rules, dep lists (md + machine-readable yml parallel), composer scripts, phpstan/rector configs, canonical reference repos, version defaults, pest-vs-phpunit, gitattributes managed-block contract, upgrade merge modes, composer failure modes, placeholder transforms.
- **5 checklists** under `checklists/` — preflight, per-category-never-touch, post-bootstrap-verification, post-upgrade-verification, self-removal.
- **6 stub trees** under `stubs/` — shared + 5 categories. Stubs use literal `__PLACEHOLDER__` strings the agent finds-and-replaces per `references/placeholder-rules.md`.
- **Composer scripts** in package's own composer.json: `post-install-cmd` and `post-update-cmd` auto-sync the skill into `~/.claude/skills/` via `package-boost:sync --scope=user`.

### Architecture decisions

- **Zero PHP code in the package.** No `src/`, no artisan, no Symfony Console. The agent does the work; the package is the playbook.
- **Global install by default** (matches `composer global require laravel/installer`). Project-local install kept as escape hatch.
- **Stays-installed-until-done** — no per-target install or self-removal. Repo-init lives globally; targets stay clean.
- **No state files written to targets.** Findings are conversation-scoped.

### Dependencies

- Requires `sandermuller/package-boost: ^0.15` (for skill propagation).
- Requires `orchestra/testbench: ^9.0||^10.0||^11.0` (to invoke `package-boost:sync` outside a Laravel app).

### Known blockers (resolved before release)

- `sandermuller/package-boost` must ship the `--scope=user` sync feature (Open Question #3 in SPEC.md). Tracking this as a pre-release dependency.

### Spec

- 40 Resolved Questions documenting every architectural decision + rationale.
- 4 Open Questions remaining: `--ai` flag verification on Laravel installer; package-boost user-scope sync feature; skill-copy-not-symlink behavior verification.
- Independently reviewed via codex in 3 rounds (v3 → v4 → v5 → v6). All findings addressed.

[Unreleased]: https://github.com/sandermuller/repo-init/compare/0.2.3...HEAD
[0.2.3]: https://github.com/sandermuller/repo-init/compare/0.2.2...0.2.3
[0.2.2]: https://github.com/sandermuller/repo-init/compare/0.2.1...0.2.2
[0.2.1]: https://github.com/sandermuller/repo-init/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/sandermuller/repo-init/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/sandermuller/repo-init/releases/tag/0.1.0
