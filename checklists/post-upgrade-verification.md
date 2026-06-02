# Post-upgrade verification

Run after every upgrade phase. If anything is red, stop and report to the user before declaring the upgrade complete.

## Category note — `skill-bundle`

`skill-bundle` ships pure-markdown skills and no PHP source. For a `skill-bundle` target, **skip** the "Tooling smoke tests" PHPStan / Rector / Tests items (only `vendor/bin/pint --test` applies) and the larastan-vs-phpstan exclusivity check (neither is installed). Composer integrity, Git state, AI tooling sync, and the `skill-bundle` entry under "Per-category extras" still apply.

## Composer integrity

- [ ] `composer validate` returns 0.
- [ ] `composer install` runs cleanly after the upgrade (no new conflicts; lockfile resolves).
- [ ] No package in both `require` AND `require-dev` (per §5.1.1 exclusivity):

  ```bash
  composer show --installed --tree | grep -E '(rector/rector|phpstan/phpstan|spatie/laravel-package-tools|driftingly/rector-laravel)' | head -10
  ```

- [ ] `larastan` vs `phpstan/phpstan` exclusivity (per §5.3):

  ```bash
  composer show --installed | grep -E '^(larastan/larastan|phpstan/phpstan) '
  ```

  Laravel-aware categories: only `larastan/larastan`. Framework-agnostic: only `phpstan/phpstan`.

## Tooling smoke tests

- [ ] **Pint clean**: `vendor/bin/pint --test` returns 0 (or shows acceptable formatting drift the user agreed to address separately).
- [ ] **PHPStan green**: `vendor/bin/phpstan analyse --no-progress --memory-limit=2G` returns 0. If new errors appeared post-upgrade, surface them — they may be due to bumped rules from a new shared dep version.
- [ ] **Rector dry-run clean**: `vendor/bin/rector process --dry-run` reports 0 changes (or only changes the user explicitly opted in to). If new rector rules were added via the upgrade, this may report changes — surface and ask user whether to apply.
- [ ] **Tests pass**: `vendor/bin/pest --ci` (or `vendor/bin/phpunit`) returns 0. If pre-existing test failures, mention but don't block — the upgrade isn't responsible for those.

## Per-category extras

### `laravel-project`

- [ ] `php artisan --version` runs.
- [ ] `php artisan test --compact` returns 0 (or pre-existing failures).
- [ ] `vendor/bin/boost sync` ran without error (boost-core's standalone bin).

### `laravel-package`

- [ ] `vendor/bin/testbench package-boost:sync` ran.
- [ ] `vendor/bin/testbench package:discover --ansi` runs (workbench scripts are wired).
- [ ] (If workbench used) `vendor/bin/testbench serve --ansi` smoke test loads `/preview` without 500.

### `php-package`

- [ ] `composer validate-gitattributes` returns 0 (or surfaces specific export-ignore lines still needed).

### `skill-bundle`

- [ ] `composer validate-gitattributes` returns 0 (or surfaces specific export-ignore lines still needed).
- [ ] `sandermuller/boost-core` is in `require` (runtime), NOT `require-dev`.
- [ ] `config.allow-plugins` does NOT list `sandermuller/boost-core: true` (stale post boost-core 0.6.0 — `type: library`). For `skill-bundle`, `config.allow-plugins` is typically empty.
- [ ] `resources/boost/skills/` holds at least one `<skill-name>/SKILL.md`.

### `phpstan-extension`

- [ ] `vendor/bin/phpunit` runs (test framework callable).
- [ ] `composer show phpstan/phpstan` in `require` (not `require-dev`).
- [ ] `extra.phpstan.includes` references an existing `extension.neon` file.
- [ ] `autoload-dev.classmap` includes `tests/Rules/stubs/`.

### `rector-extension`

- [ ] `vendor/bin/rector --version` runs.
- [ ] `composer show rector/rector` in `require` (not `require-dev`).
- [ ] `extra.rector.includes` references an existing `config/config.php` file.
- [ ] `config.allow-plugins.rector/extension-installer` is `true`.

## Git state

- [ ] `git status` reflects only the upgrade-driven changes — no unexpected modifications.
- [ ] (Optional) Suggest the user review and commit: `git add -A && git status`.

## AI tooling sync

- [ ] `.claude/skills/repo-init/SKILL.md` still present (sync didn't accidentally remove it).
- [ ] `.claude/skills/`, `.cursor/skills/`, `.agents/skills/` reflect any new or updated `.ai/skills/` content from the upgrade.

## Boost config layout (`.config/` canonical)

Applies to every category except `laravel-project` (which has no boost-core config).

- [ ] `.config/boost.php` is present (the canonical config location).
- [ ] No root `boost.php` remains — if the upgrade migrated one, it was **moved**, not copied. Both present is a hard error (`AmbiguousBoostConfigException`).
- [ ] The gitignored sync manifest is at `.config/boost/manifest.json` (not root `.boost/`); `vendor/bin/boost sync --check` may report a one-time stale-manifest cleanup as advisory — that is expected, not drift.
- [ ] The `.gitattributes` managed block contains `.config/ export-ignore` and no stale `boost.php export-ignore` line.

## Stop conditions

Stop and report to the user if ANY of:

- BOTH `.config/boost.php` AND a root `boost.php` exist (boost-core hard error — every `boost` command throws until one is removed).
- `composer install` fails post-upgrade.
- A package was installed in BOTH `require` and `require-dev` (`composer show` reveals).
- Both larastan + bare phpstan are installed.
- A never-touch path (per `checklists/per-category-never-touch.md`) was written to.
- `composer validate` reports errors.
- Lockfile + composer.json are out of sync.

In any of these cases, do NOT declare the upgrade complete. Surface the gap to the user with the offending file/dep/finding.

## When everything's green

```
✓ Upgrade complete for {target}.

Changes applied:
  - {N} MISSING files written
  - {N} composer require / require --dev calls succeeded
  - {N} OUTDATED files updated per merge mode
  - {N} composer.json keys patched
  - {N} NON-CANONICAL fixes accepted

Drifted but not auto-fixed (notify-only):
  - {list of phpstan.neon.dist / rector.php / etc. mentioned in audit but left alone}

Want to:
  - Commit the changes? Run `git add -A && git status` to review, then commit.
  - Run another audit? `phases/audit-{category}.md`.
  - Done? Stop. Repo-init lives globally; nothing to remove from this target.
```
