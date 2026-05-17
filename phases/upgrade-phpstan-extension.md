# Upgrade: phpstan-extension

Apply audit findings to an existing phpstan-extension package.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md` AND re-run audit: open `$REPO_INIT_HOME/phases/audit-phpstan-extension.md`.

## Safety rails

Same as `upgrade-laravel-package.md` §Honor the safety rails.

## Apply MISSING files

Stubs from `$REPO_INIT_HOME/stubs/<shared|phpstan-extension>/<path>`.

`extension.neon` is the trickiest stub:

- If absent entirely: copy `$REPO_INIT_HOME/stubs/phpstan-extension/extension.neon` (skeleton with commented blocks). User fills in.
- If present but missing top-level blocks (`parametersSchema`, `parameters`, `services`): treat as OUTDATED in `replace` mode — show diff, prompt before patching just the missing skeleton headers. Never overwrite user's existing rule registrations inside `services:`.

## Apply MISSING runtime deps

Single `composer require <list>` (NOT `--dev`):

- `phpstan/phpstan: ^2` (mandatory)
- `illuminate/support: __LARAVEL_VERSIONS__` (only if Laravel-aware opt-in confirmed)

## Apply MISSING dev deps

Single `composer require --dev <list>`. Shared list MINUS bare `phpstan/phpstan` (per §5.1.1 — it's in `require`). Plus:

- `phpunit/phpunit` (canonical for phpstan-extension)
- `nikic/php-parser`

If Laravel-aware opt-in:

- `larastan/larastan` (REPLACES bare `phpstan/phpstan` in `require-dev` — but since `phpstan/phpstan` is in `require` for this category anyway, this only means "add larastan, don't add bare phpstan to require-dev"). If `phpstan/phpstan` is somehow in `require-dev`, remove it (`composer remove --dev phpstan/phpstan`) before adding larastan.

On failure, consult `references/composer-failure-modes.md`.

## Apply OUTDATED files per merge mode

Same logic as upgrade-laravel-package.md.

## Apply composer.json merge-keys patches

- **`scripts`**: insert missing entries. For phpstan-extension, `test` defaults to `vendor/bin/phpunit`.
- **`extra.phpstan.includes`**: ensure `["extension.neon"]` is set. If existing array, ensure `extension.neon` is in it. Don't replace; add.
- **`autoload-dev.classmap`**: ensure `tests/Rules/stubs/` is in the classmap. If missing, insert as `["tests/Rules/stubs/"]` (preserving existing entries).
- **`config.allow-plugins`**: `phpstan/extension-installer: true`.
- **`config.sort-packages`**: `true`.
- Skip `pestphp/pest-plugin` allow-plugin (phpstan-extension uses PHPUnit).
- Don't touch `extra.laravel.providers` (phpstan-extension isn't a Laravel service provider).

## Apply NON-CANONICAL fixes (each prompted)

- **`phpstan/phpstan` in BOTH `require` and `require-dev`**: Composer rejects on install. Remove from `require-dev` (`composer remove --dev phpstan/phpstan`); keep `require: phpstan/phpstan: ^2`.
- **`larastan/larastan` in `require-dev` but no `illuminate/*` in `require`**: ask the user — Laravel-aware? If yes, add `illuminate/support`. If no, remove larastan.
- **Test-framework is Pest**: tolerate but inform user that PHPStan's `RuleTestCase` is PHPUnit-based; testing with Pest works but is less idiomatic.
- **`composer.lock` committed**: prompt to remove from git tracking.
- **`tests/Rules/stubs/` exists but not in classmap**: add to classmap (via merge-keys patch above).
- **PHP floor `^8.2`**: prompt bump.

## Run package-boost sync

```bash
vendor/bin/testbench package-boost:sync
```

## Verification

Open `$REPO_INIT_HOME/checklists/post-upgrade-verification.md`. Plus:

```bash
vendor/bin/phpstan analyse --help | head -5    # extension self-discovery works
vendor/bin/phpunit --version                   # test framework callable
```

## What's next

- Keep working: next phase or re-audit.
- Done: stop.

## Common issues

- **`composer require` rejects `phpstan/phpstan` as already in require**: per design. Don't include it in the `composer require --dev` list — the audit shouldn't have flagged it as MISSING from require-dev.
- **Test fixtures under `tests/Rules/stubs/` don't autoload**: classmap missing. Re-check `composer.json` `autoload-dev.classmap` and run `composer dump-autoload`.
- **Laravel-aware opt-in flip-flopping**: user adds `illuminate/*` then removes it. Re-audit picks up the change; subsequent upgrade either adds or removes larastan accordingly. This is intentional, just be clear with the user about the cascade.
