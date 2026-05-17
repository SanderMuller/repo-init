# `sandermuller/repo-new` CLI

Design spec (v2). Separate package providing a `repo new` CLI for mechanical scaffolding. Requires `sandermuller/repo-init` for stubs + dep data. Phase files in `repo-init` rewritten to be idempotent so the agent can pick up after CLI scaffolding without re-doing work.

**Status:** design approved (4 user clarifications + 1 codex review pass). Ready for implementation pending prerequisite work in `repo-init` (idempotency rework).

---

## 1. Overview

Two packages, two install commands, one mental model:

```bash
composer global require sandermuller/repo-init    # AI playbook (existing)
composer global require sandermuller/repo-new     # CLI (new)
```

The CLI walks the user through 2–7 prompts, then mechanically scaffolds the target dir using `repo-init`'s stubs + data. After scaffolding, the user asks Claude to continue — the agent reads `repo-init`'s `bootstrap-<category>.md` phase file end-to-end and each step's idempotency guards detect what's already done (skip) vs what's left (execute). No mid-phase resume contract; the existing single-entry-point model is preserved.

Two packages because (per codex review):

- `repo-init` stays pure markdown + stubs (RQ1 preserved, no PHP).
- `repo-new` ships PHP code (Symfony Console wizard + scaffolder). Depends on `repo-init` in `require` to read stubs + per-category-deps.yml at runtime.

---

## 2. Scope

### In scope (repo-new v0.1)

- CLI command `repo new [name]` with interactive wizard.
- 5 core categories (matching repo-init v7): `laravel-project`, `laravel-package` (sander + spatie variants), `php-package`, `phpstan-extension`, `rector-extension`.
- Reads stubs + per-category-deps from the installed `vendor/sandermuller/repo-init/` (or global equivalent).
- Bails on first error, leaves partial state for inspection.
- Emits a "next steps" prompt for the user to feed to Claude post-scaffold.
- Vendor-driven defaults for test-framework + opt-ins (sander → pest, hihaho → phpunit, etc.). All overridable via flags.

### Prerequisite work in `sandermuller/repo-init` (must ship FIRST)

- **Idempotency rework of all 5 `bootstrap-<category>.md` phase files.** Each step gains a "skip if already done" guard. See §6.
- New CI check in repo-init: idempotency-conformance test. Run a phase file twice (or after CLI), assert second run is a no-op.
- SPEC.md addition: RQ41 documents the bootstrap-phase idempotency contract.

### Out of scope (v0.1)

- `repo audit` / `repo upgrade` CLI commands — stays agent-driven via repo-init.
- filament-plugin + nova-tool categories — defer to v0.2 (matches repo-init v7 scope).
- Auto-installing repo-init at first `repo new` run — assumes user already ran the global require.
- State files in target (`.repo-new-state.json` etc.) — eliminated by idempotency.

---

## 3. UX flow — the wizard

Sequential prompts. Single-screen with default values pre-filled. Most users hit enter through ~5 Qs.

```
$ repo new

Welcome to repo-new. Scaffolding a fresh repo using sandermuller/repo-init.

Q1: Is this a project (full Laravel app) or a package (library)?
   [1] project   — full Laravel app, deploys somewhere
   [2] package   — library, others consume via composer
> 2

Q2: What kind of package?
   [1] laravel       — adds functionality to a Laravel app (ServiceProvider, config, etc.)
   [2] php           — framework-agnostic PHP library, works without Laravel
   [3] phpstan       — phpstan-extension (custom phpstan rules)
   [4] rector        — rector-extension (custom rector rules)
> 1

Q3: Sander-style or hihaho-style?
   [1] sander  — hand-rolled ServiceProvider, Pest tests by default
   [2] spatie  — extends Spatie\PackageServiceProvider, PHPUnit by default
> 1

Q4: Composer name? Format: <vendor>/<name> (kebab-case).
   Examples: sandermuller/queue-insights, hihaho/laravel-js-store
> sandermuller/my-new-package

Q5: One-line description?
> A package that does X and Y.

Q6: PHP version? [8.3 / 8.4 / 8.5] (default: 8.3)
> [enter]

Q7: Laravel version range? (default: ^11.0||^12.0||^13.0)
   [1] ^11.0||^12.0||^13.0   — support all three majors
   [2] ^12.0||^13.0
   [3] ^13.0
> [enter]

Confirm scaffold:
  Type:        laravel-package (sander variant)
  Name:        sandermuller/my-new-package
  Description: A package that does X and Y.
  PHP:         ^8.3
  Laravel:     ^11.0||^12.0||^13.0
  Test:        pest (sander default)
  Author:      Sander Muller <github@scode.nl>  (from git config)
  Target dir:  ./my-new-package (subdir of cwd, doesn't exist yet — will mkdir)
  Will run:    composer install + composer require --dev <16 deps> + package-boost:sync

Proceed? [Y/n]
> Y

[scaffold output here ...]

✓ Scaffold complete. Next steps in the handoff prompt below.
```

