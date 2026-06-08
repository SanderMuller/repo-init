# Upgrading

Per-major / per-minor upgrade notes for `sandermuller/repo-init`. Each section is anchored so release notes can deep-link to the relevant breaking-change explanation.

## From 0.x to 0.x (pre-1.0 cadence — historical)

Pre-`1.0.0` releases (0.1.0 through 0.8.x) introduced breaking changes in MINOR bumps; each is documented in the CHANGELOG and the per-version-pair sections below. From 1.0.0 onward repo-init follows standard SemVer: breaking changes ship as MAJOR only, additive as MINOR, fixes as PATCH.

To upgrade:

```bash
composer global update sandermuller/repo-init
```

The `post-update-cmd` hook re-syncs the skill into `~/.claude/skills/sandermuller__repo-init/`. If a stub or reference doc shape changed in a way that affects in-flight workflows, re-running `audit` on already-set-up repos will surface the new MISSING / NON-CANONICAL findings.

> **From 0.8.0 onward** there is no install-time auto-sync — boost-core 0.6.0 removed the Composer plugin. After every `composer global update sandermuller/repo-init`, run `composer global exec -- boost sync --scope=user --all` to refresh the user-scope skill dirs. See the `0.7.x → 0.8.0` section below.

---

## 1.5.1 → 1.6.0 (boost family `1.x` adoption)

Additive — no breaking change to repo-init itself. `composer global update sandermuller/repo-init` (+ `composer global exec -- boost sync --scope=user --all`) and you are on 1.6.0.

The boost family reached its stable `1.x` line, and repo-init's scaffold / recommended floors move onto it. The bump is mechanical: boost-core 1.0.0 is a drop-in over 0.23.3 (the SemVer freeze, no API change), package-boost-php 1.0.0 only narrows its boost-core requirement to `^1.0`, and package-boost-laravel 1.0.0 froze its surface. **No code migration** — the `boost.php` authoring API, the `AutoSync` façade hooks, and the CLI contract are all unchanged.

- **Canonical boost floors raised to `1.x`:**
  - `sandermuller/boost-core: ^1.1` — skill-bundle's direct `require` and repo-init itself (`^1.1` picks up the `laravel/boost` coexistence advisories added in boost-core 1.1; `.config/boost.php` still needs ≥ 0.18, satisfied).
  - `sandermuller/package-boost-php: ^1.0` — the framework-agnostic categories' umbrella (`php-package`, `phpstan-extension`, `rector-extension`, `composer-plugin`).
  - `sandermuller/package-boost-laravel: ^1.0` — the Laravel categories' umbrella (`laravel-package` + `laravel-package-spatie`, `filament-plugin`, `nova-tool`).
  - `sandermuller/boost-skills: ^2.0.0` in the scaffolded stubs, aligning them with repo-init's own dev floor (they previously trailed at `^1.9.0`).
- **package-boost-laravel 1.0.0 removed dead scaffolding** — its (empty) service provider, config file, config key, publish tag, and `extra.laravel.providers` discovery entry, and it moved `illuminate/*` to `require-dev`. **Impact: none for normal use** — repo-init's Laravel scaffolds never registered the provider or read the config, and the package now installs cleanly as a dev tool regardless of the consumer's Laravel major.

**The one hand-edit the bump requires — `withTags()` array form.** boost-core 0.20 changed every `BoostConfig` builder method to take a single `array`; `withTags()` was the last variadic one. A package whose previous floor was below boost-core 0.20 (the pre-1.6.0 repo-init floor was `^0.19.0`) has a `boost.php` / `.config/boost.php` with a variadic call:

```php
// before (variadic — throws once boost-core >= 0.20 loads the config)
->withTags(Tag::Php, Tag::Github)
// after
->withTags([Tag::Php, Tag::Github])
```

`boost sync` cannot auto-migrate it (loading the config executes the call first), so it is a manual edit. On boost-core ≥ 0.23 the error is a clear, catchable `InvalidBoostConfigException` with a migration hint; on 0.20–0.22 it is a raw `TypeError`. `audit-<category>` flags a variadic call; `upgrade-<category>` makes the edit.

Re-auditing a pre-1.6.0 scaffold flags the old floors through the same floor-coupling path as before (`audit-<category>` → `upgrade-<category>`); the upgrade bumps them.

Not breaking: a package on the previous `0.x` floors keeps working; the new floors only constrain freshly scaffolded or upgraded repos.

---

## 1.5.0 → 1.5.1

Additive — no breaking change to repo-init itself. `composer global update sandermuller/repo-init` (+ `composer global exec -- boost sync --scope=user --all`) and you are on 1.5.1.

