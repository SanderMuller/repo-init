# Changelog

All notable changes to `sandermuller/repo-init` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Pre-`1.0.0` releases may introduce breaking changes in MINOR bumps; we surface those here clearly.

## [0.5.0] - 2026-05-20

### Fixed

- **BLOCKING — scaffolded packages failed their first non-interactive
  `composer install`.** All 7 stub `composer.json` files that carry a
  boost-family dependency (`filament-plugin`, `laravel-package`,
  `laravel-package-spatie`, `nova-tool`, `php-package`, `phpstan-extension`,
  `rector-extension`) were missing `sandermuller/boost-core` from
  `config.allow-plugins`. `boost-core` is a `composer-plugin` pulled in
  transitively by the boost umbrella, so `composer install --no-interaction`
  aborted with "blocked by your allow-plugins config". All 8 stubs
  (incl. `composer-plugin`) now allow-list both `sandermuller/boost-core`
  and `sandermuller/package-boost-php`. Surfaced by a real-world scaffold of
  `sandermuller/boost-skills`. Matching HIGH-severity audit rule added to the
  5 package-category audit phases; matching upgrade-phase fix.
- **POSIX-shell `post-install-cmd` in all 7 stubs.** The old
  `if [ "$COMPOSER_DEV_MODE" = "1" ]; then vendor/bin/boost sync ...; fi`
  form is Windows-broken and predates boost-core's PHP script callback.
  Replaced across all 8 stubs (+ `composer-plugin`, which had none) and
  `references/composer-scripts.md` with
  `SanderMuller\BoostCore\Scripts\BoostAutoSync::runWithSummary` for both
  `post-install-cmd` and `post-update-cmd` (the latter was missing entirely).

### Added

- **`skill-bundle` is now a first-class category** (7th full category — own
  bootstrap / audit / upgrade phases). Covers distributable Composer packages
  whose product is AI agent skills: `type: library`, `sandermuller/boost-core`
  in runtime `require` (consumers need it to discover the shipped skills),
  ships `resources/boost/skills/`, no `src/` PHP. Detected by `boost-core` in
  `require` — the discriminator from `php-package`. Ships:
  - `stubs/skill-bundle/` — lean `composer.json` (boost-core in `require`;
    `laravel/pint` + `stolt/lean-package-validator` in `require-dev`; no PHP
    toolchain, no test runner — it ships pure-markdown skills) + `.lpv`.
  - `phases/{bootstrap,audit,upgrade}-skill-bundle.md`.
  - `references/detection-rules.md` row 6; `references/per-category-deps.{yml,md}`
    section; `resources/boost/skills/repo-init/SKILL.md` 6→7 category table.
  - CI: `check-layout.sh`, `check-phase-coverage.sh`, `check-stub-composer-validity.sh`
    updated for the new category.

### Changed

