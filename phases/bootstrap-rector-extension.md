# Bootstrap: rector-extension

Greenfield setup of a Rector extension package — a library that ships custom Rector rules, registered via `extra.rector.includes`.

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

For each file under `$REPO_INIT_HOME/stubs/shared/`, copy to cwd. Substitute placeholders. Compose test-framework variant (Pest or PHPUnit) per `bootstrap-php-package.md` step 4.

### 3. Copy rector-extension stubs

For each file under `$REPO_INIT_HOME/stubs/rector-extension/`:

- `composer.json` — substitute placeholders. Note: `type: rector-extension`, `extra.rector.includes: ["config/config.php"]`, `rector/rector: ^2` in `require` (NOT `require-dev` — per `references/shared-dev-deps.md` §5.1.1 exclusion), `symplify/rule-doc-generator-contracts` in `require`, `rector/extension-installer` in `allow-plugins`.
- `config/config.php` — copy (already has `RectorConfig::configure()->withRules([])` skeleton).
- `src/Rector/.gitkeep`, `tests/Rector/.gitkeep` — copy.
- `phpstan.neon.dist`, `rector.php` — copy + substitute `__PHP_VERSION_NEON__`. The rector.php has `withPaths(src tests config)` — `config/` included because the extension's own config/config.php is non-trivial PHP.
- `.github/workflows/run-tests.yml` — copy.

### 4. Run `composer install`

```bash
composer install
```

### 5. Run `composer require --dev` for the per-category dep list

From `$REPO_INIT_HOME/references/per-category-deps.md#rector-extension`:

**MANDATORY:**

- `symplify/rule-doc-generator-contracts` — the rule documentation contract package.
- Shared deps from `$REPO_INIT_HOME/references/shared-dev-deps.md` minus `rector/rector` (already in `require` per §5.1.1 exclusion).
- `nikic/php-parser` (needed for rule tests / AST traversal).

**OPTIONAL (Laravel-aware opt-in via `--with-laravel-sets`):**

- Adds `driftingly/rector-laravel` to `require` (not `require-dev`) so the extension can wire Laravel rector sets internally in its own `config/config.php`. Edit the just-generated `composer.json` to add this.

Single batched `composer require --dev` call. On failure, consult `$REPO_INIT_HOME/references/composer-failure-modes.md`.

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

## Common issues

- **`composer require` rejects `rector/rector` as already required**: it's in `require`, not `require-dev`. Per §5.1.1 exclusion. Agent must NOT include `rector/rector` in the `composer require --dev` batch.
- **`rector/extension-installer` not allowed**: ensure `config.allow-plugins.rector/extension-installer: true` is in the just-written `composer.json` (it is in the stub). If `composer install` prompts, allow it.
- **`config/config.php` not auto-discovered**: verify `extra.rector.includes` is set to `["config/config.php"]` and the path is correct (relative to the package root).