Three refinements:

- **Firmer `minimum-stability` audit guidance.** `stable` is now stated as the **default expectation** at every release; a looser `minimum-stability` (`dev` + `prefer-stable: true`) is a *justified exception*, not a free pass — legitimate only while a package is actively co-developed against UNRELEASED sibling packages. Being on `0.x` is **not** by itself a justification, and a package with downstream / production dependents should lean `stable` (the finding escalates to MEDIUM severity there). The default recommendation is to tighten to `stable`.
- **Canonical boost floors raised.** The scaffolded / recommended floors moved to `sandermuller/boost-core: ^0.19.0` (skill-bundle's direct require + repo-init itself) and `sandermuller/package-boost-php: ^0.17.0` (the framework-agnostic categories' umbrella). `package-boost-php` 0.17 requires `boost-core ^0.18||^0.19`, so the `.config/` layout (which needs boost-core ≥ 0.18) stays satisfied transitively. `package-boost-laravel` is unchanged (`^0.10.0`). Re-auditing a pre-1.5.1 scaffold flags the old floor; the matching `upgrade-<category>` bumps it.
- **Internal cleanup.** Removed repo-init's own orphaned root `.lpv` (a leftover of the long-removed, structurally-incompatible lpv gate) — no consumer-facing effect.

Not breaking: a package on the previous floors keeps working; `minimum-stability: stable` repos are unaffected.

---

## 1.4.x → 1.5.0 (`.config/boost.php` canonical layout)

Additive — no breaking change to repo-init itself. `composer global update sandermuller/repo-init` (+ `composer global exec -- boost sync --scope=user --all`) and you are on 1.5.0.

