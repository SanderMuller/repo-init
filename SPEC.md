# sandermuller/repo-init

## Overview

Zero-code, dev-only Composer package that ships an AI playbook for bootstrapping, auditing, or upgrading a GitHub repo to the canonical Sander/hihaho dev setup. No PHP runtime, no artisan commands, no binaries — just one Claude skill that routes the agent through 15 per-(category × mode) markdown phases, plus pinned stub files the agent copies into the target repo and reference docs the agent consults.

**Distribution: global install (like `composer global require laravel/installer`).** Install once per machine:

```bash
composer global require sandermuller/repo-init
```

A one-time post-install step syncs the skill into the user-level Claude skill dir (`~/.claude/skills/repo-init/`) so it auto-activates in any project. From then on, every phase reads phases/checklists/references/stubs from the global install path (`$(composer global config home)/vendor/sandermuller/repo-init/`) directly — nothing is copied into target repos, and no per-project dev dep is added. Self-removal is a single optional command (`composer global remove sandermuller/repo-init`), almost never run in practice.

Project-local install (`composer require --dev sandermuller/repo-init`) remains supported as an escape hatch for users who want to pin a different repo-init version per target — see §3.4.

v1 supports five repo categories: `laravel-project`, `laravel-package`, `php-package`, `phpstan-extension`, `rector-extension`.

---

## 1. Goals & Non-Goals

### Goals

- **Pure docs, zero code.** The package contains only markdown, JSON/YAML/PHP stub files, and a `composer.json`. No service provider, no commands, no PHP source under `src/`.
- **Single entry point.** `.ai/skills/repo-init/SKILL.md` is the only doc the agent must read first. It runs an inline detection checklist, then routes to the right phase file.
- **One phase = one self-contained playbook.** 15 phase files (5 categories × 3 modes: bootstrap, audit, upgrade) — the agent reads one file top-to-bottom and follows it.
- **Stubs over generators.** Agent copies files from `stubs/<category>/` and substitutes placeholders manually (the file naming makes which placeholders to fill obvious; no templating engine).
- **Wrap, don't duplicate.** Stubs and dep lists wire in `sandermuller/package-boost`, `larastan/larastan`, `laravel/pint`, `rector/rector`, `laravel/boost`, `hihaho/phpstan-rules` and `hihaho/rector-rules`. The playbook never reimplements what those packages already do.
- **Globally installed, locally invoked.** Installed once per machine via `composer global require sandermuller/repo-init`. All phase files, checklists, references, and stubs read from the global vendor dir (resolved at skill pre-flight as `REPO_INIT_HOME = $(composer global config home)/vendor/sandermuller/repo-init`). Nothing is copied into the target's working tree. State for in-flight work lives in the conversation context, not on disk.
- **Self-removal is optional and rare.** Most users keep repo-init installed globally forever and `composer global update sandermuller/repo-init` to refresh. Removing is a one-liner — `composer global remove sandermuller/repo-init` — invoked only if the user is decommissioning the tool entirely.

### Non-Goals (v1)

- Any PHP runtime — no commands, no Symfony Console binary, no service provider.
- Programmatic detection — the agent reads `composer.json` and follows `references/detection-rules.md` itself.
- Programmatic state/resume — the agent handles partial-failure rerun via its own task list.
- Programmatic diff/prompt UI for upgrade — the agent shows diffs and asks questions natively.
- Filament-plugin and Nova-tool package subtypes (defer to v2).
- Non-PHP repos.
- Auto-creating the GitHub remote.
- Touching security-sensitive files (see §6).

---

## 2. Package Layout

```
sandermuller/repo-init/
├── composer.json                                 # type: library; no scripts; only metadata + sync hook
├── README.md                                     # Quick-start for humans
├── CHANGELOG.md
├── LICENSE
├── .ai/
│   └── skills/
│       └── repo-init/
│           └── SKILL.md                          # The single entry point (§3)
├── phases/
│   ├── bootstrap-laravel-project.md
│   ├── bootstrap-laravel-package.md
│   ├── bootstrap-php-package.md
│   ├── bootstrap-phpstan-extension.md
│   ├── bootstrap-rector-extension.md
│   ├── audit-laravel-project.md
│   ├── audit-laravel-package.md
│   ├── audit-php-package.md
│   ├── audit-phpstan-extension.md
│   ├── audit-rector-extension.md
│   ├── upgrade-laravel-project.md
│   ├── upgrade-laravel-package.md
│   ├── upgrade-php-package.md
│   ├── upgrade-phpstan-extension.md
│   └── upgrade-rector-extension.md
├── checklists/
│   ├── preflight.md                              # Run before any phase: git clean? on a branch? composer installed?
│   ├── per-category-never-touch.md               # Files agent must never write
│   ├── post-bootstrap-verification.md            # After bootstrap: composer install ok? tests run?
│   ├── post-upgrade-verification.md              # After upgrade: phpstan still green? pint clean?
│   └── self-removal.md                           # Final confirmation + cleanup
├── references/
│   ├── detection-rules.md                        # How to read composer.json and categorise (§4)
│   ├── shared-dev-deps.md                        # Universal require-dev list (§5.1) + per-category exclusions (§5.1.1)
│   ├── per-category-deps.md                      # Split into MANDATORY vs OPTIONAL deps (§5.2)
│   ├── per-category-deps.yml                     # Machine-readable parallel of per-category-deps.md (Phase 7 sync check)
│   ├── composer-scripts.md                       # Exact scripts block per category
│   ├── phpstan-config.md                         # Per-category includes/paths/parameters
│   ├── rector-config.md                          # Per-category sets/paths
│   ├── canonical-repos.md                        # Reference repo links per category
│   ├── version-defaults.md                       # PHP, Laravel, Pest defaults & rationale
│   ├── pest-vs-phpunit.md                        # When to use which (vendor-driven default)
│   ├── gitattributes-managed-block.md            # Contract with package-boost's block
│   ├── upgrade-merge-modes.md                    # Per-file merge mode (§9) — replace/managed-block/append-only/merge-keys/notify-only
│   ├── composer-failure-modes.md                 # Common composer install/require failures + resolution playbook
│   └── placeholder-rules.md                      # StudlyCase derivation + edge cases for §2 placeholders
└── stubs/
    ├── shared/
    │   ├── .editorconfig
    │   ├── .gitattributes                        # With placeholder for vendor name + reference to managed block
    │   ├── .gitignore                            # Categorised sections; agent strips inapplicable ones per category
    │   ├── .mcp.json
    │   ├── pint.json
    │   ├── phpstan-baseline.neon                 # Empty
    │   ├── phpstan.neon.dist                     # Variants live in stubs/<category>/phpstan.neon.dist
    │   ├── rector.php                            # Variants live in stubs/<category>/rector.php
    │   ├── phpunit.xml
    │   ├── tests/Pest.php
    │   └── .github/
    │       ├── dependabot.yml
    │       └── workflows/
    │           ├── phpstan.yml
    │           ├── pint-check.yml
    │           ├── rector-check.yml
    │           └── update-changelog.yml
    ├── laravel-project/
    │   ├── boost.json
    │   ├── phpstan.neon.dist                     # paths: [app, routes, config, database, tests]
    │   ├── rector.php                            # With hihaho/rector-rules sets when --with-hihaho-rules
    │   └── README.append.md                      # Hihaho rule-pack onboarding paragraph
    ├── laravel-package/                          # Default sander-style (manual ServiceProvider)
    │   ├── composer.json
    │   ├── testbench.yaml
    │   ├── workbench/app/Providers/WorkbenchServiceProvider.php
    │   ├── src/__PACKAGE_STUDLY__ServiceProvider.php
    │   ├── config/__PACKAGE__.php
    │   ├── phpstan.neon.dist
    │   ├── rector.php
    │   └── .github/workflows/run-tests.yml       # Matrix: PHP × Laravel × stability
    ├── laravel-package-spatie/                   # hihaho-style (spatie/laravel-package-tools)
    │   ├── composer.json                         # Requires spatie/laravel-package-tools in `require`
    │   ├── testbench.yaml
    │   ├── workbench/app/Providers/WorkbenchServiceProvider.php
    │   ├── src/__PACKAGE_STUDLY__ServiceProvider.php  # extends PackageServiceProvider
    │   ├── config/__PACKAGE__.php
    │   ├── phpstan.neon.dist
    │   ├── rector.php
    │   └── .github/workflows/run-tests.yml
    ├── php-package/
    │   ├── composer.json
    │   ├── .lpv
    │   ├── PUBLIC_API.md
    │   ├── src/__PACKAGE_STUDLY__.php
    │   ├── phpstan.neon.dist
    │   ├── rector.php
    │   └── .github/workflows/run-tests.yml
    ├── phpstan-extension/
    │   ├── composer.json                         # type: phpstan-extension + extra.phpstan.includes wired
    │   ├── extension.neon                        # parametersSchema/parameters/services skeleton
    │   ├── src/Rules/.gitkeep
    │   ├── tests/Rules/stubs/.gitkeep            # classmap target
    │   ├── phpstan.neon.dist
    │   ├── rector.php
    │   └── .github/workflows/run-tests.yml
    └── rector-extension/
        ├── composer.json                         # type: rector-extension + extra.rector.includes wired
        ├── config/config.php                     # Rector service registration
        ├── src/Rector/.gitkeep
        ├── tests/Rector/.gitkeep
        ├── phpstan.neon.dist
        ├── rector.php
        └── .github/workflows/run-tests.yml
```

Stubs use literal placeholder strings the agent finds-and-replaces. Derivation rules (exact, no agent guessing):

