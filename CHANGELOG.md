# Changelog

All notable changes to `sandermuller/repo-init` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Pre-`1.0.0` releases (0.x.x — historical) introduced breaking changes in MINOR bumps; from 1.0.0 onward repo-init follows standard SemVer (breaking changes ship as MAJOR only). The pre-1.0 entries below remain for reference.

## [1.4.1](https://github.com/sandermuller/repo-init/compare/1.4.0...1.4.1) - 2026-05-31

<!-- verified-sha: e6ef21c2a07ad5bad4dba792e6b6a34c6903b0b7 -->
Patch release. Fixes two composer-plugin scaffold gaps and a `.lpv`
validator-config defect, reconciles the `.gitattributes` reference, and adopts
the current boost-family dependency line.

### Fixed

- **`.lpv` stubs shipped in the wrong format.** `php-package` and `skill-bundle`
  shipped a `.lpv` using `.gitattributes` syntax (`<path> export-ignore` per line)
  instead of lean-package-validator's bare-glob format. The validator joins those
  lines into a glob containing spaces that matches no file, so a scaffolded
  package's `validate-gitattributes` passed *vacuously* — silently checking
  nothing. Now bare globs, one artifact per line.
- **composer-plugin scaffolds had no CI test run.** Every other code-bearing
  category ships its own `run-tests.yml`; composer-plugin shipped none, though its
  bootstrap and audit expected one. Added the stub (framework-agnostic, PHP-only
  matrix).
- **composer-plugin shipped no `.lpv`.** It runs `validate-gitattributes` but had
  no validator config, so the validator fell back to its default preset and
  skipped project-specific artifacts (`boost.php`, `.ai/`, `.claude/`). Added
  `composer-plugin/.lpv`.
- **`CHANGELOG.md` was listed in `.lpv` but not export-ignored**, so a fresh
  scaffold's `validate-gitattributes` would flag it. `CHANGELOG.md` and
  `.phpunit.cache` are now export-ignored in the shared `.gitattributes` managed
  block. The never-shipped `workbench/` entry was removed from `php-package/.lpv`.

### Changed

- Audit phases: a structured "MISSING composer.json scripts" section for the
  skill-bundle audit; an atomic callback↔floor-coupling reminder across all wrapper
  audits; a `phpunit.xml.dist` check for the composer-plugin audit. `UPGRADING.md`
  now documents the 1.4.0 façade migration.
- `references/gitattributes-managed-block.md` reconciled — removed a duplicate
  entry, separated laravel-only entries from the universal set, completed the
  `.lpv` per-category list, and documented the `.lpv` file format.

### Internal

- repo-init's own dependencies bumped to the current boost-family line:
  `boost-core ^0.16.0`, `boost-skills ^2.0.0`, `package-boost-php ^0.16.1`.

**Full Changelog**: <https://github.com/SanderMuller/repo-init/compare/1.4.0...1.4.1>

## [1.4.0](https://github.com/sandermuller/repo-init/compare/1.3.1...1.4.0) - 2026-05-31

<!-- verified-sha: 4c05f83ba2d49f0d3a7c85d0a77a63c621700eb5 -->
One-package install. Scaffolds, audits, and upgrades now wire the boost
auto-sync hook through each wrapper's own namespace façade instead of
boost-core's transitive `BoostAutoSync` class — so a scaffolded package
references only a class from its direct dependency, and consumers require one
boost package, not two.

Requires `package-boost-php` 0.16.0+ and `package-boost-laravel` 0.10.0+ (the
releases that introduced the façades), both live on Packagist.

### Changed

- The eight wrapper scaffolds now mint `post-install-cmd` / `post-update-cmd`
  as their wrapper façade rather than `SanderMuller\BoostCore\Scripts\BoostAutoSync::run`:
  
  - php-wrapper (`php-package`, `composer-plugin`, `rector-extension`,
    `phpstan-extension`) → `SanderMuller\PackageBoostPhp\Scripts\AutoSync::run`,
    floor `sandermuller/package-boost-php: ^0.16.0`.
  - laravel-wrapper (`laravel-package`, `laravel-package-spatie`,
    `filament-plugin`, `nova-tool`) → `SanderMuller\PackageBoostLaravel\Scripts\AutoSync::run`,
    floor `sandermuller/package-boost-laravel: ^0.10.0`.
  
  Callback swap and floor bump land as a single change per scaffold — a façade
  callback is never written without the floor that ships it.
  
- The audit and upgrade phases enforce the family-correct callback per
  category. `references/composer-scripts.md` is the source of truth: it now
  carries a per-family canonical table plus the floor that ships each façade,
  and the baseline scripts block forks the callback by wrapper family while
  keeping every other key shared.
  
### Added

- An atomic floor-coupling rule across the upgrade phases. Whenever an upgrade
  writes a façade callback — inserting a missing hook *or* replacing an old
  `BoostAutoSync::run` — it bumps the wrapper floor in the same patch. Without
  this, upgrading a repo still on a pre-façade floor would leave the hook
  pointing at a class that isn't autoloadable; Composer skip-warns past it via
  its `class_exists()` guard and auto-sync silently stops running. The rule
  closes both the swap and the partial-drift insert paths.

### Unchanged

- `skill-bundle` keeps `SanderMuller\BoostCore\Scripts\BoostAutoSync::run` — it
  depends on `boost-core` directly, so that callback is already a direct-dep
  class and the façade rule doesn't apply.
- `laravel-project` keeps its `@php artisan project-boost:sync` hook — an
  artisan command, never a class callback.