boost-core 0.17 added `.config/boost.php` as an alternative config location and 0.18 moved the gitignored sync manifest to `.config/boost/` under that layout. From 1.5.0, repo-init scaffolds the **`.config/` layout as canonical**: bootstrap writes `.config/boost.php` (not a root `boost.php`), audit flags a legacy root `boost.php` as drift, and upgrade migrates it. The boost-core floor moved to `^0.18.0` (repo-init itself + the `skill-bundle` stub's direct require; the other categories get it transitively through `package-boost-php` ≥ 0.16.2 / `package-boost-laravel`, which already permit it).

### Re-auditing repos set up before 1.5.0

Running `audit` on an older scaffold flags two new NON-CANONICAL findings:

- **Legacy root `boost.php`** (MEDIUM, drift) — boost-core still reads it, but `.config/boost.php` is canonical. `upgrade-<category>` migrates it: it **moves** (never copies) `boost.php → .config/boost.php`, ensures boost-core ≥ 0.18, and runs `vendor/bin/boost sync` (which auto-migrates the manifest `.boost/ → .config/boost/` and rewrites the managed `.gitignore` / `.gitattributes` blocks).
- **Both `.config/boost.php` AND root `boost.php` present** (HIGH, urgent) — two configs is a hard error in boost-core ≥ 0.17 (`AmbiguousBoostConfigException`); any `boost` command throws. Fix: remove the root copy, keep `.config/boost.php`.

The dist-exclusion entry in the `.gitattributes` managed block changed from `boost.php export-ignore` to `.config/ export-ignore` (one whole-dir entry covering both `.config/boost.php` and the gitignored `.config/boost/`). It is a preserved foreign line — `boost sync` keeps it. `.lpv` files swap their `boost.php` glob for `.config/`.

Unchanged: `laravel-project` still has no boost-core config (it uses `laravel/boost`). Not breaking — a root `boost.php` keeps working; this only changes where repo-init *puts* it and what audit prefers.

---

## 1.3.x → 1.4.0 (one-package-install façade)

Additive — no breaking change to repo-init itself. `composer global update sandermuller/repo-init` (+ `composer global exec -- boost sync --scope=user --all`) and you are on 1.4.0.

Scaffolds and the audit/upgrade phases now wire the boost auto-sync hook through each wrapper's own namespace façade instead of boost-core's transitive `BoostAutoSync` class — so a scaffolded package references only a class from its direct dependency and consumers require one boost package, not two.

### Re-auditing repos set up before 1.4.0

Running `audit` on an older scaffold now flags its `post-install-cmd` / `post-update-cmd` as NON-CANONICAL (they name `SanderMuller\BoostCore\Scripts\BoostAutoSync::run`; the new canonical is the per-category wrapper façade):

| Category | New canonical callback | `require-dev` floor |
|---|---|---|
| php-package, composer-plugin, rector-extension, phpstan-extension | `SanderMuller\PackageBoostPhp\Scripts\AutoSync::run` | `sandermuller/package-boost-php: ^0.16.0` |
| laravel-package (+ spatie / filament-plugin / nova-tool) | `SanderMuller\PackageBoostLaravel\Scripts\AutoSync::run` | `sandermuller/package-boost-laravel: ^0.10.0` |

**Atomic rule:** the upgrade swaps the callback AND bumps the wrapper floor in the same change. A façade callback paired with a pre-façade floor references a class that isn't autoloadable, and Composer silently skips the hook (autosync stops) rather than failing loudly. The `upgrade-<category>` phases handle this automatically.

Unchanged: `skill-bundle` keeps `BoostAutoSync::run` (it depends on `boost-core` directly); `laravel-project` keeps its `@php artisan project-boost:sync` hook. Requires the wrapper packages at their façade-introducing releases (`package-boost-php` 0.16.0+, `package-boost-laravel` 0.10.0+).

---

## 0.8.x → 1.0.0

Stability declaration — no content changes, no breaking changes, no migration steps. `composer global update sandermuller/repo-init` (+ `composer global exec -- boost sync --scope=user --all` per the post-0.8.0 install flow) and you are on 1.0.0.

What 1.0.0 changes:

- **Versioning contract.** Repo-init follows standard SemVer from here: breaking changes ship as **MAJOR** (2.0.0+) only, additive as MINOR, fixes as PATCH. The pre-1.0 cadence (breaking-MINOR allowed, surfaced per pair in this file) is closed; the historical entries below remain for users coming from 0.x.
- **Nothing in the published archive.** Scaffold output, audit phases, stubs, references, the `repo-init` skill — identical to 0.8.1.

---

## 0.7.x → 0.8.0 (boost-core 0.6.0 alignment)

(Version provisional — final tag chosen at release time.)

boost-core 0.6.0 (BREAKING) removed its Composer plugin and is now `type: library`. repo-init's scaffold + audit/upgrade phases re-align across the family. Upgrade repo-init itself:

```bash
composer global update sandermuller/repo-init
composer global exec -- boost sync --scope=user --all
```

The second command is new and required after every global update: boost-core 0.6 removed the install-time auto-sync. `composer global exec -- boost sync --scope=user --all` runs boost from Composer's global `vendor/bin/` (regardless of your current directory) and publishes every globally-installed package's `resources/boost/skills/` into the user-scope agent dirs (`~/.{agent}/skills/<vendor>__<package>/`).

### Scaffold constraint bumps

| Category | Old pin | New pin |
|---|---|---|
| `skill-bundle` (direct `boost-core`) | `^0.5.0` | `^0.6.0` |
| `php-package` / `phpstan-extension` / `rector-extension` / `composer-plugin` | `package-boost-php ^0.5.0` | `package-boost-php ^0.7.0` |
| `laravel-package` / `laravel-package-spatie` / `filament-plugin` / `nova-tool` | `package-boost-laravel ^0.5.0` | `package-boost-laravel ^0.7.0` (0.7.0 is the `boost-core ^0.6` release; pbl is `type: library` — it never had an `allow-plugins` entry to remove) |

`laravel-project` is unaffected — it uses `laravel/boost`, not `sandermuller/boost-core`.

### `config.allow-plugins` — drop `sandermuller/boost-core`

boost-core 0.6.0 is `type: library`, no longer a composer-plugin. The `sandermuller/boost-core: true` allow-plugins entry is unnecessary — Composer ignores it; harmless but stale. `audit-<category>.md` flags it; `upgrade-<category>.md` removes it on confirmation. `sandermuller/package-boost-php` stays in `allow-plugins` — it remains `type: composer-plugin` through 0.7.0+.

### `post-install-cmd` / `post-update-cmd` switch to `BoostAutoSync::run`

Auto-firing hooks should be silent-by-default. `::runWithSummary` was wrong for these hooks (always printed a sync summary on `composer install` — noise on routine no-op installs). The canonical wiring is now:

- `post-install-cmd` / `post-update-cmd` → `BoostAutoSync::run`
- User-invoked scripts (e.g. `composer sync-ai`) — `::runWithSummary` stays correct there, where silence would read as a no-op.

From boost-core 0.6.0, `run()` prints the one-line sync summary only when `wrote>0` (silent on routine no-op installs, visible on real syncs). `audit-<category>.md` flags a stale `::runWithSummary` in those two hooks; `upgrade-<category>.md` replaces with `::run`.

### `BaseCommandAdapter` removed (composer-plugin authors only)

boost-core 0.6.0 removed its `BaseCommandAdapter` class. The composer-plugin phase docs previously cited it as a reference pattern; that citation is dropped. Plugins shipping Composer commands should extend `Composer\Command\BaseCommand` directly — the native parent. The adapter idiom solved a dual-surface problem (plugin + standalone bin) specific to boost-core and is not a general fix path.

### `composer boost:*` commands gone

The `composer boost:install` / `composer boost:sync` plugin commands are gone. Use the standalone bin instead:

```bash
# In a project (cwd is the package, vendor/ present):
vendor/bin/boost install        # was: composer boost:install
vendor/bin/boost sync           # was: composer boost:sync

# After `composer global require` (any cwd — runs from Composer's global vendor/bin):
composer global exec -- boost sync --scope=user --all   # new: global skill refresh
```

---

## 0.6.x → 0.7.0

0.7.0 changes what repo-init scaffolds — new packages ship `sandermuller/boost-skills` and a tag-configured `boost.php`. Upgrade repo-init itself:

```bash
composer global update sandermuller/repo-init
```

### New: boost-skills + the skill-tag picker

A newly bootstrapped package now gets `sandermuller/boost-skills` (in `require-dev` and the `boost.php` `withAllowedVendors()`), and the bootstrap flow interactively prompts for which skill tags to activate (`php` / `frontend` / `github` / `jira`) — written into `boost.php` as `->withTags(...)`. For a package scaffolded before 0.7.0, `audit-<category>.md` flags `sandermuller/boost-skills` as MISSING and `upgrade-<category>.md` installs it; the tag set is then a manual `boost.php` edit or a `vendor/bin/boost install` re-run. Not breaking.

### Stub constraints → boost 0.5.0 family

Scaffold stubs now pin `sandermuller/package-boost-php` / `sandermuller/package-boost-laravel` at `^0.5.0` (and `skill-bundle`'s direct `sandermuller/boost-core` at `^0.5.0`). boost-core 0.5.0 is required for the `withTags()` API. Existing repos: `audit` surfaces the constraint drift, `upgrade` applies it.

`laravel-project` gets none of this — it uses `laravel/boost`, not `sandermuller/boost-core`.

### New: `shared-stub-skip` key in `per-category-deps.yml`

`references/per-category-deps.yml` gained a `shared-stub-skip` key — a per-category denylist of `stubs/shared/` files a category does not plain-copy. Nothing to do: it does not change what repo-init scaffolds; it only exposes the existing skip behaviour in a machine-readable form for CLI tooling built on `per-category-deps.yml`.

---

## 0.5.x → 0.6.0

0.6.0 adds one file to what repo-init scaffolds. Upgrade repo-init itself the usual way:

```bash
composer global update sandermuller/repo-init
```

### New: `boost.php` scaffolded by default

Newly bootstrapped packages now ship a `boost.php` — boost-core's config — pinning the AI agent set to Claude Code, Copilot, and Codex. For a package scaffolded before 0.6.0, `audit-<category>.md` flags `boost.php` as MISSING and `upgrade-<category>.md` adds it (with the matching `export-ignore` entry in the `.gitattributes` managed block + `.lpv`). Not breaking — boost-core works without `boost.php` (agent selection is just implicit); the file only makes the agent set explicit and deterministic. `laravel-project` does **not** get a `boost.php` — it uses `laravel/boost`, not `sandermuller/boost-core`.

---

## 0.4.x → 0.5.0

0.5.0 changes what repo-init **scaffolds** — the stub `composer.json` files and the per-category dependency map. Upgrading repo-init itself is the usual one-liner:

```bash
composer global update sandermuller/repo-init
```

### If you have a repo scaffolded by repo-init < 0.5.0

Run `audit-<category>.md` then `upgrade-<category>.md` against it. Two findings will surface:

- **Blocking — `config.allow-plugins` missing the boost plugins.** Pre-0.5.0 stubs shipped a `composer.json` that requires a boost umbrella but never allow-listed `sandermuller/boost-core` (a `composer-plugin` pulled in transitively). The result: `composer install --no-interaction` aborts with "blocked by your allow-plugins config". The upgrade phase adds `sandermuller/boost-core` + `sandermuller/package-boost-php` to `config.allow-plugins`. **This is the highest-priority fix** — apply it even if you skip everything else.
- **`post-install-cmd` modernization.** The old POSIX-shell `post-install-cmd` (`if [ "$COMPOSER_DEV_MODE" = "1" ]; then ...`) is Windows-broken. The upgrade phase replaces it with boost-core's `BoostAutoSync::run` callback and adds the missing `post-update-cmd`. (`::run` not `::runWithSummary` — auto-firing hooks should be silent-on-no-op; `::runWithSummary` is for user-invoked scripts. See the `0.7.x → 0.8.0` section.)

### Boost-family dependency remap (BREAKING for new scaffolds)

The boost umbrella is no longer a single shared dev-dep. It is now assigned per category:

| Category | Boost-family dep |
|---|---|
| `php-package`, `phpstan-extension`, `rector-extension`, `composer-plugin` | `sandermuller/package-boost-php` |
| `laravel-package`, `filament-plugin`, `nova-tool` | `sandermuller/package-boost-laravel` |
| `laravel-project` | `laravel/boost` (Laravel's own AI tooling) |
| `skill-bundle` | `sandermuller/boost-core` directly, in runtime `require` |

Existing repos are not force-migrated — audit surfaces the drift; upgrade applies it on confirmation. A `laravel-package` previously carrying `sandermuller/package-boost-php` is migrated to `sandermuller/package-boost-laravel`.

### New `skill-bundle` category

0.5.0 adds a 7th category for distributable packages whose product is AI agent skills (`type: library`, `sandermuller/boost-core` in runtime `require`, ships `resources/boost/skills/`, no `src/`). It has its own bootstrap / audit / upgrade phases. Existing categories are unaffected.

---

## 0.3.x → 0.4.0

**Breaking (user-scope skill path).** `sandermuller/package-boost-php` was bumped to `^0.4.0`, which pulls `sandermuller/boost-core 0.4.0` transitively. boost-core 0.4.0 changes where user-scope skills land:

- **Before:** `~/.{agent}/skills/repo-init/` (bare package basename)
- **After:** `~/.{agent}/skills/sandermuller__repo-init/` (full `vendor__package` slug — `/` replaced by `__`, a sequence the Composer name spec forbids, so distinct packages never collide)

To upgrade:

```bash
composer global update sandermuller/repo-init
```

On the first sync after the upgrade, boost-core's `UserScopeMigrator` performs a **one-time, ownership-checked rename** of the legacy `~/.{agent}/skills/repo-init/` dir to `~/.{agent}/skills/sandermuller__repo-init/` for every enabled agent. It runs only when the legacy dir's contents are provably reproducible from this package's `resources/boost/skills/` tree — if a foreign file is present (a pre-0.2 basename collision with another package), the rename is skipped and the legacy dir is left for manual cleanup.

**What you must do:** nothing in the common case — the migration is automatic. Two exceptions:

- **Hard-coded paths.** If you have scripts, dotfiles, or docs that reference `~/.{agent}/skills/repo-init/` directly, update them to `~/.{agent}/skills/sandermuller__repo-init/`.
- **Pre-0.2 collision state.** If the auto-migration left a legacy `~/.{agent}/skills/repo-init/` dir in place, inspect it, copy any wanted files into `~/.{agent}/skills/sandermuller__repo-init/`, then `rm -rf ~/.{agent}/skills/repo-init/`.

Project-scope `.claude/skills/<skill>/` paths are **unaffected** — the `__` namespacing applies to user-scope (`$HOME`) sync only.

---

## 0.1.0 → 0.x

(No upgrades yet — 0.1.0 is the initial release.)

When 0.2.0 ships, this section gains breaking-change details and migration steps.

---

## Common upgrade patterns

### Stub shape changed

If a stub gained a new key/file/script in a newer repo-init version:

- Run `audit-<category>.md` on each affected target. The audit picks up the new expectation as MISSING.
- Run `upgrade-<category>.md` to apply.

No manual migration needed unless the upgrade is irreversible (e.g. a stub file was REMOVED — see the relevant release section).

### Reference doc renamed / removed

If a phase file referenced an old reference doc that's been removed:

- `audit` may emit "missing reference: …" warnings.
- Upgrade to the matching repo-init MINOR/MAJOR to get the new reference docs.

### Composer.json schema changed

If `composer.json` `extra.repo-init.*` keys are introduced or restructured (none currently, but reserved for v0.2+):

- Schema migration documented in this file per release.

### Skill propagation breakage

If `package-boost` is bumped to a major that changes its propagation contract:

- repo-init's `composer.json` `require` pins the compatible `package-boost` major range.
- On `composer global update`, the new package-boost is pulled in; the `post-update-cmd` hook re-syncs.
- If the user has a project-local install pinned to an older `package-boost`, the project-local install shadows the global one (per SPEC §3.4) — re-run `composer require --dev sandermuller/repo-init` in that project to refresh.