| Placeholder | Derived from | Example: input `sandermuller/queue-insights` |
|---|---|---|
| `__VENDOR__` | composer name, part before `/` | `sandermuller` |
| `__PACKAGE__` | composer name, part after `/` | `queue-insights` |
| `__VENDOR_STUDLY__` | StudlyCase of `__VENDOR__` | `SanderMuller` |
| `__PACKAGE_STUDLY__` | StudlyCase of `__PACKAGE__` | `QueueInsights` |
| `__NAMESPACE__` | `{__VENDOR_STUDLY__}\\{__PACKAGE_STUDLY__}` | `SanderMuller\\QueueInsights` |
| `__NAMESPACE_ESCAPED__` | `__NAMESPACE__` with `\\` doubled for JSON | `SanderMuller\\\\QueueInsights` |
| `__DESCRIPTION__` | user input | (free text) |
| `__AUTHOR_NAME__` | git config user.name fallback to user input | `Sander Muller` |
| `__AUTHOR_EMAIL__` | git config user.email fallback to user input | `sander@hihaho.com` |
| `__PHP_VERSION__` | `^{8.3\|8.4\|8.5}` per `--php=` | `^8.3` |
| `__LARAVEL_VERSIONS__` | per `--laravel=` (laravel-package only) | `^11.0\|\|^12.0\|\|^13.0` |
| `__PHP_VERSION_NEON__` | bare `{8.3\|8.4\|8.5}` for rector PHP set name | `php83` |

StudlyCase rule: split on `-` or `_`, uppercase first letter of each part, concatenate. `queue-insights` → `QueueInsights`. Edge cases (digits, mixed case) listed in `references/placeholder-rules.md`. Stub file paths use the same placeholders — e.g. `src/__PACKAGE_STUDLY__ServiceProvider.php` is renamed to `src/QueueInsightsServiceProvider.php` after substitution.

Each phase file lists which placeholders apply to which stubs so the agent doesn't grep.

The package itself ships only:

```json
{
    "name": "sandermuller/repo-init",
    "type": "library",
    "description": "AI playbook + stub library for bootstrapping the canonical Sander/hihaho repo setup. Install globally: `composer global require sandermuller/repo-init`.",
    "require": {
        "php": "^8.3",
        "sandermuller/boost-core": "^0.6.0"
    },
    "require-dev": {
        "laravel/pint": "^1.29",
        "sandermuller/boost-skills": "^1.0",
        "sandermuller/package-boost-php": "^0.5.0",
        "stolt/lean-package-validator": "^5.7"
    },
    "scripts": {
        "post-install-cmd": ["SanderMuller\\BoostCore\\Scripts\\BoostAutoSync::run"],
        "post-update-cmd": ["SanderMuller\\BoostCore\\Scripts\\BoostAutoSync::run"]
    },
    "config": {
        "sort-packages": true,
        "allow-plugins": {
            "sandermuller/package-boost-php": true
        }
    }
}
```

`repo-init` is a `type: library` package distributed via **global install** (`composer global require sandermuller/repo-init`; see §3.3 and RQ40) — never as a `--dev` dependency of a target repo. Its sole runtime dependency is `sandermuller/boost-core` (`type: library` from 0.6.0), the skill-sync engine. Pre-0.6.0 boost-core was a `composer-plugin` and auto-synced the `repo-init` skill into `~/.{agent}/skills/sandermuller__repo-init/` on `composer global` install/update; 0.6.0 removed the plugin (Pattern C). The sync is now a one-line manual command after each install/update: `composer global exec -- boost sync --scope=user --all` (see `references/boost-core-user-scope.md`).

Everything else sits in `require-dev` — `laravel/pint`, `sandermuller/boost-skills`, `sandermuller/package-boost-php`, `stolt/lean-package-validator` — repo-init's own maintenance tooling, not shipped to consumers. `config.allow-plugins` allow-lists `sandermuller/package-boost-php` (still `type: composer-plugin`); boost-core is no longer a plugin in 0.6.0 so its allow-plugins entry is gone.

An early draft instead placed `orchestra/testbench` + `sandermuller/package-boost` in `require`, so they would ride along when a target ran `composer require --dev sandermuller/repo-init`. That project-local model is superseded — see RQ35 and the v7 distribution decision in RQ40.

---

## 3. The Skill (`.ai/skills/repo-init/SKILL.md`)

The single entry point. Frontmatter:

```yaml
---
name: repo-init
description: Bootstrap or upgrade a repo with the canonical Sander/hihaho dev setup. Triggers when the user says "set up this repo", "scaffold a new package", "audit this repo against the standard", "upgrade tooling here", or "set up a new <category> repo".
---
```

### 3.1 Skill flow

The skill body teaches a fixed three-step entry flow:

1. **Decide intent.** Bootstrap (new repo, no composer.json yet) vs Audit (existing repo, check gaps) vs Upgrade (existing repo, apply fixes). If unclear, ask the user.
2. **Decide category.** For bootstrap, prompt the user for `--type=` (one of the five categories). For audit/upgrade, read `composer.json` and follow `references/detection-rules.md` to pick one of the five categories. If the file is ambiguous, ask the user.
3. **Open the phase file.** Read `phases/<mode>-<category>.md` end-to-end and follow it. Don't improvise — every step is in the file.

The skill also lists the seven user-facing knobs the agent must collect or infer before opening a bootstrap phase:

- `vendor` (sandermuller / hihaho / custom)
- `name` (kebab-case, OPTIONAL — see §7.target-dir-rule: if provided, scaffolds into `./<name>/`; if absent, scaffolds into cwd which must be empty modulo `.git/`)
- `php` (8.3 / 8.4 / 8.5 — default 8.3; 8.2 rejected, see §5.7)
- `laravel` (only for laravel-package — `^11||^12||^13`, `^12||^13`, `^13`)
- `test-framework` (pest / phpunit — vendor-driven default per `references/pest-vs-phpunit.md`)
- `with-hihaho-rules` (y/N — default y for vendor=hihaho)
- `with-security-advisories` (y/N — default N)

### 3.2 Skill flow ends each phase with "what next"

Phase files end with a "What's next" prompt the agent surfaces to the user — never with a self-removal prompt. Typical options:

> Bootstrap done. Want to run an audit next, or are you done with repo-init for now?
> If done: I can remove the package — `composer remove --dev sandermuller/repo-init`.

Self-removal happens **once**, at the explicit end of the user's session with repo-init — not after every phase. See §10.

### 3.3 Pre-flight: locate the global install

Every skill invocation runs this once:

1. Resolve `REPO_INIT_HOME = $(composer global config home)/vendor/sandermuller/repo-init`.
2. Verify `REPO_INIT_HOME/SPEC.md` exists. If not, prompt the user:
   > Repo-init isn't installed globally. Run `composer global require sandermuller/repo-init` to install it (one-time, machine-wide). Continue?
3. Verify `~/.claude/skills/repo-init/SKILL.md` exists. If not, run `package-boost:sync --scope=user` (see §3.5 contract) to propagate the skill into the user-level skill dir.
4. Proceed to the routing flow in §3.1. All subsequent stub/reference/checklist reads use absolute paths rooted at `REPO_INIT_HOME`.

### 3.3.1 Greenfield package bootstrap

For `bootstrap-laravel-package`, `bootstrap-php-package`, `bootstrap-phpstan-extension`, `bootstrap-rector-extension` (no Laravel installer to wrap):

> **Target-dir rule** (single source of truth — referenced from §3.1 and §7): If user passed positional `name`, create `./<name>/` and cd. If `name` is absent, target IS cwd, which must be empty modulo `.git/`. If cwd-empty precondition fails, agent stops and asks for a `name`.

Flow:

1. **Apply target-dir rule** — `mkdir <name> && cd <name>` if `name` was passed; otherwise verify cwd is empty.
2. **Proceed to the bootstrap phase steps** (§7). The bootstrap phase reads stubs from `$REPO_INIT_HOME/stubs/<category>/`, fills placeholders, writes into cwd. First file written is `composer.json` (no prior `composer init` needed — the stub IS the composer.json).
3. **Run `composer install`** to materialise the target's `vendor/`.

For `bootstrap-laravel-project`, `laravel new <name>` (or `laravel new .` if `name` absent) creates the dir + Laravel skeleton in step 1; step 2 layers our additions on top.

No `composer require --dev sandermuller/repo-init` step is needed in the target. Repo-init lives globally; the target stays clean.

### 3.4 Project-local install (escape hatch)

If the user wants a specific repo-init version pinned to a single project (e.g. testing a pre-release, or shipping a setup tied to an old repo-init version), they can install locally:

```bash
composer require --dev sandermuller/repo-init
```

The skill's pre-flight detects this case: if `./vendor/sandermuller/repo-init/SPEC.md` exists, `REPO_INIT_HOME` is set to `./vendor/sandermuller/repo-init` instead of the global path. Project-local takes precedence over global when both are present.

Project-local install also requires `vendor/bin/testbench package-boost:sync` (not `--scope=user`) to propagate the skill into the target's `.claude/skills/`. The target then activates the skill from its own `.claude/skills/repo-init/` (which shadows the user-level skill if both exist; project shadowing user is Claude Code's default skill resolution).

### 3.5 Package-boost contract: user-scope sync

For the global install model to work, `sandermuller/package-boost` must support syncing into `~/.claude/skills/` (user level) in addition to its existing project-level sync. The contract:

- New command: `vendor/bin/boost sync --scope=user` (or equivalent).
- Reads skills from `vendor/<vendor>/<package>/.ai/skills/`, writes to `~/.claude/skills/`, `~/.cursor/skills/`, etc.
- Idempotent — re-syncing doesn't duplicate.
- When invoked from a *global* composer install (`COMPOSER_HOME/vendor/sandermuller/repo-init/`), `--scope=user` is implied if no `--scope` is passed.

repo-init's own post-install hook fires `package-boost:sync --scope=user` automatically after `composer global require sandermuller/repo-init`, so the user doesn't run sync manually. See `references/boost-core-user-scope.md` for the full contract.

---

## 4. Detection (`references/detection-rules.md`)

A flat decision table the agent runs against the target repo's `composer.json`. First match wins.

| Step | Check | If true → category |
|---|---|---|
| 1 | `type: project` AND `laravel/framework` in `require` | `laravel-project` |
| 2 | `type: phpstan-extension` OR `extra.phpstan.includes` exists | `phpstan-extension` |
| 3 | `type: rector-extension` OR `extra.rector.includes` exists | `rector-extension` |
| 4 | (`type: library` OR missing) AND any of: `extra.laravel.providers` set, `illuminate/*` in `require`, `socialiteproviders/manager` in `require`, `spatie/laravel-package-tools` in `require` | `laravel-package` |
| 5 | `type: library` AND none of the above | `php-package` |
| 6 | None match | `unknown` — agent asks user to confirm |

