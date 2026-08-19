# Bootstrap: php-package

Greenfield setup of a framework-agnostic PHP package. No Laravel runtime dep — works with any composer-installable PHP project as a consumer.

**Idempotent.** Each mutating step has a `Skip if:` precondition. Re-running this phase against an already-bootstrapped target is a no-op. See SPEC.md RQ41.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`. Verify category-fit per `$REPO_INIT_HOME/references/detection-rules.md`. Placeholder transforms used in this phase come from `$REPO_INIT_HOME/references/placeholder-rules.md`.

## Inputs to collect

- `vendor` — required.
- `name` (kebab-case) — optional per target-dir rule.
- `description` — required.
- `php` — default `8.4` with `test-framework=pest` (Pest 5 requires PHP `^8.4`), `8.3` with `test-framework=phpunit`. Accepted: `8.3`, `8.4`, `8.5`. Reject `8.2`. Reject `pest` + `8.3` — ask the user which of the two to change.
- `test-framework` — default `pest` for `sandermuller`, `phpunit` for `hihaho`.
- `author-name` / `author-email` — defaults from git config.

Confirm derived `__NAMESPACE__` with the user once.

## Steps

### 1. Apply target-dir rule

- Positional `name` → `mkdir <name> && cd <name>`.
- No `name` → target IS cwd, must be empty modulo `.git/`.

### 2. Copy shared stubs

**Skip per-file if:** the file exists at target path AND no literal `__VENDOR__`/`__PACKAGE__`/etc. placeholders remain.

For each file under `$REPO_INIT_HOME/stubs/shared/`, copy to cwd. Substitute placeholders. Skip `tests/Pest.php` if `test-framework=phpunit`. **Skip `.mcp.json`** — the shared stub ships a Laravel/testbench MCP server config with no equivalent for framework-agnostic php-package code. **Boost config:** the shared boost stub lives at `.config/boost.php` (canonical) — skip it if EITHER `.config/boost.php` OR a legacy root `boost.php` already exists; never create both (boost-core ≥ 0.17 errors on two configs). See `$REPO_INIT_HOME/references/placeholder-rules.md` (Boost config location).

### 3. Copy php-package stubs

**Skip per-file if:** the SUBSTITUTED target filename already exists. **CRITICAL:** for stub files with `__PACKAGE_STUDLY__` or `__VENDOR_STUDLY__` in the filename, derive the target filename FIRST (substitute placeholders in the path), then check existence. Example: stub `src/__PACKAGE_STUDLY__.php` for a package named `repo-new` → check `src/RepoNew.php` exists, NOT `src/__PACKAGE_STUDLY__.php` exists. Checking the literal stub path will always miss because the file gets renamed after substitution.

Also verify file content has no literal `__VENDOR__` / `__PACKAGE__` / etc. placeholders remaining.

For each file under `$REPO_INIT_HOME/stubs/php-package/`:

- `composer.json` — substitute placeholders. Note: `type: library`, no `illuminate/*` in require, `phpstan/phpstan` (NOT `larastan/larastan`) in require-dev. The stub is Pest-flavoured, so it ships the PHP >= 8.4 dep set: `pestphp/*: ^5.0`, `symplify/phpstan-rules: ^14.12`, `tomasvotruba/type-coverage: ^2.3`, and NO `rector/type-perfect` (keeping type-perfect alongside type-coverage >= 2.3 double-registers `MethodNodeAnalyser` and PHPStan aborts at boot). Pest 5 requires PHP `^8.4`, so `php=8.3` is valid only with `test-framework=phpunit` — that combination has to restore the PHP 8.3 set (`symplify/phpstan-extensions: ^12.0`, `rector/type-perfect: ^2.1`, `tomasvotruba/type-coverage: >=2.2.0 <2.2.2`) and the 8.3 matrix cells. If `php=8.5`, add an `8.5` cell to `run-tests.yml`. See `references/shared-dev-deps.md` "Symplify formatter dep" and "Type-perfect dep".
- `.lpv` — lean-package-validator config (no placeholders).
- `PUBLIC_API.md` — substitute placeholders.
- `src/__PACKAGE_STUDLY__.php` — copy + substitute file name.
- `phpstan.neon.dist`, `rector.php` — copy + substitute `__PHP_VERSION_NEON__`.
- `.github/workflows/run-tests.yml` — copy (2-cell PHP-only matrix on PHP 8.4, no Laravel axis; a PHPUnit-at-8.3 scaffold adds the 8.3 cells back).

### 4. Compose test-framework variant

**Skip if:** target's `composer.json` `scripts.test` matches expected command for chosen test-framework AND `.github/workflows/run-tests.yml` last step matches.

The shipped stubs default to **Pest** for php-package. If the user picked PHPUnit:

**(a) `composer.json`**: swap `pestphp/*` deps for `phpunit/phpunit`; change `"test"` from `vendor/bin/pest` to `vendor/bin/phpunit`; change `"test-coverage"` to `vendor/bin/phpunit --coverage-html=coverage`; remove `pestphp/pest-plugin: true` from `config.allow-plugins`. If the user also picked `php=8.3`, restore the PHP 8.3 dep set in the same pass: `symplify/phpstan-extensions: ^12.0` (instead of `symplify/phpstan-rules`), `rector/type-perfect: ^2.1`, `tomasvotruba/type-coverage: >=2.2.0 <2.2.2`, and `stolt/lean-package-validator` may stay `^6.0.1` (the pin is harmless on PHPUnit 11/12).

**(b) `.github/workflows/run-tests.yml`**: change the last step's `run:` from `vendor/bin/pest --ci` to `vendor/bin/phpunit`. **Without this edit, CI fails immediately.** On `php=8.3`, also add the `8.3` matrix cells back (`prefer-lowest` + `prefer-stable`); the stub ships `8.4` cells only.

**(c) Test file**: delete `tests/Pest.php` (copied in step 2); use `phpunit.xml` (also from shared).

If keeping Pest (the default): no edits needed. `tests/Pest.php` already carries `pest()->tia()->locally()` — the Tia engine runs locally and stays out of CI.

### 5. Run `composer install`

**Skip if:** `vendor/` exists AND `composer validate --check-lock --no-check-publish --no-check-version` returns 0.

```bash
composer install
```

On failure, consult `$REPO_INIT_HOME/references/composer-failure-modes.md`.

### 6. Run `composer require --dev` for the per-category dep list

**Skip if:** every dep in the list below is in `composer.json` `require-dev`. For partial overlap, install only missing.

From `$REPO_INIT_HOME/references/per-category-deps.md#php-package`:

**MANDATORY:**

- `phpstan/phpstan` (NOT `larastan/larastan` — this is framework-agnostic; never both per `references/phpstan-config.md` §exclusivity)
- `stolt/lean-package-validator`

**Plus shared deps** (`$REPO_INIT_HOME/references/shared-dev-deps.md`).

**Boost-family member:** `sandermuller/package-boost-php` — the framework-agnostic umbrella, already in the stub `composer.json` `require-dev`. It is the only correct family member for this category. Never swap it for `sandermuller/package-boost-laravel` (Laravel categories only) or for a direct `sandermuller/boost-core` require (`skill-bundle` only), and keep the `post-install-cmd` / `post-update-cmd` callback on the matching `PackageBoostPhp` façade. See `$REPO_INIT_HOME/references/per-category-deps.md` (boost-family umbrella) and `$REPO_INIT_HOME/references/composer-scripts.md`.

Single batched call. On failure, consult composer-failure-modes.md.

### 7. Sync AI assets (project-local, optional)

**Skip if:** target's `.ai/skills/` dir exists AND `.claude/skills/` contains synced content OR (default) `~/.claude/skills/sandermuller__repo-init/` exists from global install.

Default for php-package is NO project-local AI assets — repo-init's global skill is sufficient. If the user wants this package to ship its own `.ai/skills/` (e.g. it's itself an AI-tooling library), bootstrap-spec opts in via:

```bash
mkdir -p .ai/skills .ai/guidelines
vendor/bin/boost sync
```

Otherwise skip.

### 8. Validate gitattributes

Read-only check (no mutation). Always run.

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

## Idempotency invariants (RQ41 contract)

Re-running this phase against a target where all steps' post-conditions are already met must be a no-op. Steps 1, 8, 9, 10 are read-only and always run; steps 2-7 have explicit `Skip if:` preconditions.

Tested in CI via `check-bootstrap-idempotency.sh`.

## Common issues

- **`larastan/larastan` accidentally installed**: php-package uses `phpstan/phpstan` only. If `larastan` is in deps, remove it: `composer remove --dev larastan/larastan`. Don't install both.
- **`vendor/bin/lean-package-validator` warns**: missing export-ignore. Add to `.lpv` + update the managed block in `.gitattributes` per the contract.
- **PHP version below 8.3 in target**: php-package floors at 8.3 (per `references/version-defaults.md`). If user wants 8.2, document the deviation and proceed — they're opting out of `laravel/pao` (which is fine; pao is dev-only for AI output, not user-facing).
