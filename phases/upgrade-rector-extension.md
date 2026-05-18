# Upgrade: rector-extension

Apply audit findings to an existing rector-extension package.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md` AND re-run audit: open `$REPO_INIT_HOME/phases/audit-rector-extension.md`.

## Safety rails

Same as `upgrade-laravel-package.md` §Honor the safety rails. Honour the never-touch list at `$REPO_INIT_HOME/checklists/per-category-never-touch.md` and the git-dirty rule before every write. Verify category-fit one more time via `$REPO_INIT_HOME/references/detection-rules.md` before mutating; dep expectations come from `$REPO_INIT_HOME/references/per-category-deps.md`.

## Apply MISSING files

Stubs from `$REPO_INIT_HOME/stubs/<shared|rector-extension>/<path>`.

`config/config.php` is treated specially:

- If absent: copy `$REPO_INIT_HOME/stubs/rector-extension/config/config.php` (skeleton with empty `withRules([])`).
- If present: `notify-only` — user owns it once rules are registered. Don't overwrite.

## Apply MISSING runtime deps

Single `composer require <list>` (NOT `--dev`):

- `rector/rector: ^2` (mandatory)
- `symplify/rule-doc-generator-contracts` (mandatory)
- `driftingly/rector-laravel` (only if Laravel-aware opt-in confirmed)

## Apply MISSING dev deps

Single `composer require --dev <list>`. Shared list MINUS `rector/rector` (per §5.1.1 — it's in `require`). Plus `nikic/php-parser`.

Test-framework: `pestphp/pest` (+ arch + rector-pest) for pest, OR `phpunit/phpunit` for phpunit.

On failure, consult `references/composer-failure-modes.md`.

## Apply OUTDATED files per merge mode

Same logic as upgrade-laravel-package.md — apply each file's mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md`. Scripts patch per `$REPO_INIT_HOME/references/composer-scripts.md`.

## Apply composer.json merge-keys patches

- **`scripts`**: insert missing entries. For rector-extension, the `qa` chain typically adds `@test` (full QA includes running the rule tests).
- **`extra.rector.includes`**: ensure `["config/config.php"]` is set. If existing array, ensure the path is in it. Don't replace; add.
- **`config.allow-plugins`**: `pestphp/pest-plugin: true` (if pest), `phpstan/extension-installer: true`, **`rector/extension-installer: true`** (critical for rector-extension — without it, the extension's `config/config.php` isn't auto-loaded by consumer rector configs).
- **`config.sort-packages`**: `true`.
- Don't touch `extra.laravel.providers` (rector-extension isn't a Laravel SP).

## Apply NON-CANONICAL fixes (each prompted)

- **`rector/rector` in `require-dev` instead of `require`**: move it. `composer remove --dev rector/rector` then `composer require rector/rector:^2`.
- **`rector/rector` in BOTH require and require-dev**: Composer rejects; remove from require-dev.
- **Missing `rector/extension-installer` in `config.allow-plugins`**: insert (via merge-keys above). Without it, the extension is silently broken for consumers.
- **`extra.rector.includes` points to a nonexistent file**: surface to user — either create the file or fix the path.
- **`composer.lock` committed**: prompt to remove from git tracking.
- **PHP floor `^8.2`**: prompt bump.
- **PHPUnit cache findings** (if `test-framework=phpunit`): apply `$REPO_INIT_HOME/references/phpunit-config.md` Upgrade-actions section — set `cacheDirectory=".cache/phpunit"`, `rm -rf .phpunit.cache`, `git rm -r --cached .phpunit.cache` if previously committed.
- **CI path filter drift — `phpstan.yml` missing `composer.json` / `composer.lock`**: insert both lines under the `push.paths` and `pull_request.paths` blocks in `.github/workflows/phpstan.yml`.
- **`.gitattributes` missing `.ai/ export-ignore`**: insert `.ai/ export-ignore` line after `.agents/ export-ignore` inside the `# >>> package-boost (managed) >>>` block.

## Run package-boost sync

```bash
vendor/bin/testbench package-boost:sync
```

## Verification

Open `$REPO_INIT_HOME/checklists/post-upgrade-verification.md`. Plus:

```bash
vendor/bin/rector --version
vendor/bin/rector process --dry-run    # should run without errors; rules may report 0 changes on empty src/
```

## What's next

- Keep working: next phase or re-audit.
- Done: stop.

## Common issues

- **`vendor/bin/rector process --dry-run` reports "no rules registered"**: extension self-discovery failed. Check `extra.rector.includes` AND `config.allow-plugins.rector/extension-installer: true`. Both must be set.
- **Rule classes in `src/Rector/` not auto-loaded by consumer rector configs**: ensure they're registered in `config/config.php` `withRules([...])`. Just placing them in `src/Rector/` doesn't auto-register them.
- **`composer require` rejects `rector/rector` as already in require**: per design. Don't include it in `composer require --dev`.