### Question routing by category

| Q1 | Q2 | Q3 (sander/spatie) | Q5 desc | Q6 php | Q7 laravel | Laravel-aware opt-in (Q8) |
|---|---|---|---|---|---|---|
| project | skip | skip | yes | yes | (laravel new chooses) | skip |
| pkg → laravel | — | yes | yes | yes | yes | skip |
| pkg → php | — | skip | yes | yes | skip (no Laravel) | skip |
| pkg → phpstan | — | skip | yes | yes | skip | yes — "Laravel-aware?" |
| pkg → rector | — | skip | yes | yes | skip | yes — "Laravel-aware?" |

Total Qs: 2 (Q1+Q2) required; 3–5 follow-up depending on branch.

### Vendor-driven defaults (no extra prompts)

- `test-framework`: sander → pest; hihaho → phpunit; phpstan-extension → always phpunit (ignored vendor). User overrides with `--test-framework=`.
- `with-hihaho-rules` (laravel-project only): `y` for vendor=hihaho; `N` otherwise. Override `--with-hihaho-rules` / `--without-hihaho-rules`.
- `with-security-advisories` (laravel-project only): `N` default. Override `--with-security-advisories`.

### Non-interactive mode

All Qs have flag equivalents:

```bash
repo new my-new-package \
  --type=laravel-package \
  --variant=sander \
  --vendor=sandermuller \
  --description="A package that does X and Y." \
  --php=8.3 \
  --laravel='^11.0||^12.0||^13.0' \
  --no-interaction
```

Missing required values in `--no-interaction` mode → exit 64 with the missing-flag list.

### Target-dir rule (matches repo-init §3.3.1)

- Positional `name` → `mkdir <name> && cd <name>`. Refuses if `<name>` already exists.
- No `name` → target IS cwd. Verify cwd is empty modulo `.git/`. If not, stop and ask user for a `name`.

For `laravel-project`, `laravel new <name>` invocation handles dir creation; `laravel new .` invocation for no-name case.

---

## 4. Package architecture

