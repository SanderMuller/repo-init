# Bootstrap: rector-extension

Greenfield setup of a Rector extension package — a library that ships custom Rector rules, registered via `extra.rector.includes`.

**Idempotent.** Each mutating step has a `Skip if:` precondition. Re-running this phase against an already-bootstrapped target is a no-op. See SPEC.md RQ41.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`. Verify category-fit with `$REPO_INIT_HOME/references/detection-rules.md`.

## Placeholder reference

Per `$REPO_INIT_HOME/references/placeholder-rules.md` — exact transforms for `__VENDOR__`, `__PACKAGE__`, `__NAMESPACE__`, etc. used in stub substitution below.

## Inputs to collect

- `vendor` — required.
- `name` (kebab-case) — optional per target-dir rule.
- `description` — required.
- `php` — default `8.3`. Accepted: `8.3`, `8.4`, `8.5`. Reject `8.2`.
- `test-framework` — default `pest` for sander, `phpunit` for hihaho.
- `author-name` / `author-email` — defaults from git config.
- `laravel-aware` (`--with-laravel-sets`) — `y` if the extension uses Laravel rector sets internally; adds `driftingly/rector-laravel` to `require`. Default `N` for sander-vendor, `y` for hihaho-vendor.

Confirm derived `__NAMESPACE__` with the user once.

## Steps

### 1. Apply target-dir rule

- Positional `name` → `mkdir <name> && cd <name>`.
- No `name` → target IS cwd, must be empty modulo `.git/`.

### 2. Copy shared stubs

**Skip per-file if:** the file exists at target path AND no literal placeholders remain.

For each file under `$REPO_INIT_HOME/stubs/shared/`, copy to cwd. Substitute placeholders. Compose test-framework variant (Pest or PHPUnit) per `bootstrap-php-package.md` step 4. **Skip `.mcp.json`** — the shared stub ships a Laravel/testbench MCP server config with no equivalent for framework-agnostic rector extensions. **Boost config:** the shared boost stub lives at `.config/boost.php` (canonical) — skip it if EITHER `.config/boost.php` OR a legacy root `boost.php` already exists; never create both (boost-core ≥ 0.17 errors on two configs). See `$REPO_INIT_HOME/references/placeholder-rules.md` (Boost config location).

### 3. Copy rector-extension stubs

**Skip per-file if:** the file (with file-path placeholders substituted) exists at target AND no literal placeholders remain. For `config/config.php`: skip if file exists (don't overwrite user-added rule registrations).

For each file under `$REPO_INIT_HOME/stubs/rector-extension/`:

- `composer.json` — substitute placeholders. Note: `type: rector-extension`, `extra.rector.includes: ["config/config.php"]`, `rector/rector: ^2` in `require` (NOT `require-dev` — per `references/shared-dev-deps.md` §5.1.1 exclusion), `symplify/rule-doc-generator-contracts` in `require`, `rector/extension-installer` in `allow-plugins`. Symplify dep is PHP-floor-conditional: the stub ships `symplify/phpstan-extensions: ^12.0` (installable on every accepted floor; matches the default `php=8.3`); if `php=8.4` or `8.5`, replace it with `symplify/phpstan-rules: ^14.11` AND align the `run-tests.yml` matrix with the chosen floor — drop cells below it and add cells the stub matrix lacks (it ships 8.3/8.4 cells only, so `php=8.5` needs an 8.5 cell) (see `references/shared-dev-deps.md` "Symplify formatter dep").
- `config/config.php` — copy (already has `RectorConfig::configure()->withRules([])` skeleton).
- `src/Rector/.gitkeep`, `tests/Rector/.gitkeep` — copy.
- `phpstan.neon.dist`, `rector.php` — copy + substitute `__PHP_VERSION_NEON__`. The rector.php has `withPaths(src tests config)` — `config/` included because the extension's own config/config.php is non-trivial PHP.
- `.github/workflows/run-tests.yml` — copy.

### 4. Run `composer install`

**Skip if:** `vendor/` exists AND `composer validate --check-lock --no-check-publish --no-check-version` returns 0.

```bash
composer install
```

### 5. Run `composer require --dev` for the per-category dep list

**Skip if:** every dep in the list below is in `composer.json` `require-dev` AND `require` (for runtime deps `rector/rector` + `symplify/rule-doc-generator-contracts` + Laravel-aware `driftingly/rector-laravel`).

From `$REPO_INIT_HOME/references/per-category-deps.md#rector-extension`:

**MANDATORY (runtime — these are already in the stub `composer.json`'s `require` block, installed by step 5):**

- `rector/rector: ^2`
- `symplify/rule-doc-generator-contracts: ^11.2` — rule documentation contract.

**MANDATORY (dev — added via `composer require --dev`):**

- Shared deps from `$REPO_INIT_HOME/references/shared-dev-deps.md` minus `rector/rector` (already in `require` per §5.1.1 exclusion).
- `nikic/php-parser` (needed for rule tests / AST traversal).

**OPTIONAL (Laravel-aware opt-in via `--with-laravel-sets`):**

- Adds `driftingly/rector-laravel` to `require` (not `require-dev`) so the extension can wire Laravel rector sets internally in its own `config/config.php`. Edit the just-generated `composer.json` to add this.

For dev deps: single batched `composer require --dev` call. **Do NOT include `symplify/rule-doc-generator-contracts` or `rector/rector` in the `--dev` batch** — both are in `require`. On failure, consult `$REPO_INIT_HOME/references/composer-failure-modes.md`.

If Laravel-aware: separate `composer require driftingly/rector-laravel` for the `require` side.

### 6. Verify extension auto-discovers

```bash
vendor/bin/rector --version
```

Then test the empty-config wiring:

```bash
vendor/bin/rector process --dry-run
```

Should report 0 changes (no rules registered yet). Once the user adds a rule class in `src/Rector/` and registers it in `config/config.php`'s `withRules([...])`, `rector/extension-installer` auto-loads it via `extra.rector.includes`.

### 7. Run post-bootstrap verification

Open `$REPO_INIT_HOME/checklists/post-bootstrap-verification.md`.

### 8. Print next steps

```
✓ Bootstrap done for {vendor}/{name} (rector-extension{laravel-aware? ', Laravel-aware'}).

Next:
- Write your first rule in src/Rector/. Example: src/Rector/MyTransformRector.php extending Rector\Rector\AbstractRector.
- Register it in config/config.php under `withRules([...])`.
- Write a test in tests/Rector/. Use Rector's RectorTestCase to compare before/after fixtures.
- Set up the GitHub remote: `gh repo create {vendor}/{name} --public --source=. --remote=origin --push`.
- Run `composer qa` to confirm baseline passes.

Want to run an audit next (`phases/audit-rector-extension.md`), or are you done?
```

## What's next

- Keep working: open `$REPO_INIT_HOME/phases/audit-rector-extension.md`.
- Done: stop.

## Idempotency invariants (RQ41 contract)

Re-running this phase against a target where all steps' post-conditions are already met must be a no-op. Steps 1, 6, 7, 8 are read-only and always run; steps 2-5 have explicit `Skip if:` preconditions.

Tested in CI via `check-bootstrap-idempotency.sh`.

## Common issues

- **`composer require` rejects `rector/rector` as already required**: it's in `require`, not `require-dev`. Per §5.1.1 exclusion. Agent must NOT include `rector/rector` in the `composer require --dev` batch.
- **`rector/extension-installer` not allowed**: ensure `config.allow-plugins.rector/extension-installer: true` is in the just-written `composer.json` (it is in the stub). If `composer install` prompts, allow it.
- **`config/config.php` not auto-discovered**: verify `extra.rector.includes` is set to `["config/config.php"]` and the path is correct (relative to the package root).
