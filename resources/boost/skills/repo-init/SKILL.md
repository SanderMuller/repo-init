---
name: repo-init
description: Bootstrap or upgrade a repo with the canonical Sander/hihaho dev setup. Triggers when the user says "set up this repo", "scaffold a new package", "audit this repo against the standard", "upgrade tooling here", or "set up a new Laravel project / package / phpstan extension / rector extension".
---

# repo-init

Routes the agent through a fixed entry flow, then to the right per-(category × mode) phase file. All phases, checklists, references, and stubs live in `$REPO_INIT_HOME` — read them in place.

## Pre-flight (run once per session)

Before any phase:

1. **Resolve `REPO_INIT_HOME`**:
   - Run `composer global config home` to get the global Composer dir.
   - Compute `REPO_INIT_HOME=<composer-global-home>/vendor/sandermuller/repo-init` and **remember the absolute path** for the rest of the session.
   - If your shell tool spawns a fresh subshell per command (Claude Code default): **inline-substitute the absolute path** in every subsequent command (e.g. `cat /Users/<u>/.composer/vendor/sandermuller/repo-init/phases/bootstrap-laravel-package.md` instead of `cat $REPO_INIT_HOME/phases/...`). The `$REPO_INIT_HOME` shorthand used throughout phase files / references is a documentation convention — substitute it before running shell commands.
   - Verify `<resolved-REPO_INIT_HOME>/SPEC.md` exists.
   - **Escape hatch**: if `./vendor/sandermuller/repo-init/SPEC.md` exists in the target cwd, use that path instead (project-local install shadows global).
2. **If `REPO_INIT_HOME/SPEC.md` is missing**: tell the user:
   > Repo-init isn't installed. Run `composer global require sandermuller/repo-init` to install it (one-time, machine-wide). Then ask me again.
   And stop.
3. **Verify skill is synced to user-level dir**: check `~/.claude/skills/repo-init/SKILL.md` exists. boost-core 0.2.0+ auto-syncs this on `composer global require` / `composer global update` (global-context auto-sync writes to `~/.{agent}/skills/{package}/` for every globally-installed package with `resources/boost/skills/`). If missing — fallback:

   ```bash
   cd $REPO_INIT_HOME && vendor/bin/boost sync --scope=user
   ```

   (Propagates into `~/.claude/skills/`, `~/.cursor/skills/`, `~/.amp/skills/`, etc.)
4. Proceed to the routing flow below.

## Decide intent

Three modes:

- **Bootstrap** — new repo, about to create or fill an empty directory.
- **Audit** — existing repo, list gaps against the canonical setup. Read-only.
- **Upgrade** — existing repo, apply fixes. Re-runs the audit first.

If unclear from the user's prompt, ask.

## Decide category

For bootstrap, ask the user which category. For audit/upgrade, read the target's `composer.json` and follow `$REPO_INIT_HOME/references/detection-rules.md`.

Six categories:

| Category | Detection signal |
|---|---|
| `laravel-project` | `type: project` + `laravel/framework` in `require` |
| `phpstan-extension` | `type: phpstan-extension` OR `extra.phpstan.includes` |
| `rector-extension` | `type: rector-extension` OR `extra.rector.includes` |
| `laravel-package` | `type: library` + (`extra.laravel.providers` OR `illuminate/*` OR `socialiteproviders/manager` OR `spatie/laravel-package-tools`) |
| `composer-plugin` | `type: composer-plugin` |
| `php-package` | `type: library` + none of the above |

Sub-flags for `laravel-package`:

- If `spatie/laravel-package-tools` is in `require`: use the `laravel-package-spatie` stub variant (hihaho-style). Otherwise use `laravel-package` (sander-style).
- If `filament/filament` is in `require` OR user wants a Filament plugin: bootstrap routes to `phases/bootstrap-filament-plugin.md` instead. Audit / upgrade fall through to laravel-package phases.
- If `laravel/nova` is in `require` OR user wants a Nova tool: bootstrap routes to `phases/bootstrap-nova-tool.md`. Audit / upgrade fall through to laravel-package phases.

Sub-flags for `composer-plugin`:

