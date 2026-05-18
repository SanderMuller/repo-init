# `sandermuller/boost-core` user-scope sync

repo-init's global-install model (per SPEC RQ40 + Open Question #3) needs a way to propagate the `repo-init` skill into `~/.claude/skills/` / `~/.cursor/skills/` / etc. when the package is installed via `composer global require sandermuller/repo-init`. This feature landed in [`sandermuller/boost-core`](https://github.com/SanderMuller/boost-core), commit [`bebd046b`](https://github.com/SanderMuller/boost-core/commit/bebd046bbcc14d8ca3f7184b911d467b04bc27bb).

**Important:** the feature shipped in `boost-core`, not in `sandermuller/package-boost`. The earlier draft of this doc anticipated the wrong package. Repo-init's post-install hook now invokes `boost-core`'s binary.

## Command surface

```bash
vendor/bin/boost sync --scope=user
```

- `--scope=project` (default): project-local sync — writes to `<cwd>/.claude/skills/`, etc. Existing behaviour.
- `--scope=user`: writes to `$HOME/.claude/skills/<pkg-suffix>/<skill>.md` and the equivalent dirs for 9 agents (`.cursor`, `.agents`, `.github`, `.junie`, `.kiro`, `.codex`, `.windsurf`, `.aider`).

Each globally-installed package nests under its own `<pkg-suffix>/` subdir so multiple tools (repo-init + future siblings) don't collide.

## What user-scope sync does

| Source | Destination |
|---|---|
| `$COMPOSER_HOME/vendor/sandermuller/repo-init/resources/boost/skills/<skill>/SKILL.md` | `~/.claude/skills/repo-init/<skill>.md` |
| Same | `~/.cursor/skills/repo-init/<skill>.md` |
| Same (× 7 more agents) | `~/.{agent}/skills/repo-init/<skill>.md` |

Guidelines (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) are **NOT** fanned out to `$HOME` — user-home is the wrong place for project-specific instructions.

## Copy, never symlink

Load-bearing invariant for the self-removal contract (`tests/self-removal-contract.md`). When `composer global remove sandermuller/repo-init` deletes the source vendor dir, the user-scope copy in `~/.claude/skills/repo-init/` must survive. boost-core's `SyncEngine::syncUser()` does a file copy, not a symlink.

## Idempotency

Re-running `boost sync --scope=user` does not duplicate, append-to, or corrupt existing user-scope files. Same hash-then-overwrite semantics as project-scope sync.

## Permissions

Files `0644`, dirs `0755` — matches boost-core's project-scope posture.

## $HOME resolution

`$HOME` first, then `$USERPROFILE` (Windows), then `sys_get_temp_dir()`. boost-core also accepts a `$homeRoot` override (used for testing) so the test harness doesn't need to call `putenv` (which is on `spaze/phpstan-disallowed-calls`).

## Source of truth

The implementation lives in boost-core:

- `src/Commands/SyncCommand.php` — the `--scope` flag plumbing.
- `src/Sync/SyncEngine.php` — `syncUser($packageRoot, $checkOnly, ?$homeRoot)`.
- `src/Sync/UserScopeResult.php` — value object for per-run summary.
- `tests/Integration/UserScopeSyncTest.php` — happy path, guidelines NOT fanned out, check-mode reports drift, missing composer.json surfaces as error.

## How repo-init uses it

`bin/post-install-sync.php` is the composer `post-install-cmd` hook. It:

1. Locates `vendor/bin/boost` (boost-core's binary). Bails silently if not found.
2. Runs `vendor/bin/boost sync --scope=user` from repo-init's own vendor dir.
3. On exit-non-zero, prints a clear one-liner pointing at `references/boost-core-user-scope.md` and continues — does NOT fail the composer install.

## Constraints

Repo-init's `composer.json` requires `sandermuller/boost-core: ^X.Y` where X.Y is the version that ships `bebd046b` (the `--scope=user` commit). Composer enforces this at install time.

## See also

- repo-init `SPEC.md` RQ40 — the global-install model that depends on this feature
- repo-init `tests/self-removal-contract.md` — the copy-never-symlink invariant
