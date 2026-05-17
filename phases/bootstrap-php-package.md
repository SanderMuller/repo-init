# Bootstrap: php-package

Greenfield setup of a framework-agnostic PHP package. No Laravel runtime dep — works with any composer-installable PHP project as a consumer.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`.

## Inputs to collect

- `vendor` — required.
- `name` (kebab-case) — optional per target-dir rule.
- `description` — required.
- `php` — default `8.3`. Accepted: `8.3`, `8.4`, `8.5`. Reject `8.2`.
- `test-framework` — default `pest` for `sandermuller`, `phpunit` for `hihaho`.
- `author-name` / `author-email` — defaults from git config.

Confirm derived `__NAMESPACE__` with the user once.

## Steps

### 1. Apply target-dir rule

- Positional `name` → `mkdir <name> && cd <name>`.
- No `name` → target IS cwd, must be empty modulo `.git/`.

### 2. Copy shared stubs

For each file under `$REPO_INIT_HOME/stubs/shared/`, copy to cwd. Substitute placeholders. Skip `tests/Pest.php` if `test-framework=phpunit`.

### 3. Copy php-package stubs

For each file under `$REPO_INIT_HOME/stubs/php-package/`:

- `composer.json` — substitute placeholders. Note: `type: library`, no `illuminate/*` in require, `phpstan/phpstan` (NOT `larastan/larastan`) in require-dev.
- `.lpv` — lean-package-validator config (no placeholders).
- `PUBLIC_API.md` — substitute placeholders.
- `src/__PACKAGE_STUDLY__.php` — copy + substitute file name.
- `phpstan.neon.dist`, `rector.php` — copy + substitute `__PHP_VERSION_NEON__`.
- `.github/workflows/run-tests.yml` — copy (3-cell PHP-only matrix, no Laravel axis).

### 4. Compose test-framework variant

- `pest`: composer.json (already pest-flavoured), `tests/Pest.php` kept.
- `phpunit`: edit composer.json — swap `pestphp/*` deps for `phpunit/phpunit`, change `"test"` script. Use `phpunit.xml.dist`, skip `tests/Pest.php`. Also edit `.github/workflows/run-tests.yml` to `vendor/bin/phpunit` (already done for the shipped stub if pest; otherwise the agent makes the swap).

### 5. Run `composer install`

```bash
composer install
```

On failure, consult `$REPO_INIT_HOME/references/composer-failure-modes.md`.

### 6. Run `composer require --dev` for the per-category dep list

From `$REPO_INIT_HOME/references/per-category-deps.md#php-package`:

**MANDATORY:**

- `phpstan/phpstan` (NOT `larastan/larastan` — this is framework-agnostic; never both per `references/phpstan-config.md` §exclusivity)
- `stolt/lean-package-validator`

**Plus shared deps** (`$REPO_INIT_HOME/references/shared-dev-deps.md`).

Single batched call. On failure, consult composer-failure-modes.md.

### 7. Sync AI assets (project-local, optional)

Default for php-package is NO project-local AI assets — repo-init's global skill is sufficient. If the user wants this package to ship its own `.ai/skills/` (e.g. it's itself an AI-tooling library), bootstrap-spec opts in via:

```bash
mkdir -p .ai/skills .ai/guidelines
vendor/bin/testbench package-boost:sync
```

Otherwise skip.

### 8. Validate gitattributes

The php-package category uses `stolt/lean-package-validator` to ensure the published archive (`composer install --prefer-dist`) excludes dev/test/AI dirs. Run:

```bash
composer validate-gitattributes
```

If it warns about a missing export-ignore line for a dir we ship, add it to `.lpv` (and `.gitattributes` inside the package-boost managed block — see `$REPO_INIT_HOME/references/gitattributes-managed-block.md`).

### 9. Run post-bootstrap verification

Open `$REPO_INIT_HOME/checklists/post-bootstrap-verification.md`.

### 10. Print next steps

```
✓ Bootstrap done for {vendor}/{name} (php-package).

Next:
- Document your public API in PUBLIC_API.md (currently empty placeholders).
- Implement your first class in src/{__PACKAGE_STUDLY__}.php.
- Write your first test in tests/.
- Set up the GitHub remote: `gh repo create {vendor}/{name} --public --source=. --remote=origin --push`.
- Run `composer qa` to confirm baseline passes (including validate-gitattributes).

Want to run an audit next (`phases/audit-php-package.md`), or are you done?
```

## What's next

- Keep working: open `$REPO_INIT_HOME/phases/audit-php-package.md`.
- Done: stop.

## Common issues

- **`larastan/larastan` accidentally installed**: php-package uses `phpstan/phpstan` only. If `larastan` is in deps, remove it: `composer remove --dev larastan/larastan`. Don't install both.
- **`vendor/bin/lean-package-validator` warns**: missing export-ignore. Add to `.lpv` + update the managed block in `.gitattributes` per the contract.
- **PHP version below 8.3 in target**: php-package floors at 8.3 (per `references/version-defaults.md`). If user wants 8.2, document the deviation and proceed — they're opting out of `laravel/pao` (which is fine; pao is dev-only for AI output, not user-facing).
