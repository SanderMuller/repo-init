# `sandermuller/boost-core` user-scope sync

repo-init's global-install model (per SPEC RQ40 + Open Question #3) needs a way to propagate the `repo-init` skill into `~/.claude/skills/` / `~/.cursor/skills/` / etc. when the package is installed via `composer global require sandermuller/repo-init`. boost-core ships the user-scope sync command; repo-init's install path documents the one-line invocation.

> **Changed in boost-core 0.6.0 (BREAKING).** Before 0.6.0 boost-core was a Composer plugin and auto-synced on every `composer global` install/update. 0.6.0 removed the plugin (boost-core is now `type: library`). User-scope sync is now a run-it-yourself command — the user invokes it once after `composer global require` and again after each `composer global update`. The plugin-driven auto-sync model is gone (Pattern C migration on the boost-core side).

## Command surface

```bash
composer global exec -- boost sync --scope=user --all
```

- `--scope=project` (default): project-local sync — writes to `<cwd>/.claude/skills/<skill>/SKILL.md`, etc. NOT namespaced by package.
- `--scope=user`: writes to `$HOME/.claude/skills/<vendor>__<package>/<skill>/SKILL.md` and the equivalent dirs for 9 agents (`.cursor`, `.agents`, `.github`, `.amp`, `.gemini`, `.junie`, `.kiro`, `.opencode`). The `.agents` dir is shared (used by Codex via the AGENTS.md convention; Amp also writes its `commands/` there).
- `--all`: publishes EVERY installed Composer package that ships a `resources/boost/skills/` directory (discovered via `Composer\InstalledVersions`). No vendor allowlist filtering and no tag filtering — user scope has no `boost.php`, so `withAllowedVendors()` / `withTags()` (project-scope controls) do not apply. Skills only; guidelines (`CLAUDE.md` / `AGENTS.md`) are never fanned to `$HOME`.

Each globally-installed package nests under its own `<vendor>__<package>/` subdir so multiple tools (repo-init + future siblings) don't collide. The `/` in the Composer name is replaced by `__` — a sequence the Composer name spec forbids inside vendor or project parts, so the slug mapping is injective.

When the source skill directory is named after the package basename (repo-init ships its single skill at `resources/boost/skills/repo-init/`), boost-core's `rewriteForUserScope` collapses the redundant level — the user-scope output is `~/.{agent}/skills/sandermuller__repo-init/SKILL.md`, not `.../sandermuller__repo-init/repo-init/SKILL.md`.

## What user-scope sync does

| Source | Destination |
|---|---|
| `$COMPOSER_HOME/vendor/sandermuller/repo-init/resources/boost/skills/repo-init/SKILL.md` | `~/.claude/skills/sandermuller__repo-init/SKILL.md` |
| Same | `~/.cursor/skills/sandermuller__repo-init/SKILL.md` |
| Same (× 7 more agents) | `~/.{agent}/skills/sandermuller__repo-init/SKILL.md` |

Guidelines (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) are **NOT** fanned out to `$HOME` — user-home is the wrong place for project-specific instructions.

## Copy, never symlink

Load-bearing invariant for the self-removal contract (`tests/self-removal-contract.md`). When `composer global remove sandermuller/repo-init` deletes the source vendor dir, the user-scope copy in `~/.claude/skills/sandermuller__repo-init/` must survive. boost-core's `SyncEngine::syncUser()` does a file copy, not a symlink.

## Idempotency

Re-running `boost sync --scope=user --all` does not duplicate, append-to, or corrupt existing user-scope files. Same hash-then-overwrite semantics as project-scope sync.

## Permissions

Files `0644`, dirs `0755` — matches boost-core's project-scope posture.

## $HOME resolution

`$HOME` first, then `$USERPROFILE` (Windows), then `sys_get_temp_dir()`. boost-core also accepts a `$homeRoot` override (used for testing) so the test harness doesn't need to call `putenv` (which is on `spaze/phpstan-disallowed-calls`).

## How repo-init uses it

Two-step install (one-time per machine):

```bash
composer global require sandermuller/repo-init
composer global exec -- boost sync --scope=user --all
```

Two-step update (after each version bump):

```bash
composer global update sandermuller/repo-init
composer global exec -- boost sync --scope=user --all
```

repo-init is a pure-markdown package — it ships no bin and no `post-install-cmd` that fires for a globally-required dependency (Composer script hooks fire only for the root package, not for required dependencies). Post-0.6.0 there is no install-time auto-sync mechanism for a passive skill-distribution package; the user-invoked `boost sync --scope=user --all` is the canonical sync trigger. See SPEC RQ1 (zero-PHP-code) for why repo-init does not ship a bin.

## Constraints

repo-init's `composer.json` requires `sandermuller/boost-core: ^0.19.0` (canonical floor; `.config/boost.php` needs ≥ 0.18, repo-init pins the current `^0.19.0`). The `--scope=user --all` flag combination is a 0.6.0 feature (the `--all` flag arrived alongside the plugin removal). Pre-0.6.0 boost-core supported `--scope=user` but not `--all` and did the auto-sync via the plugin instead.

## See also

- repo-init `SPEC.md` RQ40 — the global-install model that depends on this sync
- repo-init `tests/self-removal-contract.md` — the copy-never-symlink invariant
- boost-core's Pattern C migration spec — Composer-plugin removal in 0.6.0
