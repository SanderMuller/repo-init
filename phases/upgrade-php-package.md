# Upgrade: php-package

Apply audit findings to an existing framework-agnostic PHP package.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md` AND re-run audit: open `$REPO_INIT_HOME/phases/audit-php-package.md`.

## Safety rails

Same as `upgrade-laravel-package.md` §Honor the safety rails. Honour `$REPO_INIT_HOME/checklists/per-category-never-touch.md` (no Laravel-specific never-touch — `.env*` and `.git/` apply universally) and the git-dirty rule before every write. Verify category-fit one more time via `$REPO_INIT_HOME/references/detection-rules.md`; dep expectations come from `$REPO_INIT_HOME/references/per-category-deps.md`.

## Apply MISSING files

For each MISSING file:

1. Read stub from `$REPO_INIT_HOME/stubs/<shared|php-package>/<path>`.
2. Substitute placeholders.
3. Write — prompt on conflict per `replace` mode.

## Apply MISSING runtime deps

Skipped — php-package has no repo-init-mandated runtime deps.

## Apply MISSING dev deps

Single batched `composer require --dev <list>`. Shared + category-mandatory:

- Shared list from `references/shared-dev-deps.md`.
- Mandatory: `phpstan/phpstan` (NEVER `larastan/larastan` — framework-agnostic), `stolt/lean-package-validator`.

Test-framework: `pestphp/pest` + arch + rector-pest (pest), OR `phpunit/phpunit` (phpunit). Never pull `pestphp/pest-plugin-laravel` for php-package — framework-agnostic.

On failure, consult `references/composer-failure-modes.md`.

## Apply OUTDATED files per merge mode

Same logic as upgrade-laravel-package.md — apply each file's mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md`.

`PUBLIC_API.md`: `replace` mode for the section structure (headers). Content inside sections is user-owned (`notify-only`). If the stub has new sections the target doesn't, prompt to merge.

## Apply composer.json merge-keys patches

- **`scripts`**: insert missing entries per `references/composer-scripts.md`. Include `validate-gitattributes` script — php-package canonical. Add `@validate-gitattributes` to the `qa` chain.
- **`config.allow-plugins`**: `pestphp/pest-plugin: true` (if pest), `phpstan/extension-installer: true`.
- **`config.sort-packages`**: `true`.
- Don't touch `extra` (php-package has no canonical extra keys from repo-init).

## Apply NON-CANONICAL fixes (each prompted)

- **`larastan/larastan` in `require-dev` for a php-package**: prompt "is this actually a laravel-package?" If user confirms yes, re-route to `audit-laravel-package.md` (don't continue with php-package upgrade). If no, remove larastan (`composer remove --dev larastan/larastan`) and ensure `phpstan/phpstan` is present.
- **`illuminate/*` in `require`**: same — re-route to laravel-package.
- **`composer.lock` committed**: prompt to `git rm --cached composer.lock`.
- **`phpunit.xml` (no .dist)**: prompt rename.
- **PHP floor `^8.2`**: prompt bump.
- **Missing `validate-gitattributes` script**: insert it (via composer.json scripts merge above).
- **`.lpv` warnings on `vendor/bin/lean-package-validator validate`**: each missing export-ignore line listed in the audit. Prompt user: add to `.lpv` AND to `.gitattributes` (inside the package-boost managed block).

## Run package-boost sync

```bash
vendor/bin/testbench package-boost:sync
```

## Verification

Open `$REPO_INIT_HOME/checklists/post-upgrade-verification.md`. Plus:

```bash
composer validate-gitattributes
```

If it warns, the `.gitattributes` block is still incomplete — surface the remaining lines.

## What's next

- Keep working: next phase or re-audit.
- Done: stop.

## Common issues

- **`stolt/lean-package-validator` already installed but `.lpv` missing**: install added the package but the user didn't commit `.lpv`. Re-run upgrade or manually copy from `$REPO_INIT_HOME/stubs/php-package/.lpv`.
- **`validate-gitattributes` script fails after install with "command not found"**: `vendor/bin/lean-package-validator` needs `composer install` to be run since the dep was added. Run it.
- **PHP floor bump breaks `composer install`**: transitive dep needs <8.3. Surface conflict; may need to skip the floor bump on this repo.
