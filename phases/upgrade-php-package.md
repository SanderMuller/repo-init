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
- Mandatory: `phpstan/phpstan` (NEVER `larastan/larastan` — framework-agnostic), `stolt/lean-package-validator`, `sandermuller/package-boost-php` (the framework-agnostic boost umbrella; pulls `sandermuller/boost-core` transitively).

Test-framework: `pestphp/pest` + arch + rector-pest (pest), OR `phpunit/phpunit` (phpunit). Never pull `pestphp/pest-plugin-laravel` for php-package — framework-agnostic.

On failure, consult `references/composer-failure-modes.md`.

## Apply OUTDATED files per merge mode

Same logic as upgrade-laravel-package.md — apply each file's mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md`.

`PUBLIC_API.md`: `replace` mode for the section structure (headers). Content inside sections is user-owned (`notify-only`). If the stub has new sections the target doesn't, prompt to merge.

## Apply composer.json merge-keys patches

- **`scripts`**: **Read `$REPO_INIT_HOME/references/composer-scripts.md` IN FULL before patching.** Do NOT infer the canonical block from memory — a real laravel-package upgrade (2026-05-25) shipped a Windows-broken `post-install-cmd` and no `post-update-cmd` because the agent auto-completed from training data. For each documented key (12 for php-package: baseline 11 + `validate-gitattributes`; the `qa` chain appends `@validate-gitattributes` but `qa` is already in the baseline 11): verify present in target with canonical value. Three cases — **MISSING** (insert), **PRESENT** (leave), **MISMATCH** (prompt — show both sides, offer replace / skip). Common drift: `post-install-cmd` is a POSIX-shell conditional referencing `vendor/bin/boost sync` — Windows-broken, predates boost-core 0.6's PHP callback (`["SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"]`). `post-update-cmd` often missing entirely. Treat both as HIGH severity. **Floor coupling (ATOMIC):** whenever this step WRITES a `PackageBoostPhp` façade callback into `post-install-cmd`/`post-update-cmd` — whether INSERTING a missing hook (the MISSING case) OR swapping an old `BoostCore\\Scripts\\BoostAutoSync::run` value (the MISMATCH case) — it MUST, in the same patch, ensure `sandermuller/package-boost-php` in `require-dev` is at `^1.0` (repo-init's canonical floor; bump if lower: `composer require --dev "sandermuller/package-boost-php:^1.0"`). The façade class first ships in 0.16.0; writing the façade callback while the floor allows a pre-0.16 version leaves the autosync hook referencing a non-autoloadable class — Composer skip-warns (`class_exists()` guard in its `EventDispatcher`) and the hook silently no-ops on the next `composer install`/`update`, so autosync stays dead until the floor is fixed. This bites the partial-drift case especially: a scaffold that has only `post-install-cmd` (and is below the floor) gets `post-update-cmd` inserted as the façade callback — non-autoloadable until the floor moves with it. Never write the façade callback without ensuring the floor in the same patch — see the ATOMIC RULE in `composer-scripts.md`.
- **`config.allow-plugins`**: `pestphp/pest-plugin: true` (if pest), `phpstan/extension-installer: true`. Remove stale entries — but ORDER MATTERS:
  - `sandermuller/boost-core: true` — safe to remove unconditionally (boost-core ≥ 0.6.0 is `type: library`; pre-0.6.0 was a plugin but those versions are no longer available on Packagist).
  - `sandermuller/package-boost-php: true` — safe to remove ONLY when the installed `sandermuller/package-boost-php` is `≥ 0.9.0`. Verify with `composer show sandermuller/package-boost-php`. If the installed version is `< 0.9.0`: FIRST bump the constraint in `composer.json` `require-dev` to `^0.9.0` and run `composer update sandermuller/package-boost-php`. Removing the allow-plugins entry while package-boost-php is still `< 0.9.0` blocks the next non-interactive `composer install` with a `blocked-plugin` error, because pre-0.9.0 versions are still `type: composer-plugin`.

  Both entries are harmless-but-obsolete once the corresponding package is library-typed. Composer ignores them.
- **`config.sort-packages`**: `true`.
- Don't touch `extra` (php-package has no canonical extra keys from repo-init).

## Apply NON-CANONICAL fixes (each prompted)

