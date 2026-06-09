# Bootstrap: laravel-package

Greenfield setup of a Laravel package (a library that adds functionality to Laravel apps via a ServiceProvider).

**Idempotent.** Each mutating step has a precondition check. If the post-condition is already met (e.g. CLI scaffolding ran first, or this phase was run before and aborted mid-way), the step is a no-op. See SPEC.md RQ41 for the contract.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`. Stop if anything is red. Verify category-fit per `$REPO_INIT_HOME/references/detection-rules.md`. Placeholder transforms (already cited under `$REPO_INIT_HOME/references/placeholder-rules.md` in step 4) apply to every stub substitution.

## Inputs to collect

Ask the user up-front for any value not already known. Skill (`SKILL.md` "Knobs to collect") may have collected most.

- `vendor` (e.g. `sandermuller`, `hihaho`, custom) — required.
- `name` (kebab-case) — optional per target-dir rule.
- `description` — required, one-line summary.
- `php` — default `8.3`. Accepted: `8.3`, `8.4`, `8.5`. Reject `8.2`.
- `laravel` — default `^12.0||^13.0`. Other options: `^13.0`. (Laravel 11 support dropped in repo-init 0.3.0 because `laravel/pao` 1.x conflicts with Laravel <12.)
- `test-framework` — default `pest` for `sandermuller`, `phpunit` for `hihaho`.
- `author-name` / `author-email` — defaults from `git config user.name` / `git config user.email`.
- `variant` — `sander` (default) or `spatie`. Auto-set to `spatie` if vendor is `hihaho`. If `spatie`, the stub source is `$REPO_INIT_HOME/stubs/laravel-package-spatie/` instead of `$REPO_INIT_HOME/stubs/laravel-package/`.

Confirm the derived `__NAMESPACE__` with the user once (per `$REPO_INIT_HOME/references/placeholder-rules.md` — e.g. `sandermuller/queue-insights` derives `Sandermuller\QueueInsights` by default; user may override to `SanderMuller\QueueInsights`).

## Steps

### 1. Apply target-dir rule

Lookup-only; no idempotency guard needed (cd is naturally idempotent).

- If user passed positional `name`: `mkdir -p <name> && cd <name>`. Tolerate dir already existing (idempotency); fail only if dir exists AND is non-empty AND doesn't look like a partial scaffold of this category.
- Otherwise: target IS cwd. Verify cwd is empty modulo `.git/` OR looks like a partial scaffold of `laravel-package`. If neither, stop and ask the user for a `name`.

### 2. Pick stub source dir

Lookup-only; no mutation.

Set `STUB_CATEGORY_DIR` based on the `variant`:

- `sander` → `$REPO_INIT_HOME/stubs/laravel-package/`
- `spatie` → `$REPO_INIT_HOME/stubs/laravel-package-spatie/`

The two variants differ in `composer.json` (spatie has `spatie/laravel-package-tools` in `require`, uses PHPUnit by default) and `src/__PACKAGE_STUDLY__ServiceProvider.php` (spatie extends `PackageServiceProvider`).

### 3. Copy shared stubs

**Precondition check:** for every file under `$REPO_INIT_HOME/stubs/shared/`, the equivalent file exists at the corresponding path in cwd AND contains no literal `__VENDOR__` / `__PACKAGE__` / `__NAMESPACE__` / `__AUTHOR_*` / `__PHP_VERSION__` / `__LARAVEL_VERSIONS__` placeholder strings (which would mean stub was copied but substitution was skipped).

**If precondition met:** skip — shared stubs already copied + substituted.

**Otherwise:** for each file under `$REPO_INIT_HOME/stubs/shared/`, copy to the same relative path in cwd. Substitute placeholders per `$REPO_INIT_HOME/references/placeholder-rules.md`. **Boost config:** the shared boost stub lives at `.config/boost.php` (canonical) — skip it if EITHER `.config/boost.php` OR a legacy root `boost.php` already exists; never create both (boost-core ≥ 0.17 errors on two configs). See `placeholder-rules.md` (Boost config location).

Special handling for `tests/`: copy `tests/Pest.php` only when `test-framework=pest`; skip when `phpunit`.

### 4. Copy category stubs

**Precondition check:** for every file under `$STUB_CATEGORY_DIR/`, the equivalent file at the SUBSTITUTED target path exists AND contains no literal placeholders. **CRITICAL:** derive the target filename FIRST by substituting `__PACKAGE_STUDLY__` / `__VENDOR_STUDLY__` / `__PACKAGE__` in the path, THEN check existence. Example: stub `src/__PACKAGE_STUDLY__ServiceProvider.php` for `sandermuller/queue-insights` → check `src/QueueInsightsServiceProvider.php` exists, NOT `src/__PACKAGE_STUDLY__ServiceProvider.php`. The literal placeholder path will always miss because the file was renamed during substitution. (Dogfood-discovered bug from 2026-05-17.)

**If precondition met:** skip — category stubs already copied + substituted.

**Otherwise:** for each file under `$STUB_CATEGORY_DIR/`, copy to cwd. Substitute placeholders, including file-path placeholders.

### 5. Compose the test-framework variant

**Precondition check (all must pass):**

- `composer.json` `scripts.test` matches expected binary (`vendor/bin/pest` for pest, `vendor/bin/phpunit` for phpunit)
- `.github/workflows/run-tests.yml` last step `run:` matches the same binary
- (pest) `tests/Pest.php` exists / (phpunit) `tests/Pest.php` does NOT exist
- (phpunit) `composer.json` `require-dev` contains NO `pestphp/*` packages; `config.allow-plugins` has no `pestphp/pest-plugin` entry
- (pest) `composer.json` `require-dev` contains NO `phpunit/phpunit` (Pest pulls it transitively at the right version; explicit entry can pin a conflicting version)
- (phpunit) `tests/**/*.php` contain NO pest syntax: `grep -rE '^(test|it)\(|^expect\(' tests/` returns no hits; (pest) inverse check optional
- (pest) `composer.json` `config.allow-plugins."pestphp/pest-plugin"` is `true`

**If precondition met:** skip — variant already composed.

**Otherwise:** the stubs ship a default test-framework per variant: `laravel-package` (sander) defaults to **Pest**, `laravel-package-spatie` (hihaho) defaults to **PHPUnit**. If the user picked the OTHER framework, edit:

**(a) `composer.json`**:

- Swap `"test"` script: `vendor/bin/pest` ↔ `vendor/bin/phpunit`
- Swap `"test-coverage"` script: `vendor/bin/pest --coverage` ↔ `vendor/bin/phpunit --coverage-html=coverage`
- Swap dev deps: ADD `pestphp/pest` + `pestphp/pest-plugin-arch` + `pestphp/pest-plugin-laravel` + `mrpunyapal/rector-pest` OR ADD `phpunit/phpunit`; REMOVE the other set.
- Swap `config.allow-plugins`: ADD `pestphp/pest-plugin: true` for pest; REMOVE for phpunit.

**(b) `.github/workflows/run-tests.yml`**:

- Change the last step's `run:` from `vendor/bin/pest --ci` (pest default) to `vendor/bin/phpunit` (phpunit) — or vice versa. **Without this edit, CI fails immediately because the workflow runs the wrong test binary.**

**(c) Test bootstrap file**:

- Pest: keep `tests/Pest.php` (copied from shared in step 3).
- PHPUnit: delete `tests/Pest.php` (if present); rely on `phpunit.xml` (also from shared).

Pick exactly one of these per the user's choice; never both.

### 6. Run `composer install`

**Precondition check:** `vendor/` directory exists AND `composer.lock` exists AND `composer validate --check-lock --no-check-publish --no-check-version` returns 0.

**If precondition met:** skip — deps already installed cleanly.

**Otherwise:**

```bash
composer install
```

On failure, consult `$REPO_INIT_HOME/references/composer-failure-modes.md`.

### 7. Run `composer require --dev` with the per-category dep list

**Precondition check:** for every dep in the list below, `composer show --installed <dep>` returns 0 (i.e. the dep is installed) AND the dep is in target's `composer.json` `require-dev` (per `composer show --installed --no-dev | grep <dep>` returning empty — confirming it's dev not prod).

**If precondition met:** skip — all dev deps already present.

**Otherwise:** build the list:

- Shared `require-dev` from `$REPO_INIT_HOME/references/shared-dev-deps.md` (universal list), minus any per-category exclusions (`laravel-package` has none).
- Category-mandatory `require-dev` from `$REPO_INIT_HOME/references/per-category-deps.md#laravel-package`: `larastan/larastan`, `driftingly/rector-laravel`.
- Conditional opt-ins:
  - `--with-hihaho-rules` (default `y` for vendor=hihaho): adds nothing for `laravel-package` (those are laravel-project-only).
  - `variant=spatie`: `spatie/laravel-package-tools` is in `require` (already in the spatie stub composer.json), not `require-dev`.