- **BREAKING — boost-family dependency remapped per category.** The boost
  umbrella was previously `sandermuller/package-boost-php` in the shared
  dev-dep list for every category. It is now assigned by category:
  - `php-package`, `phpstan-extension`, `rector-extension`, `composer-plugin`
    → `sandermuller/package-boost-php`
  - `laravel-package` (+ `filament-plugin`, `nova-tool`) →
    `sandermuller/package-boost-laravel`
  - `laravel-project` → `laravel/boost` only (Laravel's own AI tooling —
    handles application-level skill sync via `php artisan boost:install` /
    `boost:update`; the `bootstrap-` / `upgrade-laravel-project` sync steps
    were rewritten off boost-core's `vendor/bin/boost`).
  Applied across the 7 stub `composer.json` files, `per-category-deps.{yml,md}`,
  `shared-dev-deps.md`, and all 6 audit + 6 upgrade phases.
- **`composer-plugin` now gets `sandermuller/package-boost-php`.** The 0.3.0
  `shared-exclusions` entry that dropped it was removed — `composer-plugin` is
  a framework-agnostic Composer package and takes the umbrella like the other
  agnostic categories.
- Stub `package-boost-php` constraint bumped `^0.3.0` → `^0.4.0`; the
  Laravel-category stubs now pin `sandermuller/package-boost-laravel: ^0.4.0`.

## [0.4.0] - 2026-05-20

### Changed

- **Bumped `sandermuller/package-boost-php` from `^0.3.1` to `^0.4.0`** in
  repo-init's own `composer.json`. `composer.lock` now resolves
  `package-boost-php 0.4.0` + `boost-core 0.4.0` (transitive); `laravel/prompts`
  moved `v0.3.17 → v0.3.18` in the same update. Verified end-to-end:
  `composer update` clean, `BoostAutoSync` post-update callback runs without
  error. The 7 stub `composer.json` files still pin `package-boost-php ^0.3.0`
  — a separate scaffold-stub bump is tracked independently.
- **BREAKING (user-scope skill path): `~/.{agent}/skills/repo-init/` →
  `~/.{agent}/skills/sandermuller__repo-init/`.** boost-core 0.4.0 namespaces
  user-scope skill dirs by the full `vendor__package` slug (`/` replaced by
  `__`, a sequence the Composer name spec forbids — so distinct packages can
  no longer collide on a shared basename). boost-core's `UserScopeMigrator`
  runs a one-time, ownership-checked rename of the legacy dir on the first
  `composer global update` after upgrade. Project-scope `.claude/skills/<skill>/`
  paths are **unaffected** — the `__` namespacing is user-scope (`$HOME`) only.
  Migration steps in `UPGRADING.md` "0.3.x → 0.4.0".
- **User-scope path doc sweep.** Migrated every hard-coded
  `~/.{agent}/skills/repo-init/` reference to the namespaced form across
  `README.md`, `RELEASING.md`, `SECURITY.md`, `UPGRADING.md`, the `repo-init`
  skill (`resources/boost/skills/repo-init/SKILL.md`),
  `references/boost-core-user-scope.md`,
  `checklists/{self-removal,post-bootstrap-verification}.md`,
  `tests/self-removal-contract.md`, and the `bootstrap-php-package` /
  `bootstrap-laravel-package` phases. Project-scope `.claude/skills/repo-init/`
  references left untouched (those are skill-name paths, not package slugs).
- New `UPGRADING.md` "0.3.x → 0.4.0" section documenting the breaking path
  change and the auto-migration.

### Fixed

- **Stale `sandermuller/package-boost` (no `-php` suffix) refs in
  `RELEASING.md`.** Pre-release checklist + the "Coordinated bump" section now
  name `package-boost-php` and spell out the
  `composer update --with-all-dependencies` lockfile step.
- **Stale `vendor/bin/testbench package-boost:sync` in
  `checklists/self-removal.md`** project-local removal step → `vendor/bin/boost sync`
  (the artisan command was the testbench-based predecessor; `package-boost-php`
  registers no artisan command).
- **CHANGELOG hygiene.** The `[Unreleased]` block holding already-tagged 0.3.1
  content is now correctly labelled `[0.3.1]`; the version-compare link
  references at the bottom (stale since 0.2.3) are complete through 0.4.0.

## [0.3.1] - 2026-05-18

### Changed

- **README staleness sweep**: corrected post-0.3.0 counts and references.
  Phase count `15 → 20`, reference count `14 → 18`, stub-tree count `8 → 12`
  (now lists all 9 categories + shared + 2 test-framework variants).
  Skill entry-point path `.ai/skills/repo-init/SKILL.md` → canonical
  `resources/boost/skills/repo-init/SKILL.md`. Install/Update sections
  describe boost-core's global-context auto-sync (active since 0.2.0)
  instead of the removed `post-install-cmd` shell-out. `.mcp.json` flagged
  Laravel-only (composer-plugin / rector-extension / phpstan-extension
  skip it). Dropped the "v3 → v4 → v5 → v6 codex review rounds" internal
  process note from the Design section.

### Fixed

- **Stale `php artisan package-boost:sync` refs scrubbed across active docs.**
  `phases/bootstrap-laravel-project.md` step 9, `phases/upgrade-laravel-project.md`
  composer-scripts merge + post-upgrade "Run sync" section, `references/composer-scripts.md`
  `sync-ai` recipe, `checklists/post-upgrade-verification.md` smoke check —
  all swapped to `vendor/bin/boost sync`. The artisan command was from the
  predecessor `sandermuller/package-boost` (Laravel service provider);
  `package-boost-php` is framework-agnostic and registers no artisan command.
  Surfaced by real-world bootstrap dogfood. SPEC.md still references the
  old command in historical context — preserved as a planning record.
- **Audit ↔ bootstrap drift on `.mcp.json` for framework-agnostic
  categories** (composer-plugin, php-package, phpstan-extension,
  rector-extension). The shared `.mcp.json` stub ships a Laravel/testbench
  MCP server config (`vendor/bin/testbench boost:mcp`) with no equivalent
  for non-Laravel code. Fix in both directions: bootstrap phases for
  these four categories now skip `.mcp.json` when copying from
  `stubs/shared/`, and audit phases declare matching per-category
  exclusions in their MISSING-files sections. Surfaced by real-world
  audit against a tagged composer-plugin package post-0.3.0; bootstrap
  side caught by codex review during self-evaluation (without it the
  audit-only fix would have silently drifted from what bootstrap
  actually produces).
- **`boost.php` vs `boost.json` confusion in laravel-project sync docs**
  (caught by codex review). The doc claimed boost-core auto-sync fires
  on `composer install/update` "when `boost.php` is at the project root"
  — but `laravel new --boost` generates `boost.json` (for the unrelated
  `laravel/boost` package), NOT `boost.php`. `bootstrap-laravel-project.md`
  step 9 + `upgrade-laravel-project.md` "Run boost-core sync" section now
  clarify the distinction and point to `composer boost:install --no-interaction`
  as the one-time setup if auto-sync is desired.
- **`@php` prefix consistency** in `references/composer-scripts.md` +
  `phases/upgrade-laravel-project.md`: `sync-ai` script now matches the
  shipped stubs (`vendor/bin/boost sync`, no `@php` prefix). `vendor/bin/boost`
  has its own PHP shebang; `@php` is redundant.

## [0.3.0] - 2026-05-18

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

[0.5.0]: https://github.com/sandermuller/repo-init/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/sandermuller/repo-init/compare/0.3.1...0.4.0
[0.3.1]: https://github.com/sandermuller/repo-init/compare/0.3.0...0.3.1
[0.3.0]: https://github.com/sandermuller/repo-init/compare/0.2.14...0.3.0
[0.2.14]: https://github.com/sandermuller/repo-init/compare/0.2.13...0.2.14
[0.2.13]: https://github.com/sandermuller/repo-init/compare/0.2.12...0.2.13
[0.2.12]: https://github.com/sandermuller/repo-init/compare/0.2.11...0.2.12
[0.2.11]: https://github.com/sandermuller/repo-init/compare/0.2.10...0.2.11
[0.2.10]: https://github.com/sandermuller/repo-init/compare/0.2.9...0.2.10
[0.2.9]: https://github.com/sandermuller/repo-init/compare/0.2.8...0.2.9
[0.2.8]: https://github.com/sandermuller/repo-init/compare/0.2.7...0.2.8
[0.2.7]: https://github.com/sandermuller/repo-init/compare/0.2.6...0.2.7
[0.2.6]: https://github.com/sandermuller/repo-init/compare/0.2.5...0.2.6
[0.2.5]: https://github.com/sandermuller/repo-init/compare/0.2.4...0.2.5
[0.2.4]: https://github.com/sandermuller/repo-init/compare/0.2.3...0.2.4
[0.2.3]: https://github.com/sandermuller/repo-init/compare/0.2.2...0.2.3
[0.2.2]: https://github.com/sandermuller/repo-init/compare/0.2.1...0.2.2
[0.2.1]: https://github.com/sandermuller/repo-init/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/sandermuller/repo-init/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/sandermuller/repo-init/releases/tag/0.1.0
