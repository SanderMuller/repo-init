# `sandermuller/boost-core` user-scope sync

repo-init's global-install model (per SPEC RQ40 + Open Question #3) needs a way to propagate the `repo-init` skill into `~/.claude/skills/` / `~/.cursor/skills/` / etc. when the package is installed via `composer global require sandermuller/repo-init`. boost-core ships the user-scope sync command; repo-init's install path documents the one-line invocation.

Traced against boost-core 1.13.0 (`UPGRADING.md` "1.12 → 1.13", `src/Sync/UserScope*.php`) and the files it wrote on a real machine.

> **Changed in boost-core 0.6.0 (BREAKING).** Before 0.6.0 boost-core was a Composer plugin and auto-synced on every `composer global` install/update. 0.6.0 removed the plugin (boost-core is now `type: library`). User-scope sync is now a run-it-yourself command — the user invokes it once after `composer global require` and again after each `composer global update`.

## Command surface

```bash
composer global exec -- boost sync --scope=user --all
```

- `--scope=project` (default): project-local sync — writes to `<cwd>/.claude/skills/<skill>/SKILL.md`, etc.
- `--scope=user`: publishes a package's `resources/boost/skills/` into flat `~/.{agent}/skills/<skill>-user/` dirs, plus the guidelines its author marked user-scope eligible into `~/.claude/boost/<pkg>.md`.
- `--all`: publishes EVERY installed Composer package that ships a `resources/boost/skills/` directory. No vendor allowlist and no tag filtering — user scope has no `boost.php`. A package publishes all its skills unless `~/.boost/user-scope.php` lists the ones to keep:

```php
<?php

return [
    'skills' => [
        'sandermuller/boost-skills' => ['interview', 'promptimize', 'write-spec'],
    ],
];
```

## Where the skill lands

Each skill lands at `~/.{agent}/skills/<skill>-user/SKILL.md`. The `-user` suffix keeps a user-scope copy from hiding a project skill of the same name. repo-init ships one skill, `resources/boost/skills/repo-init/`, so it lands at `~/.{agent}/skills/repo-init-user/SKILL.md`.

boost-core 1.13.0 wrote that folder for 8 agents: `.claude`, `.cursor`, `.agents`, `.amp`, `.gemini`, `.junie`, `.kiro`, `.opencode`. The `.agents` dir is shared (Codex reads it via the AGENTS.md convention).

The flat namespace is shared across packages. When two packages publish a skill of the same name, the first one written wins, and the second package's sync reports a collision. A file or symlink of your own at a target path also stops that package's sync with an error.

### Older layouts

| boost-core | Path |
|---|---|
| 1.13+ | `~/.{agent}/skills/repo-init-user/` |
| 0.4 – 1.12 | `~/.{agent}/skills/sandermuller__repo-init/` |
| before 0.4 | `~/.{agent}/skills/repo-init/` |

The first user-scope sync on 1.13 writes the flat folder and deletes the old `sandermuller__repo-init/` copy, unless the user edited that file. The pre-0.4 migration no longer runs, so a `~/.{agent}/skills/repo-init/` folder left from before 0.4 stays until the user removes it.

## Ownership manifest

boost-core records every user-scope file it writes in `~/.boost/manifests/<vendor>__<package>.json`, with the file's sha256. Two rules follow from it:

- **Sync overwrites.** A path the manifest names is rewritten on the next sync of an installed package, even when the user edited it. Edit the source skill, not the synced copy.
- **Reaping is hash-gated.** Deleting a dropped skill, or the files of a removed package, only happens when the file still matches the recorded hash. An edited file stays.

A file the manifest does not name (the user's own) is never overwritten: it stops that package's sync with an error.

## Copy, never symlink

Load-bearing invariant for the self-removal contract (`tests/self-removal-contract.md`). The sync writes a regular file (`0644`), not a symlink, so the copy in `~/.claude/skills/repo-init-user/` does not depend on the global vendor dir. boost-core also refuses to write through a symlink it finds at a target path.

## Reconcile on remove

A user-scope sync also cleans up after removed packages. When a package that has a manifest is no longer installed, the next `boost sync --scope=user --all` deletes that package's user-scope files (hash-gated, so an edited file stays) and then its manifest. So after `composer global remove sandermuller/repo-init`, the skill copy survives until the next user-scope sync. That sync needs boost-core still installed globally. When repo-init was the only global package that required boost-core, the removal takes boost-core with it, nothing reaps the copy, and it stays until the user deletes it.

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

repo-init's `composer.json` requires `sandermuller/boost-core: ^1.13`, the version that writes the flat `<skill>-user/` layout the skill's pre-flight checks for. The pre-flight still accepts the 0.4 – 1.12 `sandermuller__repo-init/` path.

## See also

- repo-init `SPEC.md` RQ40 — the global-install model that depends on this sync
- repo-init `tests/self-removal-contract.md` — the copy-never-symlink invariant and what removal leaves behind
- boost-core `UPGRADING.md` "1.12 → 1.13" — the flat `-user` layout and `~/.boost/user-scope.php`