Run as a single batched `composer require --dev <pkg1> <pkg2> ...` call FOR THE MISSING ones only. Respect the larastan-vs-phpstan exclusivity (use `larastan/larastan`; never also `phpstan/phpstan`).

On failure, consult `$REPO_INIT_HOME/references/composer-failure-modes.md`.

### 8. Run `composer require` for runtime deps if not already pulled

**Precondition check:** `composer show --installed --no-dev` lists `illuminate/contracts` AND `illuminate/support` (AND, when `variant=spatie`, `spatie/laravel-package-tools`).

**If precondition met:** skip — runtime deps already in target's `require`.

**Otherwise:** `illuminate/contracts` + `illuminate/support` are already in the stub `composer.json` `require` block at the chosen `__LARAVEL_VERSIONS__`. `composer install` in step 6 should have pulled them. If somehow missing, `composer require illuminate/contracts:__LARAVEL_VERSIONS__ illuminate/support:__LARAVEL_VERSIONS__`. For `variant=spatie`, ensure `spatie/laravel-package-tools` is also in `require` (re-add if missing).

### 9. Install + sync target-local AI assets

**Precondition check (BOTH must pass):**

- Target has the AI agent directories materialized from `package-boost:sync`: at least one of `.claude/`, `.agents/`, `.cursor/`, `.junie/`, `.kiro/` exists in target cwd, AND `AGENTS.md`/`CLAUDE.md` exist at the target root. (`package-boost:sync` is the only step that generates these; missing means sync never ran.)
- Repo-init's own skill is reachable: EITHER `.claude/skills/repo-init/SKILL.md` in target cwd (project-local install case) OR `~/.claude/skills/sandermuller__repo-init/SKILL.md` (global install case).