The document also lists three **sub-flags** the agent records (informational, may modify the chosen phase):

- `socialite-provider` — `socialiteproviders/manager` in require → no `extra.laravel.providers` expected.
- `mcp-bridge` — `laravel/mcp` in require → workbench scripts recommended.
- `hihaho-package-tools-flavoured` — `spatie/laravel-package-tools` in require → use the spatie service-provider pattern in stubs.

### 4.1 Error cases

- `composer.json` missing AND user has not picked a `--type=` → agent asks user.
- `composer.json` exists but is invalid JSON → agent stops and reports the parse error.
- `--type=` value isn't one of the five → agent rejects and re-prompts.

---

## 5. Per-Category Recipes (`references/per-category-deps.md`)

### 5.1 Shared dev deps (every category)

```
laravel/pao
laravel/pint
phpstan/extension-installer
phpstan/phpstan-strict-rules
phpstan/phpstan-deprecation-rules
phpstan/phpstan-phpunit
rector/rector
rector/type-perfect
spaze/phpstan-disallowed-calls
symplify/phpstan-extensions
tomasvotruba/cognitive-complexity
tomasvotruba/type-coverage
nunomaduro/collision
sandermuller/package-boost
orchestra/testbench
```

`laravel/pao` ("Agent-optimized output for PHP testing tools") wraps phpunit/pest/pint/phpstan/rector/paratest with agent-friendly output formatting — load-bearing for an AI-driven dev setup. It's framework-agnostic (require: `php`, `laravel/agent-detector`) so it applies to every category. Its PHP floor `^8.3` matches our hard floor (§5.7), so no fallback path is needed.

### 5.1.1 Per-category exclusions from the shared list

When a category puts a package in its **`require`** (§5.2), we drop it from the dev-deps install for that category — Composer rejects a package being in both `require` and `require-dev`.

