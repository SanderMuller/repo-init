# Upgrade: phpstan-extension

Apply audit findings to an existing phpstan-extension package.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md` AND re-run audit: open `$REPO_INIT_HOME/phases/audit-phpstan-extension.md`.

## Safety rails

Same as `upgrade-laravel-package.md` §Honor the safety rails. Honour `$REPO_INIT_HOME/checklists/per-category-never-touch.md` and the git-dirty rule before every write. Verify category-fit one more time via `$REPO_INIT_HOME/references/detection-rules.md`; dep expectations come from `$REPO_INIT_HOME/references/per-category-deps.md`.

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
- `sandermuller/package-boost-php` (the framework-agnostic boost umbrella; pulls `sandermuller/boost-core` transitively)

If Laravel-aware opt-in:

- `larastan/larastan` (REPLACES bare `phpstan/phpstan` in `require-dev` — but since `phpstan/phpstan` is in `require` for this category anyway, this only means "add larastan, don't add bare phpstan to require-dev"). If `phpstan/phpstan` is somehow in `require-dev`, remove it (`composer remove --dev phpstan/phpstan`) before adding larastan.

On failure, consult `references/composer-failure-modes.md`.

## Apply OUTDATED files per merge mode

Same logic as upgrade-laravel-package.md — apply each file's mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md`. Scripts patch per `$REPO_INIT_HOME/references/composer-scripts.md`.

## Apply composer.json merge-keys patches

- **`scripts`**: **Read `$REPO_INIT_HOME/references/composer-scripts.md` IN FULL before patching.** Do NOT infer the canonical block from memory — a real laravel-package upgrade (2026-05-25) shipped a Windows-broken `post-install-cmd` and no `post-update-cmd` because the agent auto-completed from training data. For each documented key (11 baseline for phpstan-extension; `test` is `vendor/bin/phpunit` since phpstan-extension forces phpunit): verify present with canonical value. Three cases — **MISSING** (insert), **PRESENT** (leave), **MISMATCH** (prompt — show both sides, offer replace / skip). Common drift: POSIX-shell `post-install-cmd` referencing `vendor/bin/boost sync` is Windows-broken (canonical: `["SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"]`); `post-update-cmd` often missing entirely. Both HIGH severity. **Floor coupling (ATOMIC):** whenever this step WRITES a `PackageBoostPhp` façade callback into `post-install-cmd`/`post-update-cmd` — whether INSERTING a missing hook (the MISSING case) OR swapping an old `BoostCore\\Scripts\\BoostAutoSync::run` value (the MISMATCH case) — it MUST, in the same patch, ensure `sandermuller/package-boost-php` in `require-dev` is at `^0.16.0` (bump if lower: `composer require --dev "sandermuller/package-boost-php:^0.16.0"`). The façade class first ships in 0.16.0; writing the façade callback while the floor allows a pre-0.16 version leaves the autosync hook referencing a non-autoloadable class — Composer skip-warns (`class_exists()` guard in its `EventDispatcher`) and the hook silently no-ops on the next `composer install`/`update`, so autosync stays dead until the floor is fixed. This bites the partial-drift case especially: a scaffold that has only `post-install-cmd` (and is below the floor) gets `post-update-cmd` inserted as the façade callback — non-autoloadable until the floor moves with it. Never write the façade callback without ensuring the floor in the same patch — see the ATOMIC RULE in `composer-scripts.md`.
- **`extra.phpstan.includes`**: ensure `["extension.neon"]` is set. If existing array, ensure `extension.neon` is in it. Don't replace; add.
- **`autoload-dev.classmap`**: ensure `tests/Rules/stubs/` is in the classmap. If missing, insert as `["tests/Rules/stubs/"]` (preserving existing entries).
- **`config.allow-plugins`**: `phpstan/extension-installer: true`. Remove stale entries — ORDER MATTERS for `package-boost-php`:
  - `sandermuller/boost-core: true` — safe to remove unconditionally (`type: library` from 0.6.0).
  - `sandermuller/package-boost-php: true` — safe to remove ONLY when the installed `sandermuller/package-boost-php` is `≥ 0.9.0`. Verify with `composer show sandermuller/package-boost-php`. If `< 0.9.0`: FIRST bump the constraint in `require-dev` to `^0.9.0` and run `composer update sandermuller/package-boost-php`. Removing the entry while package-boost-php is still `< 0.9.0` blocks `composer install` with a `blocked-plugin` error.

  Both are Composer-ignored once library-typed (harmless but obsolete).
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
- **PHPUnit cache findings** (phpstan-extension always uses phpunit): apply `$REPO_INIT_HOME/references/phpunit-config.md` Upgrade-actions section — set `cacheDirectory=".cache/phpunit"`, `rm -rf .phpunit.cache`, `git rm -r --cached .phpunit.cache` if previously committed.
- **CI path filter drift — `phpstan.yml` missing `composer.json` / `composer.lock`**: insert both lines under the `push.paths` and `pull_request.paths` blocks in `.github/workflows/phpstan.yml`.
- **`.gitattributes` missing `.ai/ export-ignore`**: insert `.ai/ export-ignore` line after `.agents/ export-ignore` inside the `# >>> package-boost (managed) >>>` block.

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
