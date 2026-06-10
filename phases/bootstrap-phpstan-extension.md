# Bootstrap: phpstan-extension

Greenfield setup of a PHPStan extension package — a library that ships custom PHPStan rules, registered via `extra.phpstan.includes`.

**Idempotent.** Each mutating step has a `Skip if:` precondition. Re-running this phase against an already-bootstrapped target is a no-op. See SPEC.md RQ41.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`. Verify category-fit per `$REPO_INIT_HOME/references/detection-rules.md`. Placeholder transforms used in this phase come from `$REPO_INIT_HOME/references/placeholder-rules.md`.

## Inputs to collect

- `vendor` — required.
- `name` (kebab-case) — optional per target-dir rule.
- `description` — required.
- `php` — default `8.3`. Accepted: `8.3`, `8.4`, `8.5`. Reject `8.2`.
- `author-name` / `author-email` — defaults from git config.
- `laravel-aware` — `y` if user wants the extension to analyse Laravel code (adds `larastan/larastan` to `require-dev` and `illuminate/support` to `require`). Default `N` for sander-vendor, `y` for hihaho-vendor.

**Test framework is forced to `phpunit`** for phpstan-extension (canonical for phpstan rule testing — PHPStan's `RuleTestCase` is PHPUnit-based). User can override if they really want Pest, with a warning.

Confirm derived `__NAMESPACE__` with the user once.

## Steps

### 1. Apply target-dir rule

- Positional `name` → `mkdir <name> && cd <name>`.
- No `name` → target IS cwd, must be empty modulo `.git/`.

### 2. Copy shared stubs

**Skip per-file if:** the file exists at target path AND no literal placeholders remain.

For each file under `$REPO_INIT_HOME/stubs/shared/`, copy to cwd. Substitute placeholders. **Use `phpunit.xml`, skip `tests/Pest.php`** (phpstan-extension uses PHPUnit per above). **Skip `.mcp.json`** — the shared stub ships a Laravel/testbench MCP server config with no equivalent for framework-agnostic phpstan extensions. **Boost config:** the shared boost stub lives at `.config/boost.php` (canonical) — skip it if EITHER `.config/boost.php` OR a legacy root `boost.php` already exists; never create both (boost-core ≥ 0.17 errors on two configs). See `$REPO_INIT_HOME/references/placeholder-rules.md` (Boost config location).

### 3. Copy phpstan-extension stubs

**Skip per-file if:** the file (with file-path placeholders substituted) exists at target AND no literal placeholders remain. For `extension.neon`: skip if file exists (don't overwrite user-added rule registrations).

For each file under `$REPO_INIT_HOME/stubs/phpstan-extension/`:

- `composer.json` — substitute placeholders. Note: `type: phpstan-extension`, `extra.phpstan.includes: ["extension.neon"]`, `phpstan/phpstan: ^2` in `require` (NOT `require-dev` — per `references/shared-dev-deps.md` §5.1.1 exclusion), `classmap` in `autoload-dev` for `tests/Rules/stubs/`. Symplify dep is PHP-floor-conditional: the stub ships `symplify/phpstan-extensions: ^12.0` (installable on every accepted floor; matches the default `php=8.3`); if `php=8.4` or `8.5`, replace it with `symplify/phpstan-rules: ^14.11` AND align the `run-tests.yml` matrix with the chosen floor — drop cells below it and add cells the stub matrix lacks (it ships 8.3/8.4 cells only, so `php=8.5` needs an 8.5 cell) (see `references/shared-dev-deps.md` "Symplify formatter dep").
- `extension.neon` — copy as-is (no placeholders; user fills in `parametersSchema`/`parameters`/`services` blocks for their rules).
- `src/Rules/.gitkeep` — copy (empty file to preserve the dir).
- `tests/Rules/.gitkeep`, `tests/Rules/stubs/.gitkeep` — copy.
- `phpstan.neon.dist`, `rector.php` — copy + substitute `__PHP_VERSION_NEON__`.
- `.github/workflows/run-tests.yml` — copy (uses `vendor/bin/phpunit`).

### 4. Run `composer install`

**Skip if:** `vendor/` exists AND `composer validate --check-lock --no-check-publish --no-check-version` returns 0.

```bash
composer install
```

### 5. Run `composer require --dev` for the per-category dep list

**Skip if:** every dep in the list below is in `composer.json` `require-dev` (and the Laravel-aware opt-in, if confirmed, has `illuminate/support` in `require`).

From `$REPO_INIT_HOME/references/per-category-deps.md#phpstan-extension`:

