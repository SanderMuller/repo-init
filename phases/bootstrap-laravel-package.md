# Bootstrap: laravel-package

Greenfield setup of a Laravel package (a library that adds functionality to Laravel apps via a ServiceProvider).

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`. Stop if anything is red.

## Inputs to collect

Ask the user up-front for any value not already known. Skill (`SKILL.md` "Knobs to collect") may have collected most.

- `vendor` (e.g. `sandermuller`, `hihaho`, custom) — required.
- `name` (kebab-case) — optional per target-dir rule.
- `description` — required, one-line summary.
- `php` — default `8.3`. Accepted: `8.3`, `8.4`, `8.5`. Reject `8.2`.
- `laravel` — default `^11.0||^12.0||^13.0`. Other options: `^12.0||^13.0`, `^13.0`.
- `test-framework` — default `pest` for `sandermuller`, `phpunit` for `hihaho`.
- `author-name` / `author-email` — defaults from `git config user.name` / `git config user.email`.
- `variant` — `sander` (default) or `spatie`. Auto-set to `spatie` if vendor is `hihaho`. If `spatie`, the stub source is `$REPO_INIT_HOME/stubs/laravel-package-spatie/` instead of `$REPO_INIT_HOME/stubs/laravel-package/`.

Confirm the derived `__NAMESPACE__` with the user once (per `$REPO_INIT_HOME/references/placeholder-rules.md` — e.g. `sandermuller/queue-insights` derives `Sandermuller\QueueInsights` by default; user may override to `SanderMuller\QueueInsights`).

## Steps

### 1. Apply target-dir rule

- If user passed positional `name`: `mkdir <name> && cd <name>`. Verify the dir didn't already exist.
- Otherwise: target IS cwd. Verify cwd is empty modulo `.git/`. If not, stop and ask the user for a `name`.

### 2. Pick stub source dir

Set `STUB_CATEGORY_DIR` based on the `variant`:

- `sander` → `$REPO_INIT_HOME/stubs/laravel-package/`
- `spatie` → `$REPO_INIT_HOME/stubs/laravel-package-spatie/`

The two variants differ in `composer.json` (spatie has `spatie/laravel-package-tools` in `require`, uses PHPUnit by default) and `src/__PACKAGE_STUDLY__ServiceProvider.php` (spatie extends `PackageServiceProvider`).

### 3. Copy shared stubs

For each file under `$REPO_INIT_HOME/stubs/shared/`, copy to the same relative path in cwd. Substitute placeholders per `$REPO_INIT_HOME/references/placeholder-rules.md`.

Special handling for `tests/`: copy `tests/Pest.php` only when `test-framework=pest`; skip when `phpunit`.

### 4. Copy category stubs

For each file under `$STUB_CATEGORY_DIR/`, copy to cwd. Substitute placeholders, including file-path placeholders (e.g. `src/__PACKAGE_STUDLY__ServiceProvider.php` → `src/QueueInsightsServiceProvider.php`).

### 5. Compose the test-framework variant

- If `test-framework=phpunit`: keep `phpunit.xml.dist` from `stubs/shared/`. Edit the stub `composer.json` to use `phpunit/phpunit` in `require-dev` and `"test": "vendor/bin/phpunit"` in `scripts` (already pre-set in `stubs/laravel-package-spatie/composer.json`; for `sander` variant, the agent edits the just-written `composer.json` per `$REPO_INIT_HOME/references/composer-scripts.md` substitutions table).
- If `test-framework=pest`: keep `tests/Pest.php`. Composer.json is already pest-flavoured (sander variant); for `spatie` variant the agent edits to pest. Add `pestphp/pest`, `pestphp/pest-plugin-arch`, `pestphp/pest-plugin-laravel`, `mrpunyapal/rector-pest` to `require-dev`.

Pick exactly one of these per the user's choice; never both.

### 6. Run `composer install`

```bash
composer install
```

On failure, consult `$REPO_INIT_HOME/references/composer-failure-modes.md`.

### 7. Run `composer require --dev` with the per-category dep list

Build the list:

- Shared `require-dev` from `$REPO_INIT_HOME/references/shared-dev-deps.md` (universal list), minus any per-category exclusions (`laravel-package` has none).
- Category-mandatory `require-dev` from `$REPO_INIT_HOME/references/per-category-deps.md#laravel-package`: `larastan/larastan`, `driftingly/rector-laravel`.
- Conditional opt-ins:
  - `--with-hihaho-rules` (default `y` for vendor=hihaho): adds nothing for `laravel-package` (those are laravel-project-only).
  - `variant=spatie`: `spatie/laravel-package-tools` is in `require` (already in the spatie stub composer.json), not `require-dev`.

Run as a single batched `composer require --dev <pkg1> <pkg2> ...` call. Respect the larastan-vs-phpstan exclusivity (use `larastan/larastan`; never also `phpstan/phpstan`).

On failure, consult `$REPO_INIT_HOME/references/composer-failure-modes.md`.

### 8. Run `composer require` for runtime deps if not already pulled

`illuminate/contracts` + `illuminate/support` are already in the stub `composer.json` `require` block at the chosen `__LARAVEL_VERSIONS__`. `composer install` in step 6 pulled them. No extra step needed unless `variant=spatie` and `spatie/laravel-package-tools` somehow missing — re-check.

### 9. Install + sync target-local AI assets

For project-local repo-init users (escape hatch per SPEC §3.4), or when the user explicitly wants this package to have its OWN target-local skill copy:

```bash
vendor/bin/testbench package-boost:install --all   # or --agents=claude_code per user preference
vendor/bin/testbench package-boost:sync
```

For the default global-install case, the user-level `~/.claude/skills/` already has repo-init's skill via the global `composer global require sandermuller/repo-init` post-install hook. This new package doesn't need its own copy — skip step 9 unless the user is creating a package that will itself ship AI skills (i.e. the new package's own `.ai/skills/` dir).

If skipping, instead just sync the `.ai/skills/`/`.ai/guidelines/` that ship with this package's own stub (currently empty — bootstrap creates the dir but no skills inside):

```bash
mkdir -p .ai/skills .ai/guidelines
vendor/bin/testbench package-boost:sync
```

This wires up the project-local sync so adding a skill later is one command away.

### 10. Run post-bootstrap verification

Open `$REPO_INIT_HOME/checklists/post-bootstrap-verification.md` and confirm every item.

### 11. Print next steps

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
