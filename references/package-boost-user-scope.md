# `sandermuller/package-boost` user-scope sync contract

repo-init v0.1's global-install model (per SPEC RQ40 + Open Question #3) depends on a feature `sandermuller/package-boost` must ship: a `--scope=user` flag on `package-boost:sync` that propagates skills into the user's home Claude / Cursor / Agents skill dirs instead of the current project's local dirs.

This file documents the contract repo-init expects from package-boost. Until package-boost ships the feature, repo-init's `composer global require sandermuller/repo-init` post-install hook silently no-ops the user-scope sync, and the user (or agent) must manually run `vendor/bin/testbench package-boost:sync` in some target repo with repo-init installed to get the skill propagated.

## Contract

### Command surface

```bash
vendor/bin/testbench package-boost:sync --scope=user
```

When invoked from a **global** Composer install (`COMPOSER_HOME/vendor/sandermuller/repo-init/`), `--scope=user` is implied if no `--scope` is passed. When invoked from a **project-local** install (`<target>/vendor/sandermuller/repo-init/`), `--scope=project` is implied and the existing behaviour applies.

### Source

Reads from `vendor/<vendor>/<package>/.ai/skills/` of every installed dep that ships an `.ai/skills/` dir (same discovery as the existing project-scope sync).

### Destination (user-scope)

| Source | Destination |
|---|---|
| `vendor/<v>/<p>/.ai/skills/<skill>/` | `~/.claude/skills/<skill>/` (Claude Code) |
| Same | `~/.cursor/skills/<skill>/` (Cursor) |
| Same | `~/.agents/skills/<skill>/` (Codex / OpenCode / Amp / Gemini) |
| Same | `~/.github/skills/<skill>/` (GitHub Copilot) |
| Same | `~/.junie/skills/<skill>/` (JetBrains Junie) |
| Same | `~/.kiro/skills/<skill>/` (Kiro) |

Same multi-agent fanout as the existing project-scope sync, but rooted at `$HOME` instead of the current project.

### Copy, never symlink

This is the load-bearing invariant for the self-removal contract (documented in `tests/self-removal-contract.md`). When `composer global remove sandermuller/repo-init` deletes the source `vendor/sandermuller/repo-init/`, the user-scope copy in `~/.claude/skills/repo-init/` must survive.

### Idempotency

Re-running `package-boost:sync --scope=user` must not duplicate, append-to, or corrupt existing user-scope skill files. Same hash-then-overwrite semantics as the existing project-scope sync.

### Permissions

Files in `~/.claude/skills/` etc. should be readable by the user only (`0644`); dirs `0755`. Match package-boost's existing project-scope permission posture.

### Discovery from outside a target repo

A key UX gap: package-boost's existing `--scope=project` sync assumes it's running INSIDE a target repo with `.claude/skills/` etc. resolvable in `cwd`. The user-scope variant invoked from inside the global vendor dir (`composer global require ...` post-install context) must resolve `~/.claude/skills/` from `$HOME`, NOT from cwd. So `--scope=user` is mandatory in that context — without it, package-boost would try to write skills into `$COMPOSER_HOME/vendor/sandermuller/repo-init/.claude/skills/` (meaningless).

## Implementation hints for package-boost

Approximate diff scope (~30 LOC):

1. `SyncCommand`: accept `--scope=user|project|auto` flag, default `auto`.
2. `auto` resolution: if cwd is inside `$(composer global config home)`, pick `user`; else pick `project`.
3. `getSkillDestinationPaths()`: branch on scope; user-scope returns `$_SERVER['HOME']`-rooted paths; project-scope returns cwd-rooted (existing behaviour).
4. Tests: add a fixture-based test that confirms `--scope=user` writes into a tmp `$HOME` and doesn't touch a tmp cwd.

## When this ships

Tracked as repo-init Open Question #3. When package-boost ≥ X.Y.Z ships this feature, update repo-init's `composer.json` `require: sandermuller/package-boost` constraint to require the new MINOR, then tag repo-init `0.1.0`.

Until then, the README + SKILL.md make the manual workaround explicit (run `package-boost:sync` from any target repo with repo-init installed).