**If precondition met:** skip — AI assets already available.

**If only the skill check passes** but `.claude/`/`AGENTS.md`/etc. are missing in target: the boost autosync hook never ran (likely because composer install used `--no-scripts`). Run `vendor/bin/boost sync` regardless of repo-init install scope — the target's own AI tooling is independent of repo-init's skill location.

**Otherwise:** for project-local repo-init users (escape hatch per SPEC §3.4), or when the user explicitly wants this package to have its OWN target-local skill copy:

```bash
vendor/bin/boost install   # interactively picks agents + vendor allowlist
vendor/bin/boost sync
```

For the default global-install case, the user-level `~/.claude/skills/` already has repo-init's skill via the global `composer global require sandermuller/repo-init` post-install hook. This new package doesn't need its own copy — skip step 9 unless the user is creating a package that will itself ship AI skills (i.e. the new package's own `.ai/skills/` dir).

If skipping, instead just sync the `.ai/skills/`/`.ai/guidelines/` that ship with this package's own stub (currently empty — bootstrap creates the dir but no skills inside):

```bash
mkdir -p .ai/skills .ai/guidelines
vendor/bin/boost sync
```

This wires up the project-local sync so adding a skill later is one command away.

### 10. Run post-bootstrap verification

Always run (read-only). No idempotency guard needed.

Open `$REPO_INIT_HOME/checklists/post-bootstrap-verification.md` and confirm every item.

### 11. Print next steps

Always run (informational).

```
✓ Bootstrap done for {vendor}/{name} (laravel-package, {variant} variant).

Next:
- Write your first test in tests/Feature/ or tests/Unit/.
- Implement your ServiceProvider's register() and boot() methods in src/{__PACKAGE_STUDLY__}ServiceProvider.php.
- (Optional) Configure {__PACKAGE__} in config/{__PACKAGE__}.php.
- Set up the GitHub remote: `gh repo create {vendor}/{name} --public --source=. --remote=origin --push`.
- Run `composer qa` to confirm baseline passes.

Want to run an audit next (`phases/audit-laravel-package.md`), or are you done with repo-init for now?
```

## What's next

- User wants to keep working: open `$REPO_INIT_HOME/phases/audit-laravel-package.md`.
- User is done: nothing to remove (repo-init lives globally, not in this target). Just stop.

## Common issues

- **`spatie/laravel-package-tools` not installed but ServiceProvider extends `PackageServiceProvider`**: check `composer require` output; on failure consult composer-failure-modes.md.
- **`vendor/bin/testbench` missing after `composer install`**: `orchestra/testbench` should be in `require-dev` from the shared list. If missing, `composer require --dev orchestra/testbench` separately.
- **PHPStan red on first run with `vendor/bin/phpstan`**: expected — the stub `phpstan-baseline.neon` is empty. Generate one with `vendor/bin/phpstan analyse --generate-baseline`, then commit it as a known-debt baseline.

## Idempotency invariants (RQ41 contract)

Re-running this phase against a target where all steps' post-conditions are already met must be a no-op. Specifically:

1. No file writes (every stub copy step's precondition guard skips when content already correct).
2. No `composer install` / `composer require` invocations (preconditions verify deps already installed in correct scope).
3. No `package-boost:sync` invocation (precondition verifies skill already synced).
4. Verification + print-next-steps still run (they're read-only).

This contract lets `sandermuller/repo-new` do mechanical scaffolding via CLI, then the agent runs this phase end-to-end and detects "nothing to do" automatically — no mid-phase resume contract needed.

Tested in CI via `check-bootstrap-idempotency.sh`.
