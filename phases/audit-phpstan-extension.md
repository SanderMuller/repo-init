# Audit: phpstan-extension

Read-only check of an existing `phpstan-extension` package against the canonical baseline.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`.

Verify detection per `$REPO_INIT_HOME/references/detection-rules.md`: target has `type: phpstan-extension` OR `extra.phpstan.includes` set.

## Opt-in confirmation

- **Laravel-aware?** Default `y` if any `illuminate/*` already in `require`. If `y`: audit expects `larastan/larastan` in `require-dev` (replacing bare `phpstan/phpstan` per §5.3 exclusivity) and `illuminate/support` in `require`.

`test-framework` is forced to `phpunit` for phpstan-extension (canonical for rule testing — PHPStan's `RuleTestCase` is PHPUnit-based). If the target uses Pest, tolerate it but mention it in the report under "Notes" — don't push to migrate.

## MISSING files

**Shared:** same list as audit-laravel-package.md but using `phpunit.xml.dist` (never `tests/Pest.php`).

**Category-specific (phpstan-extension):**

- [ ] `composer.json` with `type: phpstan-extension` AND `extra.phpstan.includes: ["extension.neon"]`
- [ ] `extension.neon` at repo root — with `parametersSchema`, `parameters`, and `services` blocks (even if empty / commented). If file exists but blocks are missing, flag as OUTDATED rather than MISSING.
- [ ] `src/Rules/` directory exists (may contain `.gitkeep` if no rules yet)
- [ ] `tests/Rules/` directory exists
- [ ] `tests/Rules/stubs/` directory exists — must be declared in `composer.json` `autoload-dev.classmap` (`["tests/Rules/stubs/"]`)

## MISSING runtime deps (must be in `require`)

From `$REPO_INIT_HOME/references/per-category-deps.md#phpstan-extension` MANDATORY:

- [ ] `phpstan/phpstan: ^2` (in `require`, not `require-dev` — per §5.1.1 exclusion)

OPTIONAL (Laravel-aware):

- [ ] If opt-in confirmed: `illuminate/support: __LARAVEL_VERSIONS__` in `require`.

## MISSING dev deps (must be in `require-dev`)

Apply per-category exclusion: drop bare `phpstan/phpstan` from the shared list (it's in `require`).

From shared (`$REPO_INIT_HOME/references/shared-dev-deps.md`):

- [ ] `laravel/pao`
- [ ] `laravel/pint`
- [ ] `phpstan/extension-installer`
- [ ] `phpstan/phpstan-strict-rules`
- [ ] `phpstan/phpstan-deprecation-rules`
- [ ] `phpstan/phpstan-phpunit`
- [ ] `rector/rector`
- [ ] `rector/type-perfect`
- [ ] `spaze/phpstan-disallowed-calls`
- [ ] `symplify/phpstan-extensions`
- [ ] `tomasvotruba/cognitive-complexity`
- [ ] `tomasvotruba/type-coverage`
- [ ] `nunomaduro/collision`
- [ ] `sandermuller/package-boost`
- [ ] `orchestra/testbench`
- [ ] `phpunit/phpunit` (test-framework=phpunit, the default for phpstan-extension)
- [ ] `nikic/php-parser` (rule tests + AST traversal)

OPTIONAL (Laravel-aware):

- [ ] `larastan/larastan` (REPLACES bare `phpstan/phpstan` — never both; the require-side `phpstan/phpstan: ^2` stays so the extension declares its own dep cleanly for consumers).

## OUTDATED files (per merge mode)

Same logic as audit-laravel-package.md — apply each file's mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md`. Plus:

- `extension.neon` is `replace` mode for the skeleton structure (the `parametersSchema`/`parameters`/`services` block headers) but `notify-only` for the actual rule registrations inside. Bootstrap writes the skeleton; user fills it in.

## NON-CANONICAL findings

- [ ] `phpstan/phpstan` in BOTH `require` and `require-dev` (Composer rejects; should never happen but check). Flag — remove from `require-dev`.
- [ ] `larastan/larastan` in `require-dev` BUT no `illuminate/*` in `require` — Laravel-aware claim without the actual Laravel runtime dep. Ask user: do you mean to be Laravel-aware? If yes, add `illuminate/support` to `require`.
- [ ] Test-framework is Pest for a phpstan-extension — tolerate but mention in Notes.
- [ ] `composer.lock` committed.
- [ ] `tests/Rules/stubs/` exists but NOT declared in `autoload-dev.classmap`. Phpstan extension test fixtures need classmap loading. Flag.
- [ ] PHP floor `^8.2` or below.

## EXTRA findings

Informational. Often: the extension ships extra `.neon` config files beyond `extension.neon` — totally legit, don't flag.

## Report

Same format as audit-laravel-package.md.

## What's next

- Apply fixes: `phases/upgrade-phpstan-extension.md`.
- Defer / done: stop.
