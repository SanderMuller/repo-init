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