```
sandermuller/repo-new/
├── bin/
│   └── repo                                    # Symfony Console entry point
├── src/
│   ├── Application.php                         # Symfony Console application
│   ├── NewCommand.php                          # The `repo new` command
│   ├── Wizard/
│   │   ├── Wizard.php                          # Drives Q1→Q7 (+Q8 for Laravel-aware exts)
│   │   ├── Question/                           # One class per Q
│   │   │   ├── ProjectVsPackageQuestion.php
│   │   │   ├── PackageTypeQuestion.php
│   │   │   ├── VariantQuestion.php
│   │   │   ├── NameQuestion.php
│   │   │   ├── DescriptionQuestion.php
│   │   │   ├── PhpVersionQuestion.php
│   │   │   ├── LaravelVersionQuestion.php
│   │   │   └── LaravelAwareQuestion.php
│   │   └── WizardState.php                     # Collected answers + derived defaults
│   ├── Scaffolder/
│   │   ├── Scaffolder.php                      # Dispatches per category
│   │   ├── LaravelProjectScaffolder.php        # Wraps `laravel new`, then lays additions
│   │   ├── PackageScaffolder.php               # mkdir + copy stubs + composer ops
│   │   └── TargetDirResolver.php               # Implements target-dir rule
│   ├── RepoInit/
│   │   ├── RepoInitLocator.php                 # Finds vendor/sandermuller/repo-init/ at runtime
│   │   ├── PerCategoryDeps.php                 # Parses per-category-deps.yml
│   │   ├── StubReader.php                      # Lists + reads stub files
│   │   └── PlaceholderSubstituter.php          # Applies placeholder-rules.md transforms
│   ├── Composer/
│   │   ├── ComposerRunner.php                  # Shells out to composer install / require
│   │   └── ComposerFailureSurfacer.php         # Pretty-prints composer errors verbatim
│   ├── HandoffPrompt/
│   │   ├── HandoffPromptBuilder.php            # Generates Claude-handoff text per category
│   │   └── templates/                          # Per-category prompt templates
│   └── Git/
│       └── GitInitializer.php                  # git init + (opt-in) initial commit
├── tests/                                      # Pest tests
│   ├── Wizard/
│   ├── Scaffolder/
│   ├── RepoInit/
│   └── Integration/
│       └── ScaffoldEndToEndTest.php            # Full `repo new` runs against tmp dir
├── composer.json
├── README.md
├── CHANGELOG.md
├── LICENSE
└── SPEC.md → symlink or copy of specs/repo-new-cli.md
```

### `composer.json` shape

```json
{
    "name": "sandermuller/repo-new",
    "type": "library",
    "description": "CLI wizard for scaffolding repos using sandermuller/repo-init's playbook.",
    "license": "MIT",
    "require": {
        "php": "^8.3",
        "sandermuller/repo-init": "^0.1",
        "symfony/console": "^7.0||^8.0",
        "symfony/yaml": "^7.0||^8.0",
        "symfony/process": "^7.0||^8.0"
    },
    "autoload": {
        "psr-4": {
            "SanderMuller\\RepoNew\\": "src/"
        }
    },
    "bin": [
        "bin/repo"
    ]
}
```

### `RepoInitLocator` — runtime data discovery

CLI is installed globally. Looks for repo-init data in this order:

1. `__DIR__/../../../sandermuller/repo-init/` — sibling in same global vendor dir (most common).
2. `<composer-global-home>/vendor/sandermuller/repo-init/` — explicit global lookup as fallback.
3. `./vendor/sandermuller/repo-init/` — project-local lookup (if user has both installed locally).

If none found, exit 70 with message: "sandermuller/repo-init not found. Run `composer global require sandermuller/repo-init` first."

This addresses codex finding #3 ("misframed — derive from binary location"): we resolve relative to the bin script, not via `composer global config home` which can fail.

---

## 5. Scaffold actions per category

### `laravel-project`