- **`command-provider`** — plugin class implements `Capable` AND `getCapabilities()` returns `CommandProvider`. Audit verifies the provider class exists and commands extend `Composer\Command\BaseCommand` (or adapter pattern).
- **`event-subscriber`** — plugin class implements `EventSubscriberInterface`. Audit verifies subscribed events are valid `ScriptEvents` constants.
- **`boost-skill-provider`** — `resources/boost/skills/` dir present. Treated as informational; boost-core handles discovery.

Ambiguous → ask the user.

## Open the phase file

Read `$REPO_INIT_HOME/phases/<mode>-<category>.md` end-to-end. Follow it top-to-bottom. Don't improvise — every step you need is in the file.

## Knobs to collect (bootstrap mode)

Before opening a bootstrap phase, gather these. Skill prompts the user for any you can't infer.

- `vendor` (e.g. `sandermuller`, `hihaho`, custom) — required.
- `name` (kebab-case) — OPTIONAL. If provided, scaffold into `./<name>/`; if absent, scaffold into cwd (which must be empty modulo `.git/`). If cwd-empty precondition fails, stop and ask for a `name`.
- `php` — default `8.3`. Accepted: `8.3`, `8.4`, `8.5`. `8.2` rejected (laravel/pao floor).
- `laravel` (laravel-package only) — default `^12.0||^13.0`. (Laravel 11 dropped in 0.3.0 due to pao conflict.)
- `test-framework` — default `pest` for vendor `sandermuller`, `phpunit` for vendor `hihaho`. `phpstan-extension` always `phpunit`.
- `with-hihaho-rules` — default `y` for vendor `hihaho`, `N` otherwise.
- `with-security-advisories` — default `N`.

## Greenfield package bootstrap (no composer.json yet)

For `bootstrap-laravel-package`, `bootstrap-php-package`, `bootstrap-phpstan-extension`, `bootstrap-rector-extension`, `bootstrap-composer-plugin` in a brand-new dir:

1. Apply target-dir rule: `mkdir <name> && cd <name>` if `name` was provided; otherwise verify cwd is empty modulo `.git/`.
2. Open `$REPO_INIT_HOME/phases/bootstrap-<category>.md` and follow it. The phase's first step copies a stub `composer.json` from `$REPO_INIT_HOME/stubs/<category>/` directly into cwd — no `composer init` prelude needed.

For `bootstrap-laravel-project`, `laravel new <name>` (or `laravel new .` if `name` absent) creates the dir + Laravel skeleton in step 1; step 2 layers our additions on top.

**No `composer require --dev sandermuller/repo-init` step is needed in the target repo.** Repo-init lives globally; the target stays clean.

## After every phase: what's next

Phase files end with a "What's next" prompt. Typical:

> Bootstrap done. Want to run an audit next, or are you done with repo-init for now?

There's nothing to "remove" from the target — repo-init was never installed there. The skill simply stops.

## Safety rails the agent must honour

All documented in phase files; summary:

- **Per-category never-touch list** (`$REPO_INIT_HOME/checklists/per-category-never-touch.md`) — `config/auth*.php`, `app/Policies/`, `.env*`, `.git/`, `vendor/`, `node_modules/`. Always honoured.
- **Git-dirty guard** (audit + upgrade modes only) — run `git status --porcelain` before any write; skip paths whose 2-character status prefix indicates modified/added/untracked state (`MM`, `??`, or a single `M`/`A` in either column). Bootstrap exempts itself because cwd-must-be-empty is the precondition.
- **larastan vs phpstan exclusivity** — never `composer require` both in the same call. Phase files spell out which is right per category.

## Updating repo-init

```bash
composer global update sandermuller/repo-init
```

The user-level skill auto-re-syncs via boost-core's global-context auto-sync hook (POST_AUTOLOAD_DUMP under `composer global`). Manual fallback:

```bash
cd $REPO_INIT_HOME && vendor/bin/boost sync --scope=user
```

## Project-local install (escape hatch)

If a user wants to pin a specific repo-init version per project:

```bash
composer require --dev sandermuller/repo-init
```

The skill's pre-flight detects this and uses the project-local install as `REPO_INIT_HOME` (shadowing the global install). Self-removal then becomes `composer remove --dev sandermuller/repo-init` for that target.
