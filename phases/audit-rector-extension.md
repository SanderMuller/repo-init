# Audit: rector-extension

Read-only check of an existing `rector-extension` package against the canonical baseline.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`.

Verify detection per `$REPO_INIT_HOME/references/detection-rules.md`: target has `type: rector-extension` OR `extra.rector.includes` set.

## Opt-in confirmation

- **Laravel-aware (`--with-laravel-sets`)?** Default `y` if `driftingly/rector-laravel` already in `require` OR `require-dev`. If `y`: audit expects `driftingly/rector-laravel` in `require` (not `require-dev`).
- `test-framework` — detect from existing deps (`pestphp/pest` vs `phpunit/phpunit`). No default forcing for rector-extension.

## MISSING files

**Shared:** same list as audit-laravel-package.md.

**Category-specific (rector-extension):**

- [ ] `composer.json` with `type: rector-extension` AND `extra.rector.includes: ["config/config.php"]` AND `config.allow-plugins.rector/extension-installer: true`
- [ ] `config/config.php` — Rector service registration file (even if rules array is empty)
- [ ] `src/Rector/` directory exists
- [ ] `tests/Rector/` directory exists

## MISSING runtime deps (must be in `require`)

From `$REPO_INIT_HOME/references/per-category-deps.md#rector-extension` MANDATORY:

- [ ] `rector/rector: ^2` (in `require`, not `require-dev` — per §5.1.1 exclusion)
- [ ] `symplify/rule-doc-generator-contracts`

OPTIONAL (Laravel-aware):

- [ ] If opt-in: `driftingly/rector-laravel` in `require`.

## MISSING dev deps (must be in `require-dev`)

Apply per-category exclusion: drop `rector/rector` from the shared list (it's in `require`).

From shared:

- [ ] `laravel/pao`
- [ ] `laravel/pint`
- [ ] `phpstan/extension-installer`
- [ ] `phpstan/phpstan` (rector-extension is framework-agnostic by default — uses bare phpstan, not larastan)
- [ ] `phpstan/phpstan-strict-rules`
- [ ] `phpstan/phpstan-deprecation-rules`
- [ ] `phpstan/phpstan-phpunit`
- [ ] `rector/type-perfect`
- [ ] `spaze/phpstan-disallowed-calls`
- [ ] `symplify/phpstan-extensions`
- [ ] `tomasvotruba/cognitive-complexity`
- [ ] `tomasvotruba/type-coverage`
- [ ] `nunomaduro/collision`
- [ ] `sandermuller/package-boost`
- [ ] `orchestra/testbench`
- [ ] `nikic/php-parser` (AST traversal in rule tests)

Test-framework split:

- pest: `pestphp/pest`, `pestphp/pest-plugin-arch`, `mrpunyapal/rector-pest`.
- phpunit: `phpunit/phpunit`.

## OUTDATED files (per merge mode)

For each file present, apply the merge mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md` — same logic as `audit-laravel-package.md`. `config/config.php` is `notify-only` once rules are registered (user owns it); `replace` mode applies only to the skeleton if the file is empty/missing.

## NON-CANONICAL findings

- [ ] `rector/rector` in `require-dev` instead of `require` — should be in `require` for rector-extension. Flag.
- [ ] `rector/rector` in BOTH `require` and `require-dev` — Composer rejects; should never happen.
- [ ] Missing `rector/extension-installer` in `config.allow-plugins` — auto-discovery breaks without it.
- [ ] `composer.lock` committed.
- [ ] PHP floor `^8.2` or below.
- [ ] `extra.rector.includes` points to a file that doesn't exist.

## EXTRA findings

Informational. Often: the extension ships rule-doc generators, custom set lists — legit, don't flag.

## Report

Same format as audit-laravel-package.md.

## What's next

- Apply fixes: `phases/upgrade-rector-extension.md`.
- Defer / done: stop.
