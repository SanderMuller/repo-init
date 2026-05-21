# Upgrading

Per-major / per-minor upgrade notes for `sandermuller/repo-init`. Each section is anchored so release notes can deep-link to the relevant breaking-change explanation.

## From 0.x to 0.x (pre-1.0 cadence)

Pre-`1.0.0` releases may introduce breaking changes in MINOR bumps. We surface those in the CHANGELOG and here. Patch releases are always non-breaking.

To upgrade:

```bash
composer global update sandermuller/repo-init
```

The `post-update-cmd` hook re-syncs the skill into `~/.claude/skills/sandermuller__repo-init/`. If a stub or reference doc shape changed in a way that affects in-flight workflows, re-running `audit` on already-set-up repos will surface the new MISSING / NON-CANONICAL findings.

---

## 0.6.x → 0.7.0

0.7.0 changes what repo-init scaffolds — new packages ship `sandermuller/boost-skills` and a tag-configured `boost.php`. Upgrade repo-init itself:

```bash
composer global update sandermuller/repo-init
```

### New: boost-skills + the skill-tag picker

A newly bootstrapped package now gets `sandermuller/boost-skills` (in `require-dev` and the `boost.php` `withAllowedVendors()`), and the bootstrap flow interactively prompts for which skill tags to activate (`php` / `frontend` / `github` / `jira`) — written into `boost.php` as `->withTags(...)`. For a package scaffolded before 0.7.0, `audit-<category>.md` flags `sandermuller/boost-skills` as MISSING and `upgrade-<category>.md` installs it; the tag set is then a manual `boost.php` edit or a `composer boost:install` re-run. Not breaking.

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
- **`post-install-cmd` modernization.** The old POSIX-shell `post-install-cmd` (`if [ "$COMPOSER_DEV_MODE" = "1" ]; then ...`) is Windows-broken. The upgrade phase replaces it with boost-core's `BoostAutoSync::runWithSummary` callback and adds the missing `post-update-cmd`.

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