| Category | Drop from §5.1 shared dev deps | Because §5.2 puts it in `require` |
|---|---|---|
| `rector-extension` | `rector/rector` | `rector/rector: ^2` |
| `phpstan-extension` | `phpstan/phpstan` (the bare one — `phpstan/extension-installer` + `phpstan-strict-rules` + `phpstan-phpunit` + `phpstan-deprecation-rules` stay in `require-dev`) | `phpstan/phpstan: ^2` |
| `laravel-package` (sub-flag `hihaho-package-tools-flavoured`) | (none — `spatie/laravel-package-tools` isn't in shared) | `spatie/laravel-package-tools` |
| Others | (none) | — |

Audit honours these: a `rector-extension` repo with `rector/rector` in `require` and absent from `require-dev` is **correct**, not MISSING. Same for `phpstan/phpstan` in `phpstan-extension`.

Note: §5.1 shared dev deps do not directly list bare `phpstan/phpstan` — but `larastan/larastan` (in Laravel categories) requires it transitively. For non-Laravel categories `php-package` and `phpstan-extension`, `phpstan/phpstan` is required explicitly via §5.2 ("Adds to `require-dev`" for php-package; "Adds to `require`" for phpstan-extension).

When `test-framework=pest`: add `pestphp/pest`, `pestphp/pest-plugin-arch`, `mrpunyapal/rector-pest`. Laravel categories also add `pestphp/pest-plugin-laravel`.

When `test-framework=phpunit`: add `phpunit/phpunit`.

### 5.2 Category-specific additions

Split into **MANDATORY** (audit flags MISSING if absent) and **OPTIONAL/CONDITIONAL** (audit flags only if the user confirmed opt-in at audit-start prompt — see §8 audit-scoping).

**Hard rule: no package appears in both `require` and `require-dev` in the same row** — Composer rejects it and audit would emit false MISSING/EXTRA noise. When a category puts a package in `require`, §5.1.1 drops it from the shared dev-deps install for that category.

**MANDATORY (per category):**

| Category | Adds to `require-dev` | Adds to `require` |
|---|---|---|
| `laravel-project` | `larastan/larastan`, `laravel/boost`, `laravel/pail`, `laravel/tinker`, `driftingly/rector-laravel` | (the `laravel new` baseline) |
| `laravel-package` | `larastan/larastan`, `driftingly/rector-laravel` | `illuminate/contracts`, `illuminate/support` at `__LARAVEL_VERSIONS__` |
| `php-package` | `phpstan/phpstan`, `stolt/lean-package-validator` | (no `illuminate/*`) |
| `phpstan-extension` | (none beyond shared, minus `phpstan/phpstan` per §5.1.1) | `phpstan/phpstan: ^2` |
| `rector-extension` | (none beyond shared, minus `rector/rector` per §5.1.1) | `rector/rector: ^2` |

**OPTIONAL / CONDITIONAL (only flagged when opt-in is confirmed):**

| Category | Opt-in flag / sub-flag | Adds to `require-dev` | Adds to `require` |
|---|---|---|---|
| `laravel-project` | `--with-hihaho-rules` (default `y` for vendor=hihaho) | `hihaho/phpstan-rules`, `hihaho/rector-rules`, `symplify/phpstan-rules` | — |
| `laravel-project` | `--with-security-advisories` (default `N`) | `roave/security-advisories: dev-latest` | — |
| `laravel-package` | suggest (not mandatory) | `livewire/livewire` (suggested only — not auto-installed, not audited) | — |
| `laravel-package` | sub-flag `hihaho-package-tools-flavoured` (or `--variant=spatie`) | — | `spatie/laravel-package-tools` |
| `phpstan-extension` | Laravel-aware (has `illuminate/*` in `require`) | `larastan/larastan` (replaces shared `phpstan/phpstan` — see §5.3) | `illuminate/support` |
| `rector-extension` | Laravel-aware (`--with-laravel-sets`) | — | `driftingly/rector-laravel` |

The "Laravel-aware" sub-detection for phpstan/rector extensions: if the existing repo already has `illuminate/*` in `require`, opt-in is auto-set to `y`; otherwise the audit asks the user. For bootstrap, asked at the bootstrap prompt.

When the `phpstan-extension` Laravel-aware opt-in fires, `larastan/larastan` is installed instead of (not in addition to) `phpstan/phpstan` per §5.3 — the agent removes `phpstan/phpstan` from `require-dev` and adds `larastan/larastan`; the `require` `phpstan/phpstan: ^2` stays (so the extension's own composer.json keeps declaring its phpstan dependency cleanly for consumers).

### 5.3 `larastan` vs `phpstan/phpstan` exclusivity

`larastan/larastan` requires `phpstan/phpstan` transitively. Categories use exactly one of them:

- Laravel-aware → `larastan/larastan` only.
- Framework-agnostic → `phpstan/phpstan` only.

Phase files spell this out so the agent never `composer require`s both in the same call.

### 5.4 Composer scripts (`references/composer-scripts.md`)

Always:

```json
{
  "scripts": {
    "phpstan": "vendor/bin/phpstan analyse --memory-limit=2G",
    "phpstan-simplified": "vendor/bin/phpstan analyse --memory-limit=2G --error-format symplify",
    "phpstan-clear-cache": "vendor/bin/phpstan clear-result-cache",
    "format": "vendor/bin/pint",
    "rector": "vendor/bin/rector process",
    "test": "vendor/bin/pest",
    "test-coverage": "vendor/bin/pest --coverage",
    "sync-ai": "vendor/bin/boost sync",
    "qa": ["@rector", "@format", "@phpstan-simplified"],
    "post-install-cmd": ["SanderMuller\\BoostCore\\Scripts\\BoostAutoSync::run"],
    "post-update-cmd": ["SanderMuller\\BoostCore\\Scripts\\BoostAutoSync::run"]
  }
}
```

Substitutions:

- `test`/`test-coverage` → `vendor/bin/phpunit` when `test-framework=phpunit`
- `sync-ai` is dropped for `laravel-project` (it uses `laravel/boost`, not `boost-core`; AI assets sync via `php artisan boost:install` / `boost:update`)

Always added for `laravel-package` (per RQ13 — the `--with-workbench-scripts` flag from earlier drafts is dropped; observed across all canonical sander L-packages):

```json
{
  "scripts": {
    "post-autoload-dump": ["@clear", "@prepare"],
    "clear": "@php vendor/bin/testbench package:purge-skeleton --ansi",
    "prepare": "@php vendor/bin/testbench package:discover --ansi",
    "build": "@php vendor/bin/testbench workbench:build --ansi",
    "serve": ["Composer\\Config::disableProcessTimeout", "@build", "@php vendor/bin/testbench serve --ansi"]
  }
}
```

### 5.5 PHPStan config (`references/phpstan-config.md`)

Always:

```neon
includes:
    - phpstan-baseline.neon
    - phar://phpstan.phar/conf/bleedingEdge.neon
    - vendor/spaze/phpstan-disallowed-calls/disallowed-{dangerous,execution,insecure}-calls.neon
parameters:
    tmpDir: .cache/phpstan
    level: max
    strictRules:
        allRules: true
    editorUrl: 'phpstorm://open?file=%%file%%&line=%%line%%'
    type_coverage: { return: 100, param: 100, property: 100, constant: 0, declare: 100 }
    type_perfect: { null_over_false: true, narrow_return: true }
    cognitive_complexity: { class: 80, function: 20 }
```

Per-category `paths:` and extra `includes:`:

| Category | `paths:` | Extra `includes:` |
|---|---|---|
| `laravel-project` | `[app, routes, config, database, tests]` | `vendor/hihaho/phpstan-rules/extension.neon` when `--with-hihaho-rules` |
| `laravel-package` | `[src, tests, workbench]` | (Larastan auto-included via `phpstan/extension-installer`) |
| `php-package` | `[src, tests]` | (no Laravel-specific includes) |
| `phpstan-extension` | `[src, tests]` | the package's own `extension.neon` (already in `extra.phpstan.includes`) |
| `rector-extension` | `[src, tests]` | (none) |

### 5.6 Rector config (`references/rector-config.md`)

Always:

```php
return RectorConfig::configure()
    ->withCache(cacheDirectory: './.cache/rector', cacheClass: FileCacheStorage::class)
    ->withImportNames()
    ->withFluentCallNewLine()
    ->withParallel(300, 15, 15)
    ->withMemoryLimit('3G')
    ->withPhpSets(php{XX}: true)        // {XX} from --php
    ->withPreparedSets(deadCode: true, codeQuality: true, codingStyle: true,
        typeDeclarations: true, typeDeclarationDocblocks: true,
        privatization: true, instanceOf: true, earlyReturn: true);
```

Per-category `withPaths` and `withSets`:

| Category | `withPaths` | Extra `withSets` |
|---|---|---|
| `laravel-project` | `app, routes, config, database, tests` | `LaravelSetList::LARAVEL_*`, `Hihaho\RectorRules\Sets::ALL` when `--with-hihaho-rules` |
| `laravel-package` | `src, tests, workbench` | `LaravelSetList::LARAVEL_*`, `PestSetList::*` when pest |
| `php-package` | `src, tests` | `PestSetList::*` when pest |
| `phpstan-extension` | `src, tests` | (none) |
| `rector-extension` | `src, tests, config` | (none) |

### 5.7 PHP floor — `^8.3` minimum

All categories floor at PHP `^8.3`. The `--php=` flag accepts `8.3`, `8.4`, or `8.5` only; `8.2` is rejected at the prompt and in the flag parser.

Rationale: a hard floor avoids the matrix-of-matrices problem (each PHP × Laravel × test-framework cell that has to be tested) and unblocks every shared dep — `laravel/pao` (`^8.3`), the strictest. Existing `^8.2` repos audited by repo-init will be flagged as `NON-CANONICAL` on the `require.php` constraint; the upgrade phase offers to bump the floor as a single composer.json edit.

---

## 6. Never-Touch List (`checklists/per-category-never-touch.md`)

Files the agent must never write, regardless of phase. **Per-mode scope:**

- **Bootstrap mode:** target dir is empty (modulo `.git/`) — the cwd-empty precondition is the protection. The git-dirty rule is *not* applied; new files from `laravel new` are expected to be untracked at the moment the bootstrap phase starts writing on top of them. The security never-touch paths below still apply for `laravel-project` bootstrap (we never write to `config/auth*.php` even when overlaying onto a fresh `laravel new` output).
- **Audit / Upgrade mode:** both the security never-touch paths AND the git-dirty rule are applied. Agent runs `git status --porcelain` before any write and skips paths with prefixes `M`, `M`, `MM`, `A`, `??`. Override requires explicit per-file user opt-in.

**`laravel-project` security never-touch (all modes):**

- `app/Http/Middleware/Authenticate.php`
- Anything under `app/Policies/`, `app/Http/Middleware/`
- `config/auth.php`, `config/sanctum.php`, `config/permission.php`, any `config/auth*.php`
- `routes/auth.php`
- `.env`, `.env.*` (except `.env.example` on bootstrap only)

**All categories security never-touch (all modes):**

- Anything matching a `.env*` glob (except `.env.example` on bootstrap)
- Anything under `.git/`, `vendor/`, `node_modules/`

---

## 7. Bootstrap Phase Pattern (`phases/bootstrap-*.md`)

> **Note (v7 alignment).** The step list below describes the *project-local install* shape from the early-draft SPEC. The current v7 global-install architecture (per RQ40 + §3.3 / §3.3.1) means steps 9–10 below (`testbench package-boost:install --all` and project-local `:sync`) are SKIPPED by default — repo-init is installed globally and the skill is synced once at `composer global require` time, not per-target. Phase 9 step 9 in the actual `phases/bootstrap-laravel-package.md` (and siblings) reflects this. The example below is kept for reference but the live phase files are authoritative.

Each bootstrap phase file follows the same shape. Example: `phases/bootstrap-laravel-package.md`.

```markdown
# Bootstrap: laravel-package

## Pre-flight
Run checklists/preflight.md first. Stop if anything is red.

## Inputs to collect
- vendor (required)
- name (optional, kebab-case — see target-dir rule below)
- php (default 8.3)
- laravel (default ^11||^12||^13)
- test-framework (default pest)
- description (one line)
- author-name, author-email (default from git config)

## Steps

1. Pre-flight: confirm `vendor/sandermuller/repo-init/` exists (skill's §3.3 handles install + sync if not).
2. Apply the target-dir rule (§3.3.1):
   - If user passed a positional `name`: create `./<name>/` and cd into it.
   - Otherwise: target IS cwd. Verify cwd is empty except for `.git/`; if violated, stop and ask the user for a `name`.
3. Read stubs from `vendor/sandermuller/repo-init/stubs/shared/`. Substitute placeholders (per §2 transform table). Write to cwd.
4. Read stubs from `vendor/sandermuller/repo-init/stubs/laravel-package/` (or `laravel-package-spatie/` per sub-flag). Substitute. Write.
5. Compose the test-framework variant: copy `tests/Pest.php` (pest) or `phpunit.xml` (phpunit) from `stubs/shared/`.
6. Write `composer.json` (assembled from the category stub + script block from `references/composer-scripts.md`).
7. Run `composer install`.
8. Run `composer require --dev` with the dep list from `references/shared-dev-deps.md` + `references/per-category-deps.md#laravel-package`. Apply the test-framework split (§5.1). Handle composer failures per `references/composer-failure-modes.md`.
9. Run `vendor/bin/testbench package-boost:install --all` (or `--agents=claude_code` per user preference).
10. Run `vendor/bin/testbench package-boost:sync`.
11. Run post-bootstrap verification (`checklists/post-bootstrap-verification.md`).
12. Print next steps (write first test, set up GitHub remote, etc.) AND ask the user: "Want to run an audit / upgrade next, or are you done with repo-init for now?"

## Verification
Open `checklists/post-bootstrap-verification.md` and confirm every item.

## What's next
- User wants to keep working: open the next phase file (e.g. `audit-laravel-package.md`).
- User is done: open `checklists/self-removal.md` (final, one-shot).
```

Other categories follow the same shape with adjusted step lists. Notable differences:

- `bootstrap-laravel-project.md` wraps `laravel new <name> --boost --git --no-interaction` as step 2 instead of copying stubs. Steps 3–10 then layer additions on top, prompting per-file when the Laravel installer wrote something the stub would overwrite.
- `bootstrap-phpstan-extension.md` and `bootstrap-rector-extension.md` add a step for writing the `extension.neon` / `config/config.php` and wiring `extra.phpstan.includes` / `extra.rector.includes`.
- `bootstrap-php-package.md` adds steps for `.lpv` and `PUBLIC_API.md`; skips the `extra.laravel.providers` wiring entirely.

---

## 8. Audit Phase Pattern (`phases/audit-*.md`)

Each audit file is a structured checklist with four severity buckets matching the original spec's taxonomy:

```markdown
# Audit: laravel-package

## Pre-flight
Run checklists/preflight.md.

## MISSING files (must be present)
Check each path; if absent, mark MISSING and add to the audit report.
- [ ] .editorconfig
- [ ] .gitattributes (with package-boost managed block)
- [ ] .gitignore
- [ ] .mcp.json
- [ ] pint.json
- [ ] phpstan.neon.dist
- [ ] phpstan-baseline.neon
- [ ] rector.php
- [ ] phpunit.xml OR tests/Pest.php (per test-framework)
- [ ] testbench.yaml
- [ ] workbench/app/Providers/WorkbenchServiceProvider.php
- [ ] .github/workflows/phpstan.yml
- [ ] .github/workflows/pint-check.yml
- [ ] .github/workflows/rector-check.yml
- [ ] .github/workflows/run-tests.yml
- [ ] .github/workflows/update-changelog.yml
- [ ] .github/dependabot.yml
- [ ] CLAUDE.md (generated by package-boost; surface as MISSING if no AGENTS.md either)

## Opt-in confirmation (audit-scoping)
Before walking deps, ask the user once per OPTIONAL/CONDITIONAL dep block in §5.2:
- Did this repo opt into hihaho rules? (auto-infer `y` if vendor is hihaho or `hihaho/phpstan-rules` is already in require-dev)
- Did this repo opt into security advisories? (auto-infer `y` if `roave/security-advisories` is already in require-dev)
- Is this package Laravel-aware? (only for phpstan-extension/rector-extension; auto-infer `y` if `illuminate/*` in require)
- Is this a spatie-flavoured L-package? (only for laravel-package; auto-infer `y` if `spatie/laravel-package-tools` is in require)
Record each answer; only flag the deps in opt-in-confirmed rows as MISSING below.

## MISSING runtime deps (must be in require)
Read composer.json. For each dep in §5.2 MANDATORY "Adds to `require`" column for this category, mark MISSING if absent.
For each confirmed-opt-in row in §5.2 OPTIONAL/CONDITIONAL "Adds to `require`", same check.
Skip opted-out rows entirely.

Apply per-category exclusions (§5.1.1) — a dep that this category puts in `require` is NOT additionally expected in `require-dev`.

## MISSING dev deps (must be in require-dev)
Read composer.json. For each dep in §5.1 shared list (minus §5.1.1 per-category exclusions) + §5.2 MANDATORY "Adds to `require-dev`" column, mark MISSING if absent.
For each confirmed-opt-in row in §5.2 OPTIONAL/CONDITIONAL "Adds to `require-dev`", same check.
Skip opted-out rows entirely.

`livewire/livewire` and other rows tagged "suggest only" are never audited.

## OUTDATED files
For each file present, look up its **merge mode** in `references/upgrade-merge-modes.md` and apply the matching detector:
- `replace` files (workflows, dependabot.yml, .editorconfig) — diff against stub; any difference is OUTDATED.
- `managed-block` files (.gitattributes) — diff *only inside* the package-boost managed block; flag OUTDATED if our entries inside the block drift.
- `append-only` files (.gitignore) — flag MISSING per line we expect but is absent. Never OUTDATED — extra lines are allowed.
- `merge-keys` files (composer.json) — flag MISSING per key we expect, walking each documented section: `scripts`, `extra.laravel.providers`, `extra.phpstan.includes`, `extra.rector.includes`, `config.allow-plugins`, `config.sort-packages`, `autoload-dev.classmap` (per category — see §9 for the section-to-category map). Never OUTDATED for whole-file diff.
- `notify-only` files (phpstan.neon.dist, rector.php, pint.json, phpstan-baseline.neon) — never flag OUTDATED automatically. User owns these. Mention drift in audit report as informational only.

## NON-CANONICAL files
- [ ] composer.lock committed (libraries should not commit lockfiles) — flag as NON-CANONICAL
- [ ] phpunit.xml vs phpunit.xml (prefer .dist) — flag as NON-CANONICAL
- [ ] Two managed blocks in .gitattributes (only package-boost's should exist; see `references/gitattributes-managed-block.md`)

## EXTRA files / deps
Informational only — do not remove. Just list.

## Report
Present findings to the user, grouped by severity, with file paths and dep names. Findings live in the conversation — no state file written to the target repo. Ask whether to proceed to `phases/upgrade-laravel-package.md` (which re-runs the audit fresh as its first step, so a new conversation session re-derives findings instead of relying on persisted state).
```

The structure is identical across categories; only the file list and dep list change.

---

## 9. Upgrade Phase Pattern (`phases/upgrade-*.md`)

Each upgrade file consumes the audit report and walks the agent through applying it. The agent does the diffing and prompting natively — there is no UI for the package to ship.

```markdown
# Upgrade: laravel-package

## Pre-flight
Run checklists/preflight.md. Re-run the audit phase first so the upgrade operates on a fresh, in-conversation finding list (no persisted state to drift).

## Apply MISSING files
For each MISSING file from the just-run audit:
- Read the stub from `vendor/sandermuller/repo-init/stubs/`.
- Substitute placeholders using the inputs collected from the user.
- Write to target path.

## Apply MISSING runtime deps
Run a single `composer require <list>` for all MISSING runtime deps.

## Apply MISSING dev deps
Run a single `composer require --dev <list>` for all MISSING dev deps.
Respect the larastan-vs-phpstan exclusivity rule (§5.3).
Handle composer failures per `references/composer-failure-modes.md`.

## Apply OUTDATED files (per merge mode)
For each OUTDATED file, apply the merge mode from `references/upgrade-merge-modes.md`:
- `replace` — show unified diff, prompt: write / skip / backup-and-write (rename existing to `<path>.bak.<timestamp>`) / abort.
- `managed-block` — patch only inside the managed block; never touch lines outside.
- `append-only` — append missing lines only; never remove or reorder existing.
- `merge-keys` — patch only the listed keys; never touch other top-level keys.
- `notify-only` — surface drift to user, do nothing automatically.
Respect the never-touch list (`checklists/per-category-never-touch.md`) and git-dirty rule for audit/upgrade mode (§6).

## Apply composer.json merge-keys patches
The auditor reports MISSING keys per documented composer.json section. For each, insert/patch only the listed keys; never touch sibling keys.

- **`scripts`** — For each script in `references/composer-scripts.md` not present, insert it.
- **`extra.laravel.providers`** (laravel-package only) — If missing, add the ServiceProvider FQCN derived from `__NAMESPACE__\\__PACKAGE_STUDLY__ServiceProvider`.
- **`extra.phpstan.includes`** (phpstan-extension only) — If missing, add `["extension.neon"]` (or merge if existing array doesn't contain it).
- **`extra.rector.includes`** (rector-extension only) — If missing, add `["config/config.php"]` (or merge).
- **`config.allow-plugins`** — Ensure required plugin entries exist: `pestphp/pest-plugin` (when test-framework=pest), `phpstan/extension-installer` (always), `rector/extension-installer` (rector-extension only).
- **`config.sort-packages`** — If absent, add `true`.
- **`autoload-dev.classmap`** (phpstan-extension only) — If `tests/Rules/stubs/` exists but isn't in classmap, add it.

Per-key writes use the `merge-keys` mode from `references/upgrade-merge-modes.md` — surgical JSON patches, no whole-file rewrite, no reordering of other keys.

## NON-CANONICAL fixes
For each NON-CANONICAL finding:
- composer.lock → ask user whether to `git rm --cached composer.lock` and add to .gitignore.
- phpunit.xml → ask whether to rename to phpunit.xml (only if phpunit.xml doesn't exist).
- PHP floor `^8.2` → ask whether to bump to `^8.3` (one-line composer.json edit).

## Verification
Open `checklists/post-upgrade-verification.md`.

## What's next
- User wants to keep working: open the next phase file (or re-audit).
- User is done: open `checklists/self-removal.md` (final, one-shot).
```

---

## 10. Self-Removal (`checklists/self-removal.md`)

Self-removal is the explicit final step of the user's repo-init session — invoked once, not after every phase.

```markdown
# Self-removal — final step only

Pre-conditions:
- [ ] User has explicitly said they're done with repo-init for this repo.
- [ ] No half-finished writes (last phase ran to completion or the user aborted cleanly).
- [ ] No unstaged repo-init-driven changes pending review.

Decision — does the skill need to survive?
- If user wants `.claude/skills/repo-init/SKILL.md` to remain in the target (so they can re-invoke without re-installing the source): confirm it was synced by package-boost (it should be, from the post-install or manual sync). Note: re-invoking the skill without the package installed will fail at the first vendor/ read — the skill body explicitly checks and will re-prompt to install. This is by design.
- If user wants a clean removal: also delete `.claude/skills/repo-init/`, `.cursor/skills/repo-init/`, etc. (one-line `rm -rf`).

Run:
   composer remove --dev sandermuller/repo-init

Verify:
- [ ] `vendor/sandermuller/repo-init/` is gone.
- [ ] `composer.lock` regenerated cleanly (no orphan lock entries).
- [ ] If user kept the synced skill: confirm `.claude/skills/repo-init/SKILL.md` still on disk.

User can re-install at any future date with `composer require --dev sandermuller/repo-init` to resume audit/upgrade work; nothing here is destructive.
```

Notable: nothing about state files, no audit-report cleanup, no playbook deletion — because there are no temp files, no state files, and no playbook copies in the target. The package itself is the only artefact, and `composer remove` deletes it cleanly.

---

## 11. References Details

Brief summary of each reference file's purpose. Each is a flat markdown doc the agent reads on demand.

- `references/detection-rules.md` — §4 in this spec
- `references/shared-dev-deps.md` — single bullet list of universal deps + version floors
- `references/per-category-deps.md` — §5.2 of this spec
- `references/composer-scripts.md` — §5.4
- `references/phpstan-config.md` — §5.5
- `references/rector-config.md` — §5.6
- `references/canonical-repos.md` — links to the reference repos per category: `SanderMuller/laravel-queue-insights`, `SanderMuller/solana-pubkey`, `SanderMuller/laravel-fluent-validation-phpstan`, `SanderMuller/laravel-fluent-validation-rector`, `hihaho/pipedrive-migration-tool`. Includes "what to look at" notes per file.
- `references/version-defaults.md` — default PHP (`8.3`), Laravel range (`^11||^12||^13`), Pest (`^4.0`), test-framework defaults per vendor.
- `references/pest-vs-phpunit.md` — when to use which; vendor-driven default (sander=pest, hihaho=phpunit, phpstan-extension=always phpunit).
- `references/gitattributes-managed-block.md` — explains the package-boost managed block, why repo-init's stub appends to it rather than creating a second block, and the fallback if package-boost's block is absent.
- `references/upgrade-merge-modes.md` — per-file merge mode declaration: `replace` / `managed-block` / `append-only` / `merge-keys` / `notify-only`. Audit + upgrade phases consult this so OUTDATED detection isn't a blunt whole-file diff (codex v3 #7).
- `references/composer-failure-modes.md` — common composer-install / require failures (version conflict, package not found, conflicting deps, PHP-version-not-satisfied, transitive lock conflict) with the resolution playbook (re-prompt user for narrower constraints, fall back to per-package require, escalate to user). Cited from bootstrap step 8 and upgrade dep-application steps.
- `references/placeholder-rules.md` — exact StudlyCase derivation rule, edge cases (digits, mixed case, hyphenated multi-word), examples for every placeholder in §2.

---

## 12. Eat-Own-Dogfood

Because the package is pure markdown + stubs, it doesn't have its own composer scripts to run, no tests to write, no PHPStan to configure. The package's own dev tooling is *just* `package-boost:sync` to propagate its skill, plus a markdown lint hook in CI.

The "dogfood" property therefore reduces to: every stub in `stubs/` was generated by hand from the canonical reference repos and reviewed against the latest production package's actual file. A snapshot test in CI (one of the few CI jobs the package needs) does the inverse — diffs each stub against the matching file in the canonical repo, prints a warning if they drift more than N lines. This is the closest we get to "the tool tests itself" without writing a generator.

---

## Implementation

### Phase 1: Skill + Detection + Shared Stubs + References (Priority: HIGH)

- [ ] Write `.ai/skills/repo-init/SKILL.md` with the three-step entry flow (§3) including §3.3 install-then-sync pre-flight AND §3.3.1 greenfield-package install prelude
- [ ] Write `references/detection-rules.md` with the §4 decision table + sub-flags + error cases
- [ ] Write `references/canonical-repos.md` with the five canonical reference links
- [ ] Write `references/shared-dev-deps.md` (§5.1 list + §5.1.1 per-category exclusions)
- [ ] Write `references/per-category-deps.md` (split into MANDATORY vs OPTIONAL/CONDITIONAL per §5.2)
- [ ] Write `references/per-category-deps.yml` — machine-readable parallel of the same content (one entry per category, with `mandatory.require`, `mandatory.require-dev`, `optional.<opt-in-name>.require`, `optional.<opt-in-name>.require-dev` keys). Phase 7 sync check parses this; phase markdown files cite dep names matching the YAML.
- [ ] Write `references/composer-scripts.md`, `references/phpstan-config.md`, `references/rector-config.md`, `references/version-defaults.md`, `references/pest-vs-phpunit.md`, `references/gitattributes-managed-block.md`
- [ ] Write `references/upgrade-merge-modes.md` — `replace`/`managed-block`/`append-only`/`merge-keys`/`notify-only` mode per stub file (REQUIRED by Phase 4 audit + Phase 5 upgrade)
- [ ] Write `references/composer-failure-modes.md` — common failure → resolution playbook (REQUIRED by Phase 3 bootstrap + Phase 5 upgrade)
- [ ] Write `references/placeholder-rules.md` — StudlyCase derivation + edge cases (REQUIRED by Phase 3 bootstrap step that fills stubs)
- [ ] Write `checklists/preflight.md`, `checklists/per-category-never-touch.md`, `checklists/self-removal.md`
- [ ] Copy `stubs/shared/` files from canonical reference (`SanderMuller/laravel-queue-insights`): `.editorconfig`, `.gitattributes`, `.gitignore`, `.mcp.json`, `pint.json`, `phpstan-baseline.neon`, `phpunit.xml`, `tests/Pest.php`, `.github/workflows/*.yml`, `.github/dependabot.yml`. Replace concrete repo names with `__VENDOR__` / `__PACKAGE__` placeholders.
- [ ] Write the package's own `composer.json` (per §2 bottom) with the `post-install-cmd` hook
- [ ] Tests — markdown lint on all phase + reference + checklist files (placeholder-coverage moves to Phase 2 where stubs actually exist)

### Phase 2: Per-Category Stubs (Priority: HIGH)

- [ ] `stubs/laravel-package/` — composer.json (from queue-insights — sander-style ServiceProvider, no spatie/laravel-package-tools), testbench.yaml, ServiceProvider skeleton, config skeleton, phpstan.neon.dist + rector.php with category-specific paths, run-tests.yml matrix
- [ ] `stubs/laravel-package-spatie/` — composer.json (from hihaho/laravel-js-store style — `spatie/laravel-package-tools` in `require`), testbench.yaml, ServiceProvider skeleton extending `PackageServiceProvider`, config skeleton, phpstan.neon.dist + rector.php, run-tests.yml. **Required by RQ18; selected when sub-flag `hihaho-package-tools-flavoured` is set OR `--variant=spatie`.**
- [ ] `stubs/php-package/` — composer.json (from solana-pubkey), .lpv, PUBLIC_API.md, src skeleton, phpstan.neon.dist + rector.php, run-tests.yml
- [ ] `stubs/phpstan-extension/` — composer.json (from laravel-fluent-validation-phpstan), extension.neon with parametersSchema/parameters/services skeleton, .gitkept dirs, phpstan.neon.dist + rector.php, run-tests.yml
- [ ] `stubs/rector-extension/` — composer.json (from laravel-fluent-validation-rector — `rector/rector` in `require` only, NOT `require-dev` per §5.1.1), config/config.php skeleton, .gitkept dirs, phpstan.neon.dist + rector.php, run-tests.yml
- [ ] `stubs/laravel-project/` — boost.json, phpstan.neon.dist with Laravel paths, rector.php with hihaho sets, README.append.md
- [ ] Tests — snapshot CI job that diffs each stub against the matching file in the canonical reference repo; warns if drift exceeds threshold. Placeholder-coverage test (every placeholder in §2 used in at least one stub; every placeholder used in a stub defined in §2) — moved here from Phase 1 because it needs Phase 2's stubs to exist.

### Phase 3: Bootstrap Phases (Priority: HIGH)

- [ ] `phases/bootstrap-laravel-package.md` — full step list per §7
- [ ] `phases/bootstrap-php-package.md`
- [ ] `phases/bootstrap-phpstan-extension.md`
- [ ] `phases/bootstrap-rector-extension.md`
- [ ] `phases/bootstrap-laravel-project.md` — wraps `laravel new <name> --boost`; layers stubs on top
- [ ] All bootstrap phases include the §3.3.1 greenfield install prelude (`mkdir`, `composer init`, `composer require --dev sandermuller/repo-init`) BEFORE the first stub-copy step. `bootstrap-laravel-project.md` substitutes `laravel new <name>` for the mkdir+composer-init steps.
- [ ] `checklists/post-bootstrap-verification.md` — common verification items (composer install ok, vendor/ populated, tests run, phpstan passes initial smoke)
- [ ] Tests — markdown lint; spec-link audit (every reference cited in a phase file exists in references/); greenfield-bootstrap-contract test (assert each bootstrap phase has the prelude steps in order)

### Phase 4: Audit Phases (Priority: HIGH)

- [ ] `phases/audit-laravel-package.md` — full checklist per §8: opt-in confirmation prompt FIRST, then MANDATORY runtime+dev deps, then OPTIONAL deps (only for confirmed opt-ins), then OUTDATED files per merge mode, then composer.json merge-keys per §9 (scripts + extra.*+ config.* + autoload-dev), then NON-CANONICAL
- [ ] `phases/audit-php-package.md` (no Laravel opt-in path; spatie variant N/A)
- [ ] `phases/audit-phpstan-extension.md` (Laravel-aware opt-in detected from `illuminate/*` presence)
- [ ] `phases/audit-rector-extension.md` (Laravel-aware opt-in detected from `driftingly/rector-laravel` presence)
- [ ] `phases/audit-laravel-project.md` (hihaho-rules + security-advisories opt-ins)
- [ ] Tests — markdown lint; verify every audit file's MISSING-files list matches §2 stub layout for that category; verify every audit file walks both MANDATORY columns AND walks OPTIONAL only on confirmed opt-in (audit-scoping test); verify per-category exclusions (§5.1.1) are honoured (no dep in both require and require-dev)

### Phase 5: Upgrade Phases (Priority: HIGH)

- [ ] `phases/upgrade-laravel-package.md` — full step list per §9: re-audit first, MISSING-runtime-deps + MISSING-dev-deps (separate composer require calls), OUTDATED files per merge mode, composer.json merge-keys (scripts + extra.*+ config.* + autoload-dev), NON-CANONICAL fixes
- [ ] `phases/upgrade-php-package.md`
- [ ] `phases/upgrade-phpstan-extension.md`
- [ ] `phases/upgrade-rector-extension.md`
- [ ] `phases/upgrade-laravel-project.md`
- [ ] `checklists/post-upgrade-verification.md` — phpstan green, pint clean, rector dry-run clean, tests still passing
- [ ] Tests — markdown lint; check that each upgrade phase explicitly references both the never-touch checklist and the git-dirty guard step; merge-keys-covers-extra test (assert every documented `extra.*` key in §9 has a corresponding step in at least one upgrade phase)

### Phase 6: Docs & Release (Priority: MEDIUM)

- [ ] `README.md` — human quick-start: `composer require --dev sandermuller/repo-init`, then "ask Claude to set up this repo", then `composer remove --dev sandermuller/repo-init`
- [ ] `CHANGELOG.md` — initial `0.1.0` entry
- [ ] Tag `0.1.0`, publish to Packagist
- [ ] Tests — README links audit; readme-listed flags exist in SKILL.md and at least one phase file

### Phase 7: Drift Detection + Integrity CI (Priority: MEDIUM)

- [ ] **Path-integrity check** — script that walks every `.md` under `phases/`, `checklists/`, `references/`, and `.ai/skills/repo-init/SKILL.md`; extracts every relative path (`vendor/sandermuller/repo-init/stubs/...`, `references/...`, `checklists/...`, `phases/...`) and asserts each one exists in the package. Fails CI on dead links.
- [ ] **Phase-coverage check** — assert every `(category × mode)` phase file references the shared checklists it needs (preflight, never-touch, post-*-verification, self-removal) and the category-specific reference docs.
- [ ] **Dep-source-of-truth sync check** — `references/per-category-deps.yml` is the machine-readable parallel of `per-category-deps.md` (same content, structured). CI parses the YAML and asserts: (a) every dep appears in only one scope per category (no-dep-in-both-scopes); (b) every dep is referenced by name in the corresponding audit phase's MISSING-* checklist; (c) every dep is referenced by name in the corresponding upgrade phase's composer-require list. The phase markdown files cite specific dep names inline (e.g. "Check require-dev for `larastan/larastan`") so the grep is deterministic. This replaces v5's "parse the markdown" approach which codex correctly flagged as not enforceable.
- [ ] **No-dep-in-both-scopes check** — derived from the YAML parser above; explicit assertion per category.
- [ ] **Audit-scoping check** — for every audit phase, assert OPTIONAL/CONDITIONAL deps are gated behind opt-in confirmation. A phase that flags `hihaho/phpstan-rules` MISSING without first asking "did you opt into hihaho rules?" fails CI (codex v4 #3).
- [ ] **Merge-keys covers extras check** — assert each upgrade phase covers every documented composer.json key in §9 (`scripts`, `extra.laravel.providers`, `extra.phpstan.includes`, `extra.rector.includes`, `config.allow-plugins`, `config.sort-packages`, `autoload-dev.classmap`), not just `scripts` (codex v4 #4).
- [ ] **Layout-matches-resolved-Qs check** — assert `stubs/laravel-package-spatie/`, `references/upgrade-merge-modes.md`, `references/composer-failure-modes.md`, `references/placeholder-rules.md` exist (codex v4 #5 protection).
- [ ] **Placeholder-coverage check** — assert every placeholder defined in §2 transform table is used in at least one stub; assert every placeholder used in a stub is defined in §2.
- [ ] **Self-removal verification doc** — `tests/self-removal-contract.md` documents the survives-vs-clean tradeoff and links to package-boost's authoritative behaviour (skill copies, doesn't symlink).
- [ ] **Stub drift detection** — GitHub Actions workflow that fetches each canonical repo (`SanderMuller/laravel-queue-insights`, `SanderMuller/solana-pubkey`, etc.) via `gh api`, diffs the relevant files against `stubs/`, and warns when drift exceeds a per-file threshold.
- [ ] Schedule weekly; open an issue if drift detected; include suggested patch.
- [ ] Tests — workflow self-test (run against a known-stale fixture, confirm it warns); path-integrity self-test (deliberately introduce a dead link in a phase file, confirm CI fails).

### Phase 8: Extras (Priority: LOW)

- [ ] `phases/bootstrap-filament-plugin.md` + `stubs/filament-plugin/`
- [ ] `phases/bootstrap-nova-tool.md` + `stubs/nova-tool/`
- [ ] `references/branch-alias.md` — when to add `extra.branch-alias` for early-stage packages
- [ ] `references/bin-scripts.md` — when a pure-PHP package should ship a `bin/`
- [ ] Tests — extend snapshot CI to cover new categories

---

## Open Questions

1. ~~**`--ai` flag on `laravel new`.**~~ **Resolved (2026-05):** the installer ships no `--ai` / `--with-ai` flag. The functional equivalent is `--boost` (installs `laravel/boost`, which writes `boost.json`, `.mcp.json`, AGENTS.md, CLAUDE.md). Agent-context auto-detection happens via env, no flag needed. `bootstrap-laravel-project.md` + audit / common-issues sections use `--boost` / `--no-boost`.

2. **`.gitattributes` managed-block contract with package-boost.** The shared `.gitattributes` stub assumes package-boost will accept entries appended into its managed block by downstream tools. Confirm with the package-boost maintainer and document in `references/gitattributes-managed-block.md`. If rejected, fall back to a separate `# >>> repo-init (managed) >>>` block and downgrade the "NON-CANONICAL: two managed blocks" audit finding.

3. **Package-boost user-scope sync feature.** RQ40 + §3.5 depend on a new `package-boost:sync --scope=user` command. Currently package-boost only syncs into the current project's `.claude/skills/`. Add the user-scope feature (~30 LOC change in package-boost), document the contract in `references/boost-core-user-scope.md`, ship before repo-init v0.1.

4. **Skill propagation guarantee.** §10 assumes package-boost copies (not symlinks) skills into `.claude/skills/`. Verify this is still true and document the behaviour as a load-bearing contract.

---

## Resolved Questions

1. **Architecture — code vs docs.** **Decision:** Zero PHP code. Pure markdown phases + checklists + references + stub files. Composer-installable purely so package-boost can sync the `.ai/skills/repo-init/` into the target's agent dirs. **Rationale:** The original spec invented a Symfony Console binary + artisan command layer + handler classes to do work that the AI agent does natively. Removing that layer collapses ~600 lines of spec into ~300 and eliminates an entire test surface.

2. **Greenfield target-directory behaviour.** **Decision:** Mirror `laravel new {name}` exactly — positional `name` creates a subdir; absent `name` scaffolds into cwd (empty modulo `.git/`). Phase files spell this out. **Rationale:** Matches well-known UX; no surprise.

3. **Bootstrap chicken-and-egg.** **Decision:** No longer applies — agent runs the steps itself, with no PHP/artisan/binary entry point. The package is installed in the target repo *after* `composer init` (or `laravel new`) as a dev dep so the skill propagates. **Rationale:** The chicken-and-egg only existed because the previous architecture assumed a command runner.

4. **Number / shape of phase files.** **Decision:** 15 files, one per (category × mode). Each is self-contained — agent reads top-to-bottom. **Rationale:** Avoids cross-file navigation mid-flow; each file fits on screen.

5. **Detection.** **Decision:** Inline checklist in `references/detection-rules.md`. Agent reads composer.json itself. **Rationale:** No code, no programmatic detector to maintain.

6. **Dry-run / force / state / resume.** **Decision:** All delegated to the agent's native facilities. The package never ships dry-run-equivalent semantics. **Rationale:** Agent already handles task lists, partial-failure resume, diff-and-prompt natively; reinventing them in PHP was duplication.

7. **PHPStan `paths:` per category.** **Decision:** As §5.5 table — `laravel-project` uses `[app, routes, config, database, tests]`; other categories use `[src, tests]` (+ workbench for laravel-package). **Rationale:** Original spec's "identical paths" claim was wrong; this carries over from v2 review.

8. **PHPUnit-vs-Pest choice.** **Decision:** Vendor-driven default (sander=pest, hihaho=phpunit), `phpstan-extension` always phpunit. Documented in `references/pest-vs-phpunit.md`. **Rationale:** Observed split in canonical reference repos.

9. **`larastan` vs `phpstan/phpstan` exclusivity.** **Decision:** Per §5.3 — exactly one per category, never both. Phase files spell this out. **Rationale:** Transitive dep conflict on next major.

10. **`category_confidence`.** **Decision:** Dropped. Audit phase records `detection_rule` (which row of §4 matched) instead. **Rationale:** Detector is deterministic; confidence was invented.

11. **Testbench in dev deps.** **Decision:** Always added. **Rationale:** `package-boost:sync` runs through testbench across every category. **Superseded (v7):** AI-asset sync no longer runs through testbench — `boost-core` ships a standalone `vendor/bin/boost` bin. `orchestra/testbench` stays in the shared dev-dep list as the **package test bootstrap**, and `composer-plugin` excludes it (no Laravel runtime). See `references/shared-dev-deps.md`.

12. **Conditional post-install hook.** **Decision:** Always added — `if [ $COMPOSER_DEV_MODE = "1" ]; then vendor/bin/testbench package-boost:sync 2>/dev/null || true; fi`. **Rationale:** Auto-syncs AI assets after dev installs; matches the laravel-x402-mcp pattern. **Superseded (v7):** the POSIX-shell hook is Windows-broken and is replaced — `post-install-cmd` and `post-update-cmd` now both invoke the boost-core PHP callback `SanderMuller\BoostCore\Scripts\BoostAutoSync::run` (silent on no-op installs; prints the one-line sync summary when `wrote>0` — boost-core ≥0.6.0). An intermediate v8-era wiring used `::runWithSummary` for these hooks; that was wrong (auto-firing hooks should be silent-on-no-op, otherwise routine `composer install` runs always print a summary as noise). `::runWithSummary` remains correct for user-invoked scripts (e.g. `composer sync-ai`). See §5.4 and `references/composer-scripts.md`.

13. **Workbench scripts.** **Decision:** Always added for `laravel-package`. **Rationale:** All canonical sander L-packages have them.

14. **PHP floor.** **Decision:** Hard minimum `^8.3` across all categories. `--php=` accepts `8.3` / `8.4` / `8.5` only. **Rationale:** Matches `laravel/pao`'s floor (our strictest shared dep); avoids per-PHP matrix sprawl; existing `^8.2` repos audited by repo-init get a `NON-CANONICAL` finding with a one-line composer.json bump as the upgrade path.

15. **Socialite-provider detection.** **Decision:** `socialiteproviders/manager` in require → `laravel-package` even without `extra.laravel.providers`. **Rationale:** Otherwise `sandermuller/socialite-solana` classifies as `unknown`.

16. **Git-dirty guard.** **Decision:** Agent runs `git status --porcelain` before any write and skips paths flagged as modified/staged/untracked. Override only with explicit per-file user opt-in. **Rationale:** Untracked-file hole flagged in v2 review; agent enforces in phase files.

17. **Pest floor for shipped stub.** **Decision:** Pin shared dep to `^4.0`. Bundled `tests/Pest.php` uses Pest 4 idioms. **Rationale:** One stub, no agent-side choice. Document the Pest 3 → 4 upgrade in `references/version-defaults.md` for adopters bumping into the new floor.

18. **Hihaho L-package spatie variant.** **Decision:** Ship a separate `stubs/laravel-package-spatie/` tree. Detector sub-flag `hihaho-package-tools-flavoured` (or explicit `--variant=spatie`) selects the full alternate tree. **Rationale:** Agent never mutates code mid-flow; just copies the right tree. Small duplication of composer.json + ServiceProvider + config stubs is cheaper than the two failure modes of mid-flow code rewriting.

19. **Committed `composer.lock` in libraries.** **Decision:** `NON-CANONICAL` severity. Upgrade phase offers `git rm --cached composer.lock` + add to `.gitignore` (user can decline). **Rationale:** 12-of-13 of the canonical reference libs have no lockfile; only socialite-solana commits one (likely accidental). Audit reflects the dominant pattern.

20. **`.gitattributes` managed-block contract.** **Decision:** repo-init appends entries into package-boost's existing `# >>> package-boost (managed) >>>` block — no second block. Requires a one-time package-boost update (~30 LOC) to preserve foreign lines during sync. Contract documented in `references/gitattributes-managed-block.md`. **Rationale:** Single managed block keeps the file readable and avoids the snowball problem if other tools later want to manage attributes. The cross-package contract is low cost since both packages share a maintainer.

21. **Package install + propagation lifecycle.** **Decision (v7 update):** Distribution is **global install** via `composer global require sandermuller/repo-init`, mirroring `composer global require laravel/installer`. Skill propagates once to `~/.claude/skills/repo-init/` via package-boost's new `--scope=user` sync (see RQ40). All phase/checklist/reference/stub reads use absolute paths rooted at `REPO_INIT_HOME = $(composer global config home)/vendor/sandermuller/repo-init`. Project-local install (`composer require --dev`) remains as an escape hatch (§3.4). Self-removal is optional (`composer global remove`) and rarely run. **Rationale:** Matches familiar `laravel new` UX; eliminates the greenfield `composer init` prelude; no per-target vendor pollution; one install per machine instead of per project.

22. **Audit-report state location.** **Decision:** Conversation-scoped. No file written to the target repo. Re-running audit re-derives findings from scratch (fast — it's all file-system reads of `composer.json` + per-file hashing). **Rationale:** Avoids the implicit-state problem flagged in codex v3 #3 and the "no temp files" constraint from the user. Cost: no cross-session resume of upgrade plans; upgrade-after-audit-in-different-session must re-audit first (explicitly documented in §9 upgrade phase template).

23. **Never-touch scope per mode.** **Decision:** Security never-touch paths apply in *all* modes (bootstrap, audit, upgrade). Git-dirty rule (`?? M MM A` skip) applies only in audit/upgrade modes; bootstrap exempts itself because its precondition is an empty target dir, so newly-created files from `laravel new` being untracked is expected. **Rationale:** Resolves codex v3 #4 (bootstrap blocked by its own never-touch rule). Bootstrap's protection is the cwd-empty check, not the git-dirty check.

24. **Audit + upgrade cover both `require` and `require-dev`.** **Decision:** Audit phases list MISSING runtime deps and MISSING dev deps as separate sections. Upgrade phases run `composer require <list>` and `composer require --dev <list>` as separate calls. **Rationale:** Resolves codex v3 #5 (runtime-deps drift never converges); §5.2 declares both columns, audit/upgrade must walk both.

25. **OUTDATED detection per-file merge mode.** **Decision:** Each file in `references/upgrade-merge-modes.md` declares a mode (`replace` / `managed-block` / `append-only` / `merge-keys` / `notify-only`). Auditor uses the mode-specific detector — `composer.json`, `phpstan.neon.dist`, `rector.php`, `phpstan-baseline.neon` are `notify-only` (user owns them) so never flagged OUTDATED for whole-file drift. **Rationale:** Resolves codex v3 #7 (blunt OUTDATED detection creating noise on legitimately-divergent files).

26. **Placeholder substitution exact rules.** **Decision:** §2 transform table is normative — `__VENDOR__`, `__PACKAGE__`, `__VENDOR_STUDLY__`, `__PACKAGE_STUDLY__`, `__NAMESPACE__`, `__NAMESPACE_ESCAPED__`, `__AUTHOR_NAME__`, `__AUTHOR_EMAIL__`, `__PHP_VERSION__`, `__LARAVEL_VERSIONS__`, `__PHP_VERSION_NEON__`. Edge cases in `references/placeholder-rules.md`. **Rationale:** Resolves codex v3 #6 (agent guessing the StudlyCase transform).

27. **Composer failure handling.** **Decision:** `references/composer-failure-modes.md` enumerates common failures with the resolution playbook; phase steps that run composer commands cite this reference. **Rationale:** Resolves codex v3 #8 (composer-resolution failure paths missing).

28. **Testbench in shared dev deps for non-Laravel categories.** **Decision:** Keep it. **Rationale:** `package-boost:sync` runs through Testbench in every package context (it's how boost's commands resolve outside a Laravel app); there is no alternative invocation today. Cost of one extra dev dep is small; we prefer uniform tooling to per-category conditional install paths. Codex v3 #9 acknowledged but accepted. **Superseded (v7):** boost-core's standalone `vendor/bin/boost` bin resolves outside a Laravel app without testbench, so testbench is no longer the AI-sync invocation path. It remains in the shared list as the package test bootstrap; `composer-plugin` excludes it (see RQ11).

29. **Greenfield install locus for package categories.** **Decision:** Bootstrap phase prelude (§3.3.1) — `mkdir <name>`, `cd`, `composer init --no-interaction --type=library`, `composer require --dev sandermuller/repo-init`, then proceed with bootstrap. For `laravel-project`, `laravel new <name>` replaces the mkdir + composer-init steps; the require step still runs after. **Rationale:** Resolves codex v4 #1 — package always installs INTO the target dir we're about to scaffold (preserves the RQ21 stays-installed-in-target invariant). Adds 3 prelude steps but they're mechanical and the alternative (parent-dir clutter or global install) is worse.

30. **No-dep-in-both-scopes.** **Decision:** §5.1.1 declares per-category exclusions from the shared dev-deps list whenever a category puts a package in `require`. `rector-extension` drops `rector/rector` from §5.1 shared install. Audit honours this — a `rector-extension` repo with `rector/rector` in `require` and absent from `require-dev` is correct, not MISSING. **Rationale:** Resolves codex v4 #2 — Composer rejects duplicate scope; spec must too.

31. **Optional vs mandatory deps split.** **Decision:** §5.2 split into two tables: MANDATORY (always audited) and OPTIONAL/CONDITIONAL (only audited when opt-in confirmed). Audit phase asks user up-front about each opt-in row (with auto-inference from existing `composer.json` content where possible — e.g. `hihaho/phpstan-rules` already in require-dev → opt-in inferred). `livewire/livewire` and other "suggest only" rows are never audited. **Rationale:** Resolves codex v4 #3 — opted-out compliant repos no longer audit as broken.

32. **composer.json merge-keys covers all documented keys, not just `scripts`.** **Decision:** §9 upgrade phase explicitly walks `scripts`, `extra.laravel.providers`, `extra.phpstan.includes`, `extra.rector.includes`, `config.allow-plugins`, `config.sort-packages`, `autoload-dev.classmap`. Each is a surgical JSON patch, never a whole-file rewrite. Audit's `merge-keys` detector walks the same set in §8. **Rationale:** Resolves codex v4 #4 — convergence path for composer metadata is now complete.

33. **Spec layout matches Resolved Questions.** **Decision:** §2 package layout enumerates `stubs/laravel-package-spatie/`, `references/upgrade-merge-modes.md`, `references/composer-failure-modes.md`, `references/placeholder-rules.md`. Phase 1 + Phase 2 implementation tasks create them explicitly. Phase 7 adds a layout-matches-Resolved-Qs CI check as the regression guard. **Rationale:** Resolves codex v4 #5 — spec body and implementation plan stay in sync; path-integrity CI fails on drift.

34. **No dep in both `require` AND `require-dev` (extended to all categories).** **Decision:** §5.1.1 extended to drop `phpstan/phpstan` from shared deps for `phpstan-extension` (matching the existing `rector/rector` exclusion for `rector-extension`). §5.2 rewritten so optional/conditional rows never duplicate scope — `phpstan-extension` Laravel-aware adds `larastan/larastan` to `require-dev` and `illuminate/support` to `require` only (not both). `rector-extension` Laravel-aware adds `driftingly/rector-laravel` to `require` only. **Rationale:** Resolves codex v5 #1 — composer rejects duplicate scope; spec must consistently enforce.

35. **Bootstrap sync executability — `orchestra/testbench` in repo-init's own `require`.** **Decision:** Repo-init's own `composer.json` declares `orchestra/testbench` in `require` (alongside `sandermuller/package-boost`). When the target installs `composer require --dev sandermuller/repo-init`, testbench installs alongside as a transitive dev dep, so `vendor/bin/testbench package-boost:sync` works immediately at §3.3 step 2 without waiting for the bootstrap phase to install the shared dev deps. **Rationale:** Resolves codex v5 #2 — propagation path is now executable from the very first call. **Superseded by RQ40 (v7):** repo-init is installed **globally**, never as a target's `--dev` dependency, so nothing rides along into a target's `vendor/`. Its `composer.json` `require` carries only `php` + `sandermuller/boost-core`; `orchestra/testbench` was removed and `sandermuller/package-boost-php` moved to `require-dev` (repo-init's own maintenance tooling). Skill propagation is boost-core's global-context auto-sync at `composer global require` time — see §2 and §3.3.

36. **`name` semantics unified.** **Decision:** `name` is OPTIONAL across §3.1, §3.3.1, §7, and RQ2. The single target-dir rule (declared once in §3.3.1, referenced from §7) is: positional `name` → create `./<name>/` and cd; no `name` → target is cwd (must be empty modulo `.git/`). If cwd-empty precondition fails, agent stops and asks for a `name`. **Rationale:** Resolves codex v5 #3 — §3.1 required-knob list, §3.3.1 mkdir step, and §7 generic step now all agree. Matches `laravel new` UX (both forms accepted).

37. **`extra.branch-alias` deferred to Phase 8.** **Decision:** Removed from §9 merge-keys list. Listed as Phase 8 LOW extra (alongside the existing branch-alias reference doc). **Rationale:** Resolves codex v5 #4 — v1 would have to add §8 audit + opt-in plumbing to make it complete; not worth the surface for early-stage-only feature. Future v2 brings it in fully.

38. **Phase ordering + structured dep source-of-truth.** **Decision:** Placeholder-coverage test moved from Phase 1 to Phase 2 (where stubs exist). `references/per-category-deps.yml` added as machine-readable parallel of `per-category-deps.md` — CI parses YAML for the require-vs-require-dev sync check rather than parsing markdown prose (codex v5 correctly flagged markdown parsing as not enforceable). Phase markdown files cite dep names by string match so grep is deterministic. **Rationale:** Resolves codex v5 #5 — Phase 1 test no longer depends on Phase 2 output; sync check has a real source of truth.

39. **Workbench scripts always added for `laravel-package`.** **Decision:** Drop `--with-workbench-scripts` flag. §5.4 says "always added". Matches RQ13. **Rationale:** Codex v5 flagged the body/RQ13 contradiction; observed pattern across all canonical sander L-packages is "always present" so the flag was vestigial.

40. **Distribution model — global install (v7).** **Decision:** Default is `composer global require sandermuller/repo-init` (one per machine). Project-local install remains as an escape hatch (§3.4). Skill propagates to `~/.claude/skills/repo-init/` via a new package-boost feature: `vendor/bin/boost sync --scope=user`. Phase/stub/reference paths use absolute `REPO_INIT_HOME = $(composer global config home)/vendor/sandermuller/repo-init`. **Rationale:** Matches `laravel new` mental model. Eliminates per-target install (no `composer init` prelude on greenfield; no per-target vendor pollution; no per-target self-removal). One-time setup, everywhere availability. Requires a small (~30 LOC) feature addition to package-boost (we maintain it). Closes audit-without-install open question (#3 was "audit-without-install" — global install IS audit-without-per-project-install).

41. **Bootstrap phase idempotency (v0.2).** **Decision:** All 5 `bootstrap-<category>.md` phase files are idempotent — each mutating step has a `Skip if:` precondition that makes re-runs a no-op when the post-condition is already met. Read-only steps (pre-flight, verification, print-next-steps) always run. **Rationale:** Enables the `sandermuller/repo-new` CLI (see `specs/repo-new-cli.md`) to do mechanical scaffolding via PHP code, then the agent reads the corresponding bootstrap phase file end-to-end and idempotency guards mean CLI-completed steps are silently skipped. No mid-phase resume contract needed; single-entry-point + self-contained-phase model preserved. Eliminates codex v8 finding #1 (mid-phase handoff was fragile). CI conformance test (`check-bootstrap-idempotency.sh`) guards the contract. **Impact:** repo-init bumps to 0.2.0; `sandermuller/repo-new` requires `^0.2`.

---

## Findings

<!-- Notes added during implementation. Do not remove this section. -->
