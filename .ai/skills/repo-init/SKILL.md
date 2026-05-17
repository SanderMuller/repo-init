---
name: repo-init
description: Bootstrap or upgrade a repo with the canonical Sander/hihaho dev setup. Triggers when the user says "set up this repo", "scaffold a new package", "audit this repo against the standard", "upgrade tooling here", or "set up a new Laravel project / package / phpstan extension / rector extension".
---

# repo-init

Routes the agent through a fixed entry flow, then to the right per-(category × mode) phase file. All phases, checklists, references, and stubs live in `vendor/sandermuller/repo-init/` — read them in place.

## Pre-flight (run once per target repo)

Before any phase, verify the package is installed and the skill is synced:

1. Check if `vendor/sandermuller/repo-init/` exists in the target repo's cwd.
   - If **yes**: you're inside an existing repo with repo-init installed. Proceed to "Decide intent".
   - If **no** and the repo has a `composer.json`: run `composer require --dev sandermuller/repo-init`, then `vendor/bin/testbench package-boost:sync`. Then proceed.
   - If **no** and there is no `composer.json` (true greenfield): see "Greenfield package bootstrap" below.

## Decide intent

Three modes:

- **Bootstrap** — new repo, you're about to create or fill an empty directory.
- **Audit** — existing repo, list gaps against the canonical setup. Read-only.
- **Upgrade** — existing repo, apply fixes. Re-runs the audit first.

If unclear from the user's prompt, ask.

## Decide category

For bootstrap, ask the user which category. For audit/upgrade, read the target's `composer.json` and follow `vendor/sandermuller/repo-init/references/detection-rules.md`.

Five categories:

| Category | Detection signal |
|---|---|
| `laravel-project` | `type: project` + `laravel/framework` in `require` |
| `phpstan-extension` | `type: phpstan-extension` OR `extra.phpstan.includes` |
| `rector-extension` | `type: rector-extension` OR `extra.rector.includes` |
| `laravel-package` | `type: library` + (`extra.laravel.providers` OR `illuminate/*` OR `socialiteproviders/manager` OR `spatie/laravel-package-tools`) |
| `php-package` | `type: library` + none of the above |

Sub-flag for `laravel-package`: if `spatie/laravel-package-tools` is in `require`, use the `laravel-package-spatie` stub variant (hihaho-style). Otherwise use `laravel-package` (sander-style).

Ambiguous → ask the user.

## Open the phase file

Read `vendor/sandermuller/repo-init/phases/<mode>-<category>.md` end-to-end. Follow it top-to-bottom. Don't improvise — every step you need is in the file.

## Knobs to collect (bootstrap mode)

Before opening a bootstrap phase, gather these. Skill prompts the user for any you can't infer.

- `vendor` (e.g. `sandermuller`, `hihaho`, custom) — required.
- `name` (kebab-case) — OPTIONAL. If provided, scaffold into `./<name>/`; if absent, scaffold into cwd (which must be empty modulo `.git/`). If cwd-empty precondition fails, stop and ask for a `name`.
- `php` — default `8.3`. Accepted: `8.3`, `8.4`, `8.5`. `8.2` rejected (laravel/pao floor).
- `laravel` (laravel-package only) — default `^11.0||^12.0||^13.0`.
- `test-framework` — default `pest` for vendor `sandermuller`, `phpunit` for vendor `hihaho`. `phpstan-extension` always `phpunit`.
- `with-hihaho-rules` — default `y` for vendor `hihaho`, `N` otherwise.
- `with-security-advisories` — default `N`.

## Greenfield package bootstrap (no composer.json yet)

For `bootstrap-laravel-package`, `bootstrap-php-package`, `bootstrap-phpstan-extension`, `bootstrap-rector-extension` in a brand-new dir:

1. Apply target-dir rule: `mkdir <name> && cd <name>` if `name` was provided; otherwise verify cwd is empty modulo `.git/`.
2. Run `composer init --no-interaction --name=<vendor>/<name> --type=library --no-install --stability=stable`. (Derive `<name>` from cwd basename if absent.)
3. Run `composer require --dev sandermuller/repo-init`. `orchestra/testbench` installs alongside as a transitive dev dep (declared in repo-init's own `require`), so the next step works immediately.
4. Run `vendor/bin/testbench package-boost:sync`.
5. Now open `phases/bootstrap-<category>.md` and follow it from step 1.

For `bootstrap-laravel-project`, `laravel new <name>` (or `laravel new .` if `name` absent) replaces steps 1+2. Steps 3+4 still apply.

## After every phase: what's next

Phase files end with a "What's next" prompt. Typical:

> Bootstrap done. Want to run an audit next, or are you done with repo-init for now?
> If done: I can remove the package — `composer remove --dev sandermuller/repo-init`.

**Self-removal is a single final step, not after every phase.** Only invoke `checklists/self-removal.md` when the user explicitly says they're done with repo-init for this repo.

## Safety rails the agent must honour

All documented in phase files; summary:

- **Per-category never-touch list** (`checklists/per-category-never-touch.md`) — `config/auth*.php`, `app/Policies/`, `.env*`, `.git/`, `vendor/`, `node_modules/`. Always honoured.
- **Git-dirty guard** (audit + upgrade modes only) — run `git status --porcelain` before any write; skip paths prefixed `M`, ` M`, `MM`, `A`, `??`. Bootstrap exempts itself because cwd-must-be-empty is the precondition.
- **larastan vs phpstan exclusivity** — never `composer require` both in the same call. Phase files spell out which is right per category.

## Re-invoking later

If the user removed repo-init and later asks for an audit or upgrade, the synced `.claude/skills/repo-init/SKILL.md` will still activate (package-boost copies skills, doesn't symlink). The skill's pre-flight step 1 detects the missing `vendor/sandermuller/repo-init/` and re-installs it. From the user's perspective, repo-init is always one prompt away.