**Full Changelog**: [https://github.com/SanderMuller/repo-init/compare/1.3.1...1.4.0](https://github.com/SanderMuller/repo-init/compare/1.3.1...1.4.0)

## [1.3.1](https://github.com/sandermuller/repo-init/compare/1.3.0...1.3.1) - 2026-05-29

<!-- verified-sha: 99da238951ec04b36a623f812fb4de06143af18e -->
### 1.3.1

Tracks the same-day boost-family re-tag. `sandermuller/package-boost-php` 0.12.0 floor-bumped its `boost-core` requirement to `^0.10`, so repo-init's scaffold defaults and own dependencies move in lockstep.

#### Changed

- **`boost-core` floor raised to `^0.10.0`** — for repo-init's own runtime dependency and the `skill-bundle` scaffold (the category that requires `boost-core` directly). package-boost-php 0.12.0 requires `boost-core ^0.10`, so this bump is mandatory to keep the constraint chain resolvable.
- **`package-boost-php` floor raised to `^0.12.0`** — in repo-init's dev dependencies and the four framework-agnostic scaffolds (php-package, composer-plugin, phpstan-extension, rector-extension).

Laravel categories are unchanged: they pull `boost-core` transitively through `package-boost-laravel ^0.7.3`, which still targets the `boost-core ^0.9` line. Their floors follow once package-boost-laravel adopts boost-core 0.10.

Resolves to boost-core 0.10.0 / package-boost-php 0.12.0 / boost-skills 1.9.2; no advisories.

**Full Changelog**: [https://github.com/SanderMuller/repo-init/compare/1.3.0...1.3.1](https://github.com/SanderMuller/repo-init/compare/1.3.0...1.3.1)

## [1.3.0](https://github.com/sandermuller/repo-init/compare/1.2.0...1.3.0) - 2026-05-29

<!-- verified-sha: 2abd83a268bda31beb9f6c166feb7717158ff3c1 -->
### Changed

- **Scaffold dependency floors bumped to the current boost-family line.** Newly bootstrapped packages now pin:
  
  - `sandermuller/boost-core ^0.9.3` — picks up the render-fail-then-write data-loss safety patch; `0.9.4+` ride along.
  - `sandermuller/boost-skills ^1.9.0` — skips the broken `1.8.0` mis-tag.
  - `sandermuller/package-boost-php ^0.10.1` — framework-agnostic categories (php-package, composer-plugin, phpstan-extension, rector-extension).
  - `sandermuller/package-boost-laravel ^0.7.3` — Laravel categories (laravel-package, laravel-package-spatie, filament-plugin, nova-tool).
  
  Applied across all nine stub `composer.json` files and repo-init's own dependencies.
  
### Fixed

- **Audit phases now apply the PHPUnit-cache rules to Pest repositories.** The PHPUnit-cache audit block was gated on `test-framework=phpunit`, so Pest repos skipped it — but Pest reuses PHPUnit's `phpunit.xml` and the same cache mechanism, so the rules apply equally. The gate now keys on the presence of a `phpunit.xml`, catching non-canonical `cacheDirectory` values and stray `.phpunit.cache/` directories that were previously missed on Pest repos. Affects the laravel-package, php-package, composer-plugin, rector-extension, and laravel-project audit phases.

### Internal

- Removed repo-init's own `validate-gitattributes` quality gate (and the direct `stolt/lean-package-validator` dev dependency). repo-init ships `stubs/` trees whose filenames collide with root dev files, so its own `.gitattributes` must use root-anchored `export-ignore` patterns — which the validator's format check rejects. The gate was a false positive whose prescribed fix would re-corrupt the published archive. The validator and its `validate-gitattributes` script remain part of what repo-init scaffolds for consumer packages, which are unaffected.

**Full Changelog**: [https://github.com/SanderMuller/repo-init/compare/1.2.0...1.3.0](https://github.com/SanderMuller/repo-init/compare/1.2.0...1.3.0)

## [1.2.0](https://github.com/sandermuller/repo-init/compare/1.1.0...1.2.0) - 2026-05-26

Aligns repo-init with the latest boost family. **`sandermuller/package-boost-php` 0.9.0** dropped its Composer plugin status (subcommands moved to the standalone `vendor/bin/package-boost-php` binary, matching what `sandermuller/boost-core` did in 0.6.0). That cascades into the audit/upgrade contract: scaffolded `composer.json` files no longer need a `sandermuller/*` entry in `config.allow-plugins`.

### Why

Every prior repo-init release flagged a MISSING `sandermuller/package-boost-php: true` allow-plugins entry as **HIGH severity** — because the package was `type: composer-plugin`, the entry was required for non-interactive `composer install`. As of 0.9.0, the entry is a **no-op**: Composer ignores it. Existing scaffolds that carry it are not broken, just stale; new scaffolds don't need it at all.

The audit/upgrade rules invert accordingly. Carrying the entry is now **MEDIUM-stale**, suggested for removal. The audit no longer flags MISSING (the historic flag), because under 0.9.0 there is no missing requirement to flag.

### What 1.2.0 ships

#### Root toolchain bump

- `sandermuller/boost-core` constraint widened to `^0.7.0` (was `^0.6.0`). Pulls in boost-core 0.7.0 — see [boost-core 0.7.0 release notes](https://github.com/SanderMuller/boost-core/releases/tag/0.7.0). Additive: `withRemoteSkills(...)`, `SkillRenderer` plugin contract, `boost where` command. No migration required.
- `sandermuller/package-boost-php` dev-constraint widened to `^0.9.0` (was `^0.7.0`). Pulls in package-boost-php 0.9.0 — see [package-boost-php 0.9.0 release notes](https://github.com/SanderMuller/package-boost-php/releases/tag/0.9.0). BREAKING upstream (plugin dropped); repo-init absorbs that into the audit/upgrade contract below.
- Dropped `sandermuller/package-boost-php: true` from repo-init's own `config.allow-plugins` (now empty under `config`, just `sort-packages: true`).

#### Stub modernization (9 stubs)

| Stub                       | Change                                                                                                |
|----------------------------|-------------------------------------------------------------------------------------------------------|
| `skill-bundle`             | `boost-core` `^0.6.0` → `^0.7.0`; `boost-skills` `^0.1.0` → `^1.0`                                    |
| `php-package`              | `package-boost-php` `^0.7.0` → `^0.9.0`; `boost-skills` `^0.1.0` → `^1.0`; allow-plugins entry removed |
| `composer-plugin`          | same as php-package                                                                                   |
| `phpstan-extension`        | same as php-package                                                                                   |
| `rector-extension`         | same as php-package                                                                                   |
| `laravel-package`          | `boost-skills` `^0.1.0` → `^1.0`; allow-plugins entry removed (`package-boost-php` pulled transitively via `package-boost-laravel`) |
| `laravel-package-spatie`   | same as `laravel-package`                                                                             |
| `filament-plugin`          | same as `laravel-package`                                                                             |
| `nova-tool`                | same as `laravel-package`                                                                             |

All 9 stubs JSON-valid post-edit; new scaffolds floor on boost-core 0.7, package-boost-php 0.9, boost-skills 1.x.

#### Audit-phase rule inversion (5 phases)

`phases/audit-{laravel-package,php-package,composer-plugin,phpstan-extension,rector-extension}.md` — inverted the NON-CANONICAL `sandermuller/package-boost-php` allow-plugins rule:

| Was                                                                          | Now                                                                                                                              |
|------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------|
| MISSING `sandermuller/package-boost-php: true` in `config.allow-plugins` = **HIGH severity** | PRESENT `sandermuller/package-boost-php: true` in `config.allow-plugins` = **MEDIUM-stale** (post-0.9.0; suggest removal) |

#### Upgrade-phase rewrite with version-guarded ordering (5 phases)

`phases/upgrade-{laravel-package,php-package,composer-plugin,phpstan-extension,rector-extension}.md` — `config.allow-plugins` merge-keys section rewritten. Order matters: removing the entry while the installed `package-boost-php` is still `< 0.9.0` would block the next non-interactive `composer install` with a `blocked-plugin` error (pre-0.9 versions are still `type: composer-plugin`).

The new contract:

1. Verify installed version: `composer show sandermuller/package-boost-php`.
2. If `< 0.9.0`: bump the constraint to `^0.9.0` and run `composer update sandermuller/package-boost-php` FIRST.
3. Only THEN remove the allow-plugins entry.

`sandermuller/boost-core: true` removal is unconditional (boost-core ≥ 0.6.0 has been `type: library` for releases now).

#### Reference + checklist alignment

- `references/per-category-deps.md` — prose updated to reflect both boost-core and package-boost-php being `type: library`. The "boost-family umbrella" section now states scaffolds need NO `sandermuller/*` allow-plugins entries.
- `references/boost-core-user-scope.md` — constraint citation bumped to `^0.7.0`.
- `checklists/post-upgrade-verification.md` — skill-bundle check inverted: `config.allow-plugins` should NOT list `sandermuller/boost-core: true`.
- `phases/bootstrap-skill-bundle.md` — "Common issues" section rewritten: the stub ships with empty `config.allow-plugins`; pre-0.6 `boost-core: true` re-additions flagged as stale.

### Migration

```bash
composer global update sandermuller/repo-init
composer global exec -- boost sync --scope=user --all





```

For existing scaffolded packages, the next audit walk will surface the `sandermuller/package-boost-php: true` entry as MEDIUM-stale. The upgrade phase handles removal correctly — bump first, then drop the entry.

**Full Changelog**: [https://github.com/SanderMuller/repo-init/compare/1.1.0...1.2.0](https://github.com/SanderMuller/repo-init/compare/1.1.0...1.2.0)

## [1.1.0](https://github.com/sandermuller/repo-init/compare/1.0.0...1.1.0) - 2026-05-25

Additive release: a new **MISMATCH-aware** audit protocol for the `composer.json` `scripts` block, applied to every code-bearing audit + upgrade phase plus a central source-of-truth in `references/composer-scripts.md`. No stub churn, no migration steps — agents running prior phase versions still work; this is strict-superset rigor.

### Why

A real-world upgrade run against a downstream `laravel-package` ended with a POSIX-shell `post-install-cmd` (Windows-broken — predates boost-core 0.6's PHP callback) left in place AND no `post-update-cmd` at all. The audit + upgrade phase docs steered the agent through every dev-dep but offered only a one-line pointer at the `scripts` block, so the agent auto-completed the canonical block from training data instead of diffing against `references/composer-scripts.md`. Surfaced by consumer usage feedback.

Root cause is structural: the prior `phases/audit-<category>.md` had a MISSING-only checklist for `composer.json` keys. A `post-install-cmd` that is PRESENT but value-broken survived the audit, because "present" was the only counter-state. **Value drift needs its own verdict.**

### What 1.1.0 ships

#### New protocol — `references/composer-scripts.md`

A `## Audit verification protocol (MANDATORY)` section at top, mirroring the dev-deps one in `shared-dev-deps.md`. Introduces a three-verdict protocol per script key:

- **PRESENT** — key exists, value matches canonical
- **MISSING** — key absent
- **MISMATCH** — key exists, value differs from canonical (quote both sides)

MISMATCH is the load-bearing addition. Audit and upgrade phases now treat MISMATCH at the same severity as MISSING, prompting before overwrite. The common drift class — a `post-install-cmd` whose value is a POSIX-shell conditional referencing `vendor/bin/boost sync` — is now caught explicitly.

#### Per-category audit checklists

New `## Per-category audit checklists` section in the reference doc, listing the exact expected key set per detected category — used as the input to the protocol above. Counts per category (after merging baseline + category-specific blocks):

| Category             | Keys                                  |
|----------------------|---------------------------------------|
| `laravel-package`    | 16 (baseline 11 + workbench 5)        |
| `php-package`        | 12 (baseline 11 + validate-gitattrs)  |
| `composer-plugin`    | 11 (baseline minus sync-ai + validate-gitattrs) |
| `phpstan-extension`  | 11 (baseline)                         |
| `rector-extension`   | 11 (baseline; qa includes @test)      |
| `laravel-project`    | 8 unconditional + 2 scaffold-conditional (BoostAutoSync hooks gated on boost-core in scaffold) |
| `skill-bundle`       | 6 (lean subset; already had its own check)      |

The reference doc is the source of truth — per-key checklists embedded in each audit phase mirror these lists verbatim so the protocol can enforce a per-key verdict without indirection.

#### Per-phase additions

Every code-bearing audit phase gains a `## MISSING composer.json scripts` section with an explicit per-key checklist + a HIGH-severity **POSIX-shell `post-install-cmd` / `post-update-cmd`** NON-CANONICAL finding. Every upgrade phase's `scripts` merge-keys bullet is rewritten to open with `Read references/composer-scripts.md IN FULL before patching. Do NOT infer the canonical block from memory.` MISMATCH is called out as the load-bearing case requiring a prompt before overwrite.

Touched phases:

- `phases/audit-laravel-package.md` + `phases/upgrade-laravel-package.md`
- `phases/audit-php-package.md` + `phases/upgrade-php-package.md`
- `phases/audit-composer-plugin.md` + `phases/upgrade-composer-plugin.md`
- `phases/audit-phpstan-extension.md` + `phases/upgrade-phpstan-extension.md`
- `phases/audit-rector-extension.md` + `phases/upgrade-rector-extension.md`
- `phases/audit-laravel-project.md` + `phases/upgrade-laravel-project.md`

`skill-bundle` already had this check (`audit-skill-bundle.md:63` since pre-1.0); untouched.

#### `laravel-project` nuance

A vanilla `laravel-project` ships `laravel/boost`, not `sandermuller/boost-core`. The canonical `BoostAutoSync::run` callback is therefore not autoloadable there. The `post-install-cmd` / `post-update-cmd` rows in the `laravel-project` audit checklist are **scaffold-conditional** — included only when boost-core is in the dependency tree. If a stale POSIX-shell `post-install-cmd` is present in a boost-core-less `laravel-project`, the canonical fix is REMOVAL of the script, not replacement.

Full changelog at [CHANGELOG.md](https://github.com/SanderMuller/repo-init/blob/1.1.0/CHANGELOG.md).

## [1.0.0](https://github.com/sandermuller/repo-init/compare/0.8.1...1.0.0) - 2026-05-23

**1.0.0 is a stability declaration**, not a feature release. No breaking changes, no scaffold or phase or stub content churn. From this version on `sandermuller/repo-init` follows standard SemVer — breaking changes ship as MAJOR (2.0.0+) only, additive as MINOR, fixes as PATCH. The pre-1.0 cadence (breaking-MINOR allowed, surfaced in `UPGRADING.md` per version pair) is closed; the prior 0.x entries remain in `CHANGELOG.md` + `UPGRADING.md` as history.

### What 1.0.0 ships

Doc reconciliation only — the published archive content is identical to 0.8.1:

- **`README.md`** — Dependencies section restructured into runtime (`require`, just `sandermuller/boost-core`) vs maintenance (`require-dev`, repo-init's own dev tooling explicitly noted as NOT propagated to consumers since 0.8.0 moved `sandermuller/package-boost-php` out of `require`). Uninstall command extended from 3 to all 9 boost-core agent dirs via brace expansion.
- **`UPGRADING.md`** — preamble clarifies the pre-1.0 cadence is historical; 1.0+ follows standard SemVer. New `0.8.x → 1.0.0` section (this one).
- **`RELEASING.md`** — `**Post-1.0** (future)` → `**1.0+**` current state; the breaking-change list clarifies the pre-1.0-vs-post-1.0 severity shift.
- **`CHANGELOG.md`** preamble — same pre-1.0-historical clarification.

### Migration

```bash
composer global update sandermuller/repo-init
composer global exec -- boost sync --scope=user --all







```

No further steps. Scaffold output, the `repo-init` skill, audit/upgrade phases, stubs — all identical to 0.8.1.

### Versioning from here

- **MAJOR** (2.0.0+) — breaking changes: stub-shape changes that require consumers to re-run `audit` + `upgrade`, phase-file step-ordering shifts that could trip an in-flight agent, `references/per-category-deps.yml` schema changes, category removals.
- **MINOR** — additive only: new category, new shared dep added without disturbing existing ones, new audit/upgrade rule that's a strict-superset of prior behaviour.
- **PATCH** — fixes: doc reconciliations, lint cleanups, stub typos, phase-prose corrections, dep-constraint bumps within the umbrella SemVer compatible ranges.

**Full Changelog**: [https://github.com/SanderMuller/repo-init/compare/0.8.1...1.0.0](https://github.com/SanderMuller/repo-init/compare/0.8.1...1.0.0)

## [0.8.1](https://github.com/sandermuller/repo-init/compare/0.8.0...0.8.1) - 2026-05-23

### Fixed

#### `.gitattributes` export-ignore patterns no longer sweep up stub files

repo-init 0.8.0's `.gitattributes` (introduced by the 0.8.0 self-baseline upgrade) used **unanchored** export-ignore patterns: `.editorconfig`, `.github/`, `boost.php`, `pint.json`, `tests/`, `CHANGELOG.md`, `SECURITY.md`, `.lpv`, and so on. Git matches those at **any depth**, not just at repo root — so every identically-named file under `stubs/` was also excluded from `git archive`, and therefore from the Composer archive Packagist serves.

Consumers installing 0.8.0 got an incomplete stub tree:

- `stubs/shared/` shipped **6 of 18** files. Missing from the archive: `.editorconfig`, `.gitignore`, `.github/dependabot.yml`, `.github/workflows/{phpstan,pint-check,rector-check,update-changelog}.yml`, `boost.php`, `CHANGELOG.md`, `SECURITY.md`, `pint.json`, `tests/Feature/.gitkeep`.
- `stubs/php-package/` shipped **5 of 7**. Missing: `.lpv`, `.github/workflows/run-tests.yml`.
- The same pattern affected every stub category with dotfile / workflow / tests sub-content (laravel-package, laravel-package-spatie, filament-plugin, nova-tool, phpstan-extension, rector-extension, composer-plugin, skill-bundle).

A `composer global require sandermuller/repo-init` on 0.8.0 produces an incomplete stub tree; downstream scaffolders (e.g. `sandermuller/repo-new`) break with missing canonical files. Surfaced by repo-new's smoke tests against 0.8.0.

**Fix:** every managed-block pattern in `.gitattributes` now carries a leading `/` so it only matches at repo root, leaving identically-named files under `stubs/` in the archive. Verified — `git archive --worktree-attributes HEAD stubs/` ships **100 of 100** stub files (was 72); root-level exclusions still apply unchanged.

### Upgrading

If you installed 0.8.0:

```bash
composer global update sandermuller/repo-init
composer global exec -- boost sync --scope=user --all








```

The Composer archive for 0.8.1 contains the full stub tree; downstream scaffolders that broke on 0.8.0 work again.

### CI note

`integrity.yml` and `lint-markdown.yml` are path-filtered. This release touches `.gitattributes` only — no path matches — so neither workflow ran on the push. Verified locally instead: full integrity gauntlet (10 scripts) + `check-dep-sync.py` + `markdownlint` (60 files) + `composer validate` all green; `git archive --worktree-attributes HEAD` shows the full 100-file stub tree.

Full changelog at [CHANGELOG.md](https://github.com/SanderMuller/repo-init/blob/0.8.1/CHANGELOG.md).

## [0.8.0](https://github.com/sandermuller/repo-init/compare/0.7.0...0.8.0) - 2026-05-22

0.8.0 aligns repo-init's scaffold + audit/upgrade phases + its own toolchain with the `sandermuller/boost-core` 0.6.0 family migration (boost-core dropped its Composer plugin and is now `type: library`; the umbrella packages bumped with it). Breaking for **new scaffolds** — existing repos surface the drift through `audit-<category>.md` and apply it through `upgrade-<category>.md`.

### Install / update flow changes

`composer global require sandermuller/repo-init` no longer auto-syncs the `repo-init` skill on its own — boost-core 0.6.0 removed the install-time plugin (Pattern C). The sync is now a one-line manual command after every install/update:

```bash
composer global require sandermuller/repo-init
composer global exec -- boost sync --scope=user --all









```

The `composer global exec --` form runs `boost` from Composer's global `vendor/bin/` regardless of the user's current directory; the literal `--` stops Composer from interpreting boost's flags as its own. `--scope=user --all` publishes every globally-installed package's `resources/boost/skills/` into `~/.{agent}/skills/<vendor>__<package>/`. See `references/boost-core-user-scope.md` for the full contract.

### Added

#### `sandermuller/boost-skills ^1.0` for repo-init's own dev workflow

repo-init now uses the shared `sandermuller/boost-skills` library (code-review, bug-fixing, write-spec, evaluate, pre-release, …) as its own dev tooling instead of hand-maintained `.ai/skills/` copies. boost-core syncs the 11 generic skills from the vendor package; the 12 stale local copies are deleted (`.ai/skills/{ai-guidelines,autoresearch,backend-quality,bug-fixing,code-review,codex-review,evaluate,implement-spec,pr-review-feedback,pre-release,write-spec,profile-app}`). `boost.php` gains `->withTags('php', 'github')` so the 4 tagged boost-skills skills (autoresearch, backend-quality, pr-review-feedback, pre-release) sync.

#### `update-changelog.yml` workflow

`CHANGELOG.md` is now auto-maintained: on release publish, `stefanzweifel/changelog-updater-action` prepends the GitHub release body under a new `## [X.Y.Z]` section and updates the compare links. Do not hand-edit `CHANGELOG.md` — drop the entries you want into the release body and the workflow handles the rest. Cut a release with the drafted notes file, not `--generate-notes`:

```bash
gh release create X.Y.Z --notes-file internal/release-notes-X.Y.Z.md









```

repo-init already shipped this workflow as a stub for scaffolded packages (`stubs/shared/.github/workflows/update-changelog.yml`); it now also runs on repo-init itself. `CONTRIBUTING.md` + `RELEASING.md` updated to match.

### Changed (breaking for new scaffolds)

#### Scaffolded composer.json — boost-core 0.6.0 family pins

All 9 scaffold categories now pin against the new family. Tier table:

| Tier | Categories | Old pin | New pin |
|---|---|---|---|
| `skill-bundle` | `skill-bundle` (direct boost-core dep) | `boost-core ^0.5.0` | `boost-core ^0.6.0` |
| package-boost-php | `php-package` / `phpstan-extension` / `rector-extension` / `composer-plugin` | `package-boost-php ^0.5.0` | `package-boost-php ^0.7.0` |
| package-boost-laravel | `laravel-package` / `laravel-package-spatie` / `filament-plugin` / `nova-tool` | `package-boost-laravel ^0.5.0` | `package-boost-laravel ^0.7.0` |

`laravel-project` is unaffected — it uses `laravel/boost`, not `sandermuller/boost-core`.

#### Scaffolded `config.allow-plugins` — drop `sandermuller/boost-core`

boost-core 0.6.0 is `type: library`, no longer a composer-plugin. Every scaffolded `config.allow-plugins` block drops the `sandermuller/boost-core: true` entry. `sandermuller/package-boost-php: true` STAYS — it remains `type: composer-plugin` through 0.7.0+ (it ships its own `package-boost-php:lean` / `:gitattributes` Composer commands). `sandermuller/package-boost-laravel` has always been `type: library` and was never correctly listed in allow-plugins.

The audit phases' allow-plugins rule flipped:

- *Was*: missing `sandermuller/boost-core` in `config.allow-plugins` = HIGH-severity NON-CANONICAL.
- *Now*: present `sandermuller/boost-core` in `config.allow-plugins` = MEDIUM-severity stale entry (Composer ignores it, harmless but unnecessary); missing `sandermuller/package-boost-php` (only) = HIGH-severity.

#### Scaffolded `post-install-cmd` / `post-update-cmd` → `BoostAutoSync::run`

Auto-firing hooks should be silent-on-no-op. boost-core's docblock is explicit: `run()` is for auto-firing hooks (`post-install/update-cmd`); `runWithSummary()` is for user-invoked scripts (`composer sync-ai`) where silence would read as a no-op. Every scaffolded `composer.json` now wires `::run` (not `::runWithSummary`) into the two auto-firing hooks. From boost-core 0.6.0, `run()` prints the one-line sync summary only when `wrote>0` — silent on routine no-op installs, visible on real syncs. Existing repos: `audit-<category>.md` flags a stale `::runWithSummary` in those hooks; `upgrade-<category>.md` replaces with `::run`.

#### `BaseCommandAdapter` citation dropped from composer-plugin phase docs

boost-core 0.6.0 removed its `BaseCommandAdapter` class. `phases/{audit,bootstrap,upgrade}-composer-plugin.md` previously cited it as a reference pattern for plugins shipping Composer commands. That citation is gone — the native pattern stands alone: plugins extend `Composer\Command\BaseCommand` directly. The adapter idiom solved boost-core's standalone-bin + plugin dual-surface problem specifically; it is not a general fix path.

#### `composer boost:*` plugin commands → `vendor/bin/boost <cmd>`

The `composer boost:install` / `composer boost:sync` plugin commands are gone with boost-core 0.6.0. Use the standalone bin:

```bash
# In a project (cwd is the package, vendor/ present):
vendor/bin/boost install        # was: composer boost:install
vendor/bin/boost sync           # was: composer boost:sync

# After `composer global require` (any cwd):
composer global exec -- boost sync --scope=user --all   # new: global skill refresh









```

`stubs/shared/boost.php` + repo-init's own `boost.php` docblocks updated accordingly.

#### repo-init aligned to its own `skill-bundle` baseline

repo-init's own repo now matches the canonical baseline it scaffolds for `skill-bundle` packages: `boost-core` directly in `require` (`^0.6.0`), `package-boost-php` / `pint` / `lean-package-validator` / `boost-skills` in `require-dev`, `.editorconfig` + `.gitattributes` + `.lpv` + `pint.json` + `.github/dependabot.yml` + `.github/workflows/pint-check.yml` added. `orchestra/testbench` dropped from `require` — superseded by the v7 global-install model (SPEC §538). `composer.lock` continues to be gitignored (`type: library`).

#### SPEC.md reconciled with the v7 global-install architecture

§2 composer.json example, §204 prose, §5.4 scripts block, and RQ11 / RQ12 / RQ28 / RQ35 carry "Superseded (v7)" notes alongside the original decisions — history preserved, current state explicit.

### Fixed

#### Documentation: post-global-install sync command path

The new install/update flow originally documented `vendor/bin/boost sync --scope=user --all` immediately after `composer global require/update`. After a global require the shell stays in the user's current cwd — not the Composer global vendor dir — so `vendor/bin/boost` resolves to no file there. Switched every post-global-install invocation to `composer global exec -- boost sync --scope=user --all` (README, UPGRADING, SPEC, `references/boost-core-user-scope.md`). Project-local `vendor/bin/boost install` / `sync` references kept where the cwd genuinely is a Composer package.

#### `laravel-project` scaffold AI-tooling section

(0.7.0 follow-up — `stubs/laravel-project/README.append.md` already corrected to `laravel/boost` in 0.7.0; called out here for completeness — see 0.7.0 changelog.)

### Migration notes

Upgrade repo-init itself:

```bash
composer global update sandermuller/repo-init
composer global exec -- boost sync --scope=user --all









```

For an existing scaffolded repo:

1. `audit-<category>.md` surfaces the family drift: stale `boost-core` in `allow-plugins`, `::runWithSummary` in `post-install/update-cmd`, old boost-family constraints, stale `BaseCommandAdapter` citations (composer-plugin only).
2. `upgrade-<category>.md` applies the fix on confirmation.

`composer install` for a freshly-scaffolded repo on the new family floor requires `--no-plugins` for the *transition update* if the lockfile still pins pre-0.6.0 boost-core (which is a plugin needing allow-listing that the new composer.json no longer grants). After the update, allow-plugins is correctly empty for boost-core and normal `composer install` works.

`laravel-project` is unaffected — it uses `laravel/boost`, not `sandermuller/boost-core`.

**Full Changelog**: [https://github.com/SanderMuller/repo-init/compare/0.7.0...0.8.0](https://github.com/SanderMuller/repo-init/compare/0.7.0...0.8.0)

## [0.7.0](https://github.com/sandermuller/repo-init/compare/0.6.0...0.7.0) - 2026-05-21

### Added

- **`sandermuller/boost-skills` scaffolded by default + an interactive
  skill-tag picker.** Every newly bootstrapped package now ships
  `sandermuller/boost-skills` (the shared dev-workflow skill library —
  code-review, bug-fixing, write-spec, evaluate, …) as a `require-dev`
  dependency and a `withAllowedVendors()` entry in the generated `boost.php`.
  Bootstrap gained an interactive step: the user is walked through which
  `boost-skills` tags to activate — `php`, `frontend`, `github`, `jira` —
  written into `boost.php` as `->withTags(...)`. Picking none still yields the
  universal boost-skills skills; each tag adds its capability-specific set
  (`php` → backend-quality / pre-release, `jira` → the jira-* skills, …). A new
  `__SKILL_TAGS__` placeholder carries the chosen tags into the stub. Wired
  through `stubs/shared/boost.php`, the 9 stub `composer.json` files,
  `references/{placeholder-rules,per-category-deps.md,per-category-deps.yml,shared-dev-deps}.md`,
  the `repo-init` skill's knob list, the audit phases, and `check-placeholders.sh`.
  `laravel-project` is excluded — it uses `laravel/boost`, not
  `sandermuller/boost-core`, so boost-skills would not sync there.
- **`shared-stub-skip` key in `per-category-deps.yml`.** A per-category
  denylist of `stubs/shared/` files a category does not plain-copy when it
  overlays the shared stub tree — the machine-readable parallel of the skip
  prose already in the bootstrap phases. Lets a CLI scaffolder honour the
  skips from one source of truth instead of re-deriving them. Entries are
  stub-relative and PRE-rename (`_gitattributes`, not `.gitattributes`); a
  trailing `/` marks a directory. Populated for `laravel-project` (Laravel
  ships its own equivalents; `boost.php` is boost-core-only) and
  `skill-bundle` (no PHP toolchain). Documented in
  `references/per-category-deps.md`.

### Changed

- **Scaffold stubs bumped to the boost 0.5.0 family.** The 9 stub
  `composer.json` files move `sandermuller/package-boost-php` /
  `sandermuller/package-boost-laravel` `^0.4.0 → ^0.5.0` (umbrella categories)
  and `sandermuller/boost-core` `^0.4.0 → ^0.5.0` (`skill-bundle`, direct dep).
  boost-core 0.5.0 is the floor for the `withTags()` API the skill-tag picker
  emits.

### Fixed

- **`stubs/laravel-project/README.append.md` AI-tooling section.** It still
  described the boost-core toolchain (`package-boost-php`, `vendor/bin/boost sync`,
  `boost.php` auto-sync) — stale since the 0.5.0 boost-family remap moved
  `laravel-project` onto `laravel/boost`. Rewritten to describe `laravel/boost`:
  `php artisan boost:install` / `boost:update`, `boost.json`, composer.json-detected
  skills.

## [0.6.0](https://github.com/sandermuller/repo-init/compare/0.5.0...0.6.0) - 2026-05-20

### Added

- **`boost.php` scaffolded by default.** Every newly bootstrapped package now
  ships a `boost.php` — boost-core's configuration file — pinning the AI agent
  set to Claude Code, Copilot, and Codex (`Agent::CLAUDE_CODE`, `Agent::COPILOT`,
  `Agent::CODEX`). Without it boost-core's agent selection is implicit; the
  pinned config makes a fresh scaffold's `composer boost:sync` deterministic.
  Ships as `stubs/shared/boost.php` (no placeholders — category-agnostic) and is
  copied by every package category. `laravel-project` is the one exclusion — it
  uses `laravel/boost`, not `sandermuller/boost-core`, so a `boost.php` there
  would be inert. `boost.php` is `export-ignore`d (dev config — kept out of the
  published Composer archive): entry added to `stubs/shared/_gitattributes`, the
  4 Laravel-family `_gitattributes` overrides, the `php-package` + `skill-bundle`
  `.lpv` files, and `references/gitattributes-managed-block.md`. All six
  package-category audit phases now flag a missing `boost.php` — the line was
  added to four; `phpstan-extension` / `rector-extension` inherit it via their
  "same list as audit-laravel-package.md" reference. Upgrade phases copy it via
  the generic MISSING-file path.

## [0.5.0](https://github.com/sandermuller/repo-init/compare/0.4.0...0.5.0) - 2026-05-20

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
  
## [0.4.0](https://github.com/sandermuller/repo-init/compare/0.3.1...0.4.0) - 2026-05-20

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

## [0.3.1](https://github.com/sandermuller/repo-init/compare/0.3.0...0.3.1) - 2026-05-18

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

## [0.3.0](https://github.com/sandermuller/repo-init/compare/0.2.14...0.3.0) - 2026-05-18

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

## [0.2.14](https://github.com/sandermuller/repo-init/compare/0.2.13...0.2.14) - 2026-05-17

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

## [0.2.13](https://github.com/sandermuller/repo-init/compare/0.2.12...0.2.13) - 2026-05-17

### Fixed

- **`stubs/php-package/.lpv`**: line 13 was a duplicate of line 12
  (`phpunit.xml export-ignore` listed twice). Surfaced via php-x402 upgrade
  dogfood where the sub-agent had to hand-write `.lpv` instead of copying
  the stub. Lean-package-validator would warn on the duplicate.

## [0.2.12](https://github.com/sandermuller/repo-init/compare/0.2.11...0.2.12) - 2026-05-17

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

## [0.2.11](https://github.com/sandermuller/repo-init/compare/0.2.10...0.2.11) - 2026-05-17

### Fixed

- **sander-variant ServiceProvider stub missing `#[Override]`**: same N2c
  miss as 0.2.10's spatie + workbench fix.
  `stubs/laravel-package/src/__PACKAGE_STUDLY__ServiceProvider.php`
  `register()` now ships with `use Override; #[Override]` so
  `rector --dry-run` exits 0 on fresh `--variant=sander` scaffolds. nova-tool
  and filament-plugin SP stubs intentionally unchanged: their `boot()` /
  custom-signature `register()` aren't overrides of the parent ServiceProvider.

## [0.2.10](https://github.com/sandermuller/repo-init/compare/0.2.9...0.2.10) - 2026-05-17

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

## [0.2.9](https://github.com/sandermuller/repo-init/compare/0.2.8...0.2.9) - 2026-05-17

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

## [0.2.8](https://github.com/sandermuller/repo-init/compare/0.2.7...0.2.8) - 2026-05-17

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

## [0.2.7](https://github.com/sandermuller/repo-init/compare/0.2.6...0.2.7) - 2026-05-17

### Fixed

- `stubs/{laravel-package, laravel-package-spatie, filament-plugin, nova-tool}/rector.php` — `withSets([...])` block mixed `LaravelSetList`
  and `PestSetList` entries; earlier conditional-wrap missed this 7-entry
  variant. Now: `array_merge([laravel-sets], class_exists(PestSetList) ? [pest-sets] : [])` so phpunit-only scaffolds don't fatal on
  `Class "PestSetList" not found`.

## [0.2.6](https://github.com/sandermuller/repo-init/compare/0.2.5...0.2.6) - 2026-05-17

### Fixed

- `__TEST_RUNNER__` + `__TEST_COVERAGE_FLAG__` placeholders added to 5
  stub `composer.json` scripts (`laravel-package`,
  `laravel-package-spatie`, `filament-plugin`, `nova-tool`, `php-package`).
  Previously hardcoded `vendor/bin/pest` or `vendor/bin/phpunit`, so the
  chosen `--test-framework` was only half-applied. `phpstan-extension` +
  `rector-extension` remain phpunit-hardcoded by spec.

## [0.2.5](https://github.com/sandermuller/repo-init/compare/0.2.4...0.2.5) - 2026-05-17

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

## [0.2.4](https://github.com/sandermuller/repo-init/compare/0.2.3...0.2.4) - 2026-05-17

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

## [0.2.3](https://github.com/sandermuller/repo-init/compare/0.2.2...0.2.3) - 2026-05-17

Dogfooded via `sandermuller/repo-new` CLI scaffolding both a fictional `php-package` AND `laravel-project`. Two real data bugs surfaced in `per-category-deps.yml`:

### Fixed

- **`pestphp/pest-plugin-laravel` constraint** bumped to `^4.1` (only ^4.1+ supports Laravel 13). Previously unconstrained → resolved to old versions incompatible with Laravel 13's `^13.x` framework.
- **`laravel-project` mandatory `require-dev` documentation** explicitly notes that CLI implementations MUST filter or move packages Laravel already shipped. Laravel 13+ ships `laravel/tinker` in `require` historically (was `require-dev`); a blanket `composer require --dev` errors with "currently present in the require key". The fix is two-step: `composer remove --no-update <pkg>` then `composer require --dev <list>` so packages end up in the right scope. Documented inline in per-category-deps.yml.

## [0.2.2](https://github.com/sandermuller/repo-init/compare/0.2.1...0.2.2) - 2026-05-17

### Fixed

- **`run-tests.yml` watches the right PHPUnit config file.** All 7 category stubs (`stubs/<cat>/.github/workflows/run-tests.yml`) had path filter watching `phpunit.xml`, but scaffold ships `phpunit.xml`. Result: PHPUnit config changes in generated repos wouldn't trigger CI. Fixed across `php-package`, `laravel-package`, `laravel-package-spatie`, `phpstan-extension`, `rector-extension`, `filament-plugin`, `nova-tool`. Surfaced by codex post-fix review of 0.2.1.

## [0.2.1](https://github.com/sandermuller/repo-init/compare/0.2.0...0.2.1) - 2026-05-17

Dogfood-surfaced bug fixes from scaffolding sandermuller/repo-new via the agent path.

### Fixed

- **`stubs/shared/.gitattributes` slimmed to validator-passing set.** The previous shipped file listed entries for files that don't always exist post-scaffold (e.g. `.ai/`, `.cursorrules`, `.windsurfrules`, `testbench.yaml`, `workbench/`, `phpunit.xml`, `CHANGELOG.md`). `stolt/lean-package-validator` inspects the working tree and flagged the mismatch as invalid. Slimmed to the validator-approved set: only files that always exist after scaffold + `package-boost:sync`. Category-specific extras (`testbench.yaml`, `workbench/`) moved to per-category `.gitattributes` overrides for `laravel-package`, `laravel-package-spatie`, `filament-plugin`, `nova-tool`.
- **Idempotency precondition wording for renamed-on-substitution stubs.** `bootstrap-php-package.md` step 3 + `bootstrap-laravel-package.md` step 4 now explicitly tell the agent to derive the SUBSTITUTED target filename FIRST (e.g. `src/RepoNew.php`) before checking existence, not check the literal stub filename (e.g. `src/__PACKAGE_STUDLY__.php`). Without this clarification, re-runs would re-copy + re-substitute renamed stubs incorrectly.

### Why these bugs existed

Both surfaced during the dogfood scaffold of `sandermuller/repo-new` (a future package whose CLI is designed in `specs/repo-new-cli.md`). The validator bug existed because the shipped `.gitattributes` was max-everything (covering all categories' file sets). The idempotency wording bug was a subtle slip in the v0.2 rework — the spec was correct in intent but the implementation hint was missing.

## [0.2.0](https://github.com/sandermuller/repo-init/compare/0.1.0...0.2.0) - 2026-05-17

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

## [0.1.0](https://github.com/sandermuller/repo-init/releases/tag/0.1.0) - 2026-05-17

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