- **`larastan/larastan` in `require-dev` for a php-package**: prompt "is this actually a laravel-package?" If user confirms yes, re-route to `audit-laravel-package.md` (don't continue with php-package upgrade). If no, remove larastan (`composer remove --dev larastan/larastan`) and ensure `phpstan/phpstan` is present.
- **`illuminate/*` in `require`**: same — re-route to laravel-package.
- **`composer.lock` committed**: prompt to `git rm --cached composer.lock`.
- **`phpunit.xml` (no .dist)**: prompt rename.
- **PHPUnit cache findings** (if `test-framework=phpunit`): apply `$REPO_INIT_HOME/references/phpunit-config.md` Upgrade-actions section — set `cacheDirectory=".cache/phpunit"`, `rm -rf .phpunit.cache`, `git rm -r --cached .phpunit.cache` if previously committed.
- **CI path filter drift — `phpstan.yml` missing `composer.json` / `composer.lock`**: insert both lines under the `push.paths` and `pull_request.paths` blocks in `.github/workflows/phpstan.yml`. Match indentation of surrounding entries.
- **`.gitattributes` missing `.ai/ export-ignore`**: insert `.ai/ export-ignore` line after `.agents/ export-ignore` inside the `# >>> package-boost (managed) >>>` block. Preserves alphabetical ordering.
- **PHP floor `^8.2`**: prompt bump.
- **Missing `validate-gitattributes` script**: insert it (via composer.json scripts merge above).
- **`.lpv` warnings on `vendor/bin/lean-package-validator validate`**: each artifact flagged in the audit. Prompt user: add the **bare path** (no `export-ignore` suffix) to `.lpv` AND the `<path> export-ignore` line to `.gitattributes` (inside the package-boost managed block). `.lpv` is a glob-pattern file, not `.gitattributes` syntax — see `references/gitattributes-managed-block.md` (`.lpv` file format).
- **`minimum-stability` / `prefer-stable`**: add `"minimum-stability": "stable"` + `"prefer-stable": true` to `composer.json` if absent or if `prefer-stable` isn't `true`. If `minimum-stability` is looser than `stable`, **default to tightening it to `stable`** — keep `dev` only when the author confirms the package is actively co-developed against unreleased sibling packages (being on `0.x`, or having downstream / production dependents, is a reason to tighten, NOT to keep `dev`; see `references/version-defaults.md`). Never loosen a passing `stable` baseline.

## Migrate boost config to `.config/` (canonical layout)

**Skip if:** `.config/boost.php` exists AND no root `boost.php` exists (already on the canonical layout).

boost-core ≥ 0.17's canonical config location is `.config/boost.php`; audit flags a legacy root `boost.php` as drift. To migrate:

1. **MOVE the file** — `mkdir -p .config && git mv boost.php .config/boost.php`. **Never copy** — leaving both `boost.php` and `.config/boost.php` is a hard error (`AmbiguousBoostConfigException`); every `boost` command then throws.
2. **Ensure boost-core ≥ 0.18** (the `.config/boost/` manifest layout): the `sandermuller/package-boost-php` umbrella (≥ 0.16.2) pulls boost-core ≥ 0.18 transitively — run `composer update sandermuller/package-boost-php`. No direct boost-core require to bump.
3. Run `vendor/bin/boost sync` — it auto-migrates the gitignored sync manifest `.boost/ → .config/boost/`, rewrites the managed `.gitignore` block to ignore `.config/boost/`, and refreshes the managed `.gitattributes` block. Migration is bidirectional + automatic; `vendor/bin/boost sync --check` reports the one-time stale-manifest cleanup as advisory only (never drift).
4. **`.gitattributes`:** ensure `.config/ export-ignore` is in the `# >>> package-boost (managed) >>>` block (preserved as a foreign line by the writer); remove any stale `boost.php export-ignore` line. Also update `.lpv`: replace the `boost.php` glob with `.config/`.
5. **Both-present guard:** if a prior bad copy left BOTH `boost.php` and `.config/boost.php`, do NOT run `boost sync` until resolved — delete the root `boost.php`, keep `.config/boost.php`.

## Migrate the boost config API (`withTags` array form)

**Skip if:** the boost config's `withTags(...)` / `withAgents(...)` calls already pass a single array argument (`->withTags([...])`).

boost-core 0.20 changed every `BoostConfig` builder method to take a single `array` — `withTags()` was the last variadic one. A pre-0.20 call like `->withTags(Tag::Php, Tag::Github)` throws the moment `boost.php` / `.config/boost.php` is loaded (a raw `TypeError` on boost-core 0.20–0.22; a catchable `InvalidBoostConfigException` carrying a migration hint on ≥ 0.23), so `composer install`/`update` autosync and every `boost` command fail until it is fixed. `boost sync` cannot auto-migrate it — loading the config executes the call first. Fix by hand — wrap the arguments in brackets:

```php
// before (pre-0.20 variadic — breaks under boost-core >= 0.20)
->withTags(Tag::Php, Tag::Github)
// after
->withTags([Tag::Php, Tag::Github])
```

Independent of the `.config/` location move above — this applies even to a repo already on the `.config/` layout. It is the one hand-edit the boost `1.x` floor bump requires, because that bump crosses the 0.20 break.

## Run package-boost sync

```bash
vendor/bin/boost sync
```

`vendor/bin/boost` is boost-core's standalone bin (pulled transitively via `sandermuller/package-boost-php`); the framework-agnostic categories carry no `orchestra/testbench`, so the old `vendor/bin/testbench package-boost:sync` form does not apply. The `post-install-cmd` / `post-update-cmd` autosync hook runs the same sync automatically on `composer install`/`update`.

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