**MANDATORY:**

- (None beyond shared, minus `phpstan/phpstan` per per-category exclusion.)
- Shared deps from `$REPO_INIT_HOME/references/shared-dev-deps.md` minus `phpstan/phpstan` (already in `require`).
- Plus `nikic/php-parser` (needed for rule tests).
- `phpunit/phpunit` (already in shared list for `test-framework=phpunit`).

**OPTIONAL (Laravel-aware opt-in):**

- Adds `larastan/larastan` to `require-dev` (REPLACES bare `phpstan/phpstan` in dev-deps — per `references/per-category-deps.md` Laravel-aware row). The require-side `phpstan/phpstan: ^2` stays so the extension declares its own phpstan dep cleanly for consumers.
- Adds `illuminate/support: __LARAVEL_VERSIONS__` to `require` so the extension can analyse Laravel code patterns. Edit the just-generated `composer.json` to add this.

Single batched `composer require --dev` call. On failure, consult `$REPO_INIT_HOME/references/composer-failure-modes.md`.

If Laravel-aware: run a separate `composer require illuminate/support:__LARAVEL_VERSIONS__` for the `require` side.

### 6. Verify extension auto-discovers

```bash
vendor/bin/phpstan --version
```

Should run without errors. Our extension's `extension.neon` is empty by default (no services registered yet), but the wiring is in place. Once the user adds a service in `extension.neon`, `phpstan/extension-installer` auto-loads it via `extra.phpstan.includes`.

### 7. Validate the extension.neon skeleton

The skeleton has `parametersSchema:`, `parameters:`, and `services:` blocks all commented-out. That's intentional — the user fills them in as they add rules. Verify:

```bash
vendor/bin/phpstan analyse --help | head -20   # should not error
```

### 8. Run post-bootstrap verification

Open `$REPO_INIT_HOME/checklists/post-bootstrap-verification.md`.

### 9. Print next steps

```
✓ Bootstrap done for {vendor}/{name} (phpstan-extension{laravel-aware? ', Laravel-aware'}).

Next:
- Write your first rule in src/Rules/. Example: src/Rules/NoFooRule.php implementing PHPStan\Rules\Rule.
- Register it in extension.neon under `services:`.
- Write a test in tests/Rules/. Place the fixture (the PHP code your rule should flag) under tests/Rules/stubs/.
- Set up the GitHub remote: `gh repo create {vendor}/{name} --public --source=. --remote=origin --push`.
- Run `composer test` (PHPUnit) and `composer phpstan-simplified`.

Want to run an audit next (`phases/audit-phpstan-extension.md`), or are you done?
```

## What's next

- Keep working: open `$REPO_INIT_HOME/phases/audit-phpstan-extension.md`.
- Done: stop.

## Idempotency invariants (RQ41 contract)

Re-running this phase against a target where all steps' post-conditions are already met must be a no-op. Steps 1, 6, 7, 8, 9 are read-only and always run; steps 2-5 have explicit `Skip if:` preconditions.

Tested in CI via `check-bootstrap-idempotency.sh`.

## Common issues

- **`composer require` rejects `phpstan/phpstan` as already required**: it's in `require`, not `require-dev`. Per §5.1.1 exclusion. The agent must NOT include `phpstan/phpstan` in the `composer require --dev` batch.
- **`larastan/larastan` and `phpstan/phpstan` both installed**: should never happen if the Laravel-aware opt-in is respected. If it did happen, remove `phpstan/phpstan` from `require-dev` (`composer remove --dev phpstan/phpstan`) and keep `larastan/larastan`. The require-side `phpstan/phpstan: ^2` stays.
- **`tests/Rules/stubs/` classmap missing**: phpstan-extension's `composer.json` `autoload-dev.classmap` declares this path. If missing, the agent forgot to copy that key over. Re-check.