Full wizard + lay additions on top of `laravel new` (per user direction, contra codex's #5 minimalist suggestion):

1. Verify `laravel` binary on PATH. If not, exit 70 with install instructions.
2. Run `laravel new <name> --ai` (probe for `--ai` flag support; fallback to plain `laravel new <name>` with warning).
3. `cd <name>`.
4. Read repo-init's `bootstrap-laravel-project.md` step list mechanically:
   - Overlay `stubs/shared/*` for files Laravel installer didn't write or wrote differently. Conflict resolution per stub merge mode (`replace` files = ask user; `notify-only` files = skip).
   - Overlay `stubs/laravel-project/*` (boost.json, phpstan.neon.dist, rector.php, README.append.md).
   - `composer require --dev` shared list + laravel-project mandatory list + confirmed opt-ins.
   - Extend `.gitignore` with project-only lines (append-only).
   - `php artisan package-boost:sync`.
5. Run post-bootstrap verification per repo-init's `checklists/post-bootstrap-verification.md`.

This duplicates work the agent would do; the idempotency contract in repo-init ensures the agent re-reading the same phase file is a no-op.

### Package categories

1. Apply target-dir rule (§3 target-dir rule above).
2. Read `vendor/sandermuller/repo-init/stubs/shared/*` via `StubReader`. Apply `PlaceholderSubstituter`. Write to cwd.
3. Read `vendor/sandermuller/repo-init/stubs/<category>/*` (or `<category>-spatie` for laravel-package spatie variant). Substitute. Write.
4. Compose test-framework variant per `bootstrap-<cat>.md` step 5 instructions (mechanical):
   - Patch `composer.json` scripts + deps + allow-plugins.
   - Patch `.github/workflows/run-tests.yml` `Execute tests` step.
   - Delete `tests/Pest.php` if test-framework=phpunit.
5. For Laravel-aware extension opt-in (Q8): ADD `illuminate/support` to `require` AND swap `phpstan/phpstan` for `larastan/larastan` in the dev-dep list. **Do this BEFORE composer install** (codex finding #4 + open Q4 answer).
6. `composer install`. On failure, surface verbatim, exit non-zero. Leave partial state.
7. `composer require --dev <list>` per category mandatory + shared minus exclusions + test-framework split. On failure, same.
8. For runtime deps (laravel-package, phpstan-extension, rector-extension): `composer require <list>` for the `require` block per per-category-deps.yml.
9. `vendor/bin/testbench package-boost:sync` (project-local; the new package will have its own .ai/skills/ to sync — initially empty).
10. Run post-bootstrap verification (mechanical subset: composer validate, file presence, placeholder substitution grep). Surface anything red.
11. Generate + print handoff prompt.

### Per-category exclusions (matches repo-init `per-category-deps.yml`)

- `rector-extension`: drop `rector/rector` from shared dev-deps install (it's in `require`).
- `phpstan-extension`: drop `phpstan/phpstan` from shared dev-deps install (it's in `require`).
- `laravel-package` spatie variant: ADD `spatie/laravel-package-tools` to `require`.

---

## 6. Prerequisite work in `repo-init` — bootstrap phase idempotency

repo-init's existing `bootstrap-<category>.md` phase files MUST be reworked to be idempotent so the agent can pick up after CLI scaffolding cleanly. Each step gains a precondition check; if the post-condition is already true, the step is a no-op.

### Idempotency pattern per step

Each step in every `bootstrap-<category>.md` becomes:

```markdown
### N. Step description

**Precondition check:** [how to verify if this is already done]
**If precondition already met:** skip this step.
**Otherwise:** [the actual step instructions]
```

### Per-step precondition checks

For `bootstrap-laravel-package.md` (template; other categories follow same pattern):

| Step | Precondition check (skip if true) |
|---|---|
| 1. Apply target-dir rule | `pwd` is the target dir AND target dir exists |
| 2. Pick stub source dir | (nothing to do; lookup-only) |
| 3. Copy shared stubs | Every shared stub file exists at target path AND hash matches stub-after-substitution |
| 4. Copy category stubs | Every category stub file exists at target path AND hash matches |
| 5. Compose test-framework variant | `composer.json` `scripts.test` matches expected test-framework command AND workflow `Execute tests` step matches |
| 6. Run `composer install` | `vendor/` exists AND `composer.lock` valid (`composer validate --check-lock` returns 0) |
| 7. Run `composer require --dev <list>` | Every dep in the list is in `composer.json` `require-dev` AND `vendor/<dep>/` exists |
| 8. Runtime deps | Every dep in the list is in `composer.json` `require` AND `vendor/<dep>/` exists |
| 9. `package-boost:sync` | `.claude/skills/` exists AND skill files within match `vendor/sandermuller/package-boost/.ai/skills/` |
| 10. Post-bootstrap verification | (always run — verification is read-only) |
| 11. Print next steps | (always — this is informational) |

### Idempotency conformance CI

New CI check in `repo-init`: `check-bootstrap-idempotency.sh`. Runs each `bootstrap-<cat>.md` phase against a fresh tmp dir (full run), then runs it AGAIN against the same dir (should be a no-op — every step's precondition is met). Diffs the dir before/after the second run — must be byte-equal.

### SPEC.md addition (RQ41)

> **41. Bootstrap phase idempotency.** **Decision:** All 5 `bootstrap-<category>.md` phase files are idempotent — each step has a precondition check that makes re-runs a no-op when the post-condition is already met. **Rationale:** Enables `sandermuller/repo-new` CLI to do mechanical scaffolding without needing a mid-phase resume contract. Agent can read phase files end-to-end as before; idempotency means CLI-completed steps are silently skipped. Single-entry-point + self-contained-phase model preserved (codex v8 finding #1). CI conformance test guards the contract.

---

## 7. Handoff prompt (CLI output)

Generated by `HandoffPromptBuilder`. Per-category template; all use the same structure.

### Example (laravel-package, sander variant)

```
✓ Scaffolded sandermuller/my-new-package at /Users/sandermuller/projects/my-new-package

   Type:           laravel-package (sander variant)
   PHP:            ^8.3
   Laravel:        ^11.0||^12.0||^13.0
   Test framework: pest

Files written:
   25 from stubs/shared/
   8 from stubs/laravel-package/
   17 dev deps + 2 runtime deps installed
   1 package-boost sync completed

Next: copy-paste this to Claude (it auto-activates the repo-init skill):

----- 8< -----
I just scaffolded a new Laravel package at /Users/sandermuller/projects/my-new-package
(category: laravel-package, sander variant, composer name: sandermuller/my-new-package).
The skeleton is wired (composer install, deps, package-boost). Please:

1. Verify the scaffold is healthy — run the repo-init `bootstrap-laravel-package.md`
   phase file from your skill. Every step should be a no-op (idempotency guards
   confirm everything is already done). Surface anything that needs attention.

2. Walk me through:
   - Implementing the first piece of functionality in src/MyNewPackageServiceProvider.php
   - Writing the first test in tests/Feature/ or tests/Unit/
   - Setting up the GitHub remote with `gh repo create sandermuller/my-new-package --public --source=. --remote=origin --push`

When done with this package later, ask me to run `phases/audit-laravel-package.md`
to catch any drift from the canonical baseline.
----- 8< -----
```

The template per category lives in `src/HandoffPrompt/templates/<category>.txt` and uses placeholders `{TARGET_DIR}`, `{COMPOSER_NAME}`, `{NAMESPACE}`, etc. that `HandoffPromptBuilder` substitutes.

---

## 8. Failure-path strategy

Per user decision: **bail on first error, leave partial state for inspection.**

- Each scaffold step that can fail (composer install, composer require, laravel new, package-boost sync) is wrapped in try/catch.
- On failure: surface the underlying tool's stderr verbatim, print a clear "[repo-new] Step X failed. Partial state left in `<target-dir>` for inspection. Either fix manually + re-run `repo new --resume` (NOT IMPLEMENTED in v0.1; manually re-run individual composer commands instead) OR `rm -rf <target-dir>` and try again." message, exit non-zero (typically 1; specific exit codes per error class).
- No automatic cleanup. No state file. No resume mode.

The partial state is recoverable via repo-init's agent path: user asks Claude "finish bootstrapping this repo per `bootstrap-<category>.md`" — idempotency picks up where CLI left off.

---

## 9. Auto-init git

Per user decision (matches codex's read on open Q5):

- **Auto `git init` in target dir:** YES, after successful scaffold + before printing handoff prompt. Always.
- **Auto initial commit:** OPT-IN via `--commit` flag. Default OFF. Reasoning: user may want to inspect + edit before first commit; auto-commit could surprise.

If `--commit` is set: `git add -A && git commit -m "Initial scaffold via sandermuller/repo-new"`. Commit author defaults to git config; can override with `--commit-author=`.

---

## 10. CI parity guard (repo-new ↔ repo-init)

New CI check in `repo-new`: `check-cli-data-matches-repo-init.sh`. Asserts:

1. CLI's `PackageType` enum lists exactly the 5 (v0.1) / 7 (v0.2 with filament + nova) categories present in repo-init's `references/per-category-deps.yml`. No drift.
2. CLI's stub-tree lookup matches repo-init's `stubs/` dir layout. New stub category in repo-init MUST add a CLI handler.
3. CLI's `composer require` list matches repo-init's `per-category-deps.yml` MANDATORY rows (require + require-dev split honored).
4. End-to-end smoke: `repo new --no-interaction --type=php-package --vendor=ci --name=test --description=test --php=8.3` produces a target dir whose file tree byte-equals the agent-driven `bootstrap-php-package.md` output (run via a test harness that invokes the agent against a fresh tmp dir).

Test #4 is the parity smoke. Both paths must produce identical output for the same inputs. Drift surfaces here.

---

## Implementation

### Prerequisite Phase 0: idempotency rework in `sandermuller/repo-init` (BLOCKING)

- [ ] Rewrite `phases/bootstrap-laravel-package.md` with precondition checks per §6 table. Each step starts with **Precondition check**, **If precondition already met**, **Otherwise**.
- [ ] Same for `bootstrap-laravel-project.md`, `bootstrap-php-package.md`, `bootstrap-phpstan-extension.md`, `bootstrap-rector-extension.md`.
- [ ] Add `check-bootstrap-idempotency.sh` CI check. Spins up tmp dirs, runs phase manually (driven by a test harness that interprets the markdown), runs again, asserts byte-equal.
- [ ] Add RQ41 to repo-init's SPEC.md.
- [ ] Tag repo-init `0.2.0` (idempotency rework is a MINOR bump pre-1.0 — UPGRADING.md notes the phase-file restructure).

### Phase 1: package skeleton + composer.json

- [ ] `composer init` skeleton for `sandermuller/repo-new`. composer.json per §4.
- [ ] `.gitignore`, `LICENSE`, `README.md`, `CHANGELOG.md`.
- [ ] `bin/repo` — Symfony Console entry point.
- [ ] `src/Application.php` — registers `NewCommand`.
- [ ] Tests skeleton (Pest, matching repo-init's stubs/php-package).

### Phase 2: RepoInit data layer

- [ ] `src/RepoInit/RepoInitLocator.php` — discovers vendor path per §4 lookup order.
- [ ] `src/RepoInit/PerCategoryDeps.php` — parses per-category-deps.yml; exposes `forCategory(string $cat, string $variant): DepList`.
- [ ] `src/RepoInit/StubReader.php` — lists + reads stub files.
- [ ] `src/RepoInit/PlaceholderSubstituter.php` — implements placeholder-rules.md transforms.
- [ ] Tests — Pest tests against fixture repo-init data + golden-file placeholder substitution.

### Phase 3: Wizard

- [ ] `src/Wizard/Wizard.php` + 8 question classes + `WizardState`.
- [ ] Branching per Q1/Q2 answers per §3 routing table.
- [ ] Vendor-driven defaults applied in WizardState.
- [ ] Tests — Pest test per question; integration test for full wizard flow.

### Phase 4: Scaffolders

- [ ] `src/Scaffolder/Scaffolder.php` — dispatches per category.
- [ ] `LaravelProjectScaffolder.php` — wraps `laravel new` + lays additions per §5.
- [ ] `PackageScaffolder.php` — mkdir + copy stubs + composer ops per §5.
- [ ] `TargetDirResolver.php` — implements §3 target-dir rule.
- [ ] Tests — integration tests per category against tmp dir.

### Phase 5: Composer + Git

- [ ] `src/Composer/ComposerRunner.php` — wraps composer install + require via symfony/process.
- [ ] `src/Composer/ComposerFailureSurfacer.php` — pretty-print stderr.
- [ ] `src/Git/GitInitializer.php` — git init + opt-in commit.
- [ ] Tests — mocked composer runs; real git init in tmp dir.

### Phase 6: HandoffPrompt

- [ ] `src/HandoffPrompt/HandoffPromptBuilder.php` + per-category templates.
- [ ] Tests — snapshot tests per category; assert prompt content matches expected for known inputs.

### Phase 7: NewCommand wiring + end-to-end test

- [ ] `src/NewCommand.php` — wires Wizard → Scaffolder → HandoffPrompt.
- [ ] End-to-end smoke test in `tests/Integration/ScaffoldEndToEndTest.php` — runs `repo new --no-interaction` for each category, asserts target-dir file tree matches expected.

### Phase 8: CI parity guard

- [ ] `check-cli-data-matches-repo-init.sh` per §10.
- [ ] GitHub Actions workflow runs all 4 checks + smoke test.
- [ ] Codex review pass on the implementation.

### Phase 9: Release

- [ ] `0.1.0` tag, Packagist publish.
- [ ] README + CHANGELOG + UPGRADING.

---

## Resolved Questions

1. **Architecture: separate package.** `sandermuller/repo-new` as a new package, depends on `sandermuller/repo-init` in `require`. Keeps repo-init pure markdown (RQ1 preserved).
2. **Handoff: idempotent phase files in repo-init.** Bootstrap phase files in repo-init rewritten so each step is a no-op when post-condition already met. Agent can read phase end-to-end after CLI scaffolding; no mid-phase resume contract needed. Requires Phase 0 work in repo-init.
3. **`repo-init` dep scope:** `require` (not `require-dev`). Needed for CLI to read stubs at runtime.
4. **Categories: 5 core only in v0.1.** filament-plugin + nova-tool deferred to v0.2 (matches repo-init v7 scope).
5. **Target dir: mirrors `laravel new`.** Positional `name` → subdir; no name → cwd if empty.
6. **Laravel-project: full wizard + CLI lays additions.** CLI calls `laravel new --ai`, then runs the layered additions per bootstrap-laravel-project.md mechanically. Drift risk accepted; CI parity guard catches divergence.
7. **Test-framework + opt-in: vendor-driven defaults, no extra prompts.** Sander → pest, hihaho → phpunit, phpstan-ext → always phpunit. Override via flags.
8. **Failure path: bail on first error, leave partial state.** No auto-cleanup, no resume mode. Agent path picks up via idempotency.
9. **Auto git init: yes; auto commit: opt-in via `--commit` flag.**
10. **`boost.json`: no in v0.1.** Not a per-package canonical artefact yet (per codex).
11. **`repo audit` / `repo upgrade` stubs in CLI: no.** Stay agent-driven. CLI surface stays narrow.
12. **`REPO_INIT_HOME` resolution: derived from CLI binary location, not `composer global config home`.** Per codex finding #3 + open Q3 answer.
13. **Laravel-aware extension opt-in: ask in wizard before composer install.** Avoids the §5 step 7 "edit composer.json after install" stale-lockfile problem per codex finding #4.

## Open Questions

1. **Idempotency conformance test mechanism.** The CI check runs a phase file twice and asserts the second run is a no-op. But the phase files are markdown instructions for an agent, not executable code. The test needs either a "phase-file interpreter" (a script that reads the markdown + executes steps) OR the test runs against the CLI output and asserts CLI re-run is a no-op. The first is harder but more thorough; the second is what we'd write anyway. Decide before Phase 0.

2. **Symfony Console + composer global require behavior.** When user runs `composer global require sandermuller/repo-new`, Composer installs symfony/console + symfony/yaml + symfony/process into the global vendor dir. These deps may conflict with other globally-installed packages (e.g. laravel/installer might also pull symfony/console at a different version). Verify on a test machine before publishing.

3. **Verbose vs quiet output.** Default behavior is single-line-per-step progress (à la `laravel new`). `--verbose` shows full composer output. `--quiet` shows only errors. Confirm verbosity flags match Symfony Console defaults.

4. **Repo-init version pin.** `repo-new` v0.1 requires `repo-init: ^0.1` — but the idempotency rework is repo-init `0.2.0`. Pin should be `^0.2`. Update before release.
