# Upgrade: laravel-project

Apply the audit findings to an existing Laravel application.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md` AND re-run audit: open `$REPO_INIT_HOME/phases/audit-laravel-project.md`.

## Safety rails

Same as `upgrade-laravel-package.md` §Honor the safety rails. Per-category never-touch is critical for laravel-project (auth middleware, policies, config/auth*.php, routes/auth.php, .env — never write); enforce via `$REPO_INIT_HOME/checklists/per-category-never-touch.md` + git-dirty rule before every write. Verify category-fit one more time via `$REPO_INIT_HOME/references/detection-rules.md`; dep expectations come from `$REPO_INIT_HOME/references/per-category-deps.md`.

## Apply MISSING files

For each MISSING file:

1. Read stub from `$REPO_INIT_HOME/stubs/<shared|laravel-project>/<path>`.
2. Substitute placeholders.
3. Write — prompt on conflict per `replace` mode.

`README.append.md` is handled specially: APPEND its content to the existing `README.md` (laravel-project ships a README from `laravel new`). Never overwrite the README.

## Apply MISSING runtime deps

Skipped — laravel-project doesn't have repo-init-mandated runtime deps (the user owns their application's `require` block).

## Apply MISSING dev deps

Per-category mandatory `require-dev` for `laravel-project`:

- `larastan/larastan`
- `laravel/boost`
- `laravel/pail`
- `laravel/tinker` (Laravel may ship this already)
- `driftingly/rector-laravel`

Plus shared dev deps from `$REPO_INIT_HOME/references/shared-dev-deps.md` minus what Laravel installer typically already ships (read freshly-generated composer.json to confirm): `laravel/pao`, `laravel/pint` (already), `phpstan/extension-installer`, `phpstan/phpstan-strict-rules`, `phpstan/phpstan-deprecation-rules`, `phpstan/phpstan-phpunit`, `rector/rector`, `rector/type-perfect`, `spaze/phpstan-disallowed-calls`, `symplify/phpstan-extensions`, `tomasvotruba/cognitive-complexity`, `tomasvotruba/type-coverage`, `nunomaduro/collision` (Laravel ships), `orchestra/testbench` (typically NOT in laravel-project — skip). `laravel-project` does NOT take `sandermuller/package-boost-php` — `laravel/boost` (above) is its boost-family tool.

Plus confirmed opt-ins:

- `--with-hihaho-rules`: `hihaho/phpstan-rules`, `hihaho/rector-rules`, `symplify/phpstan-rules`
- `--with-security-advisories`: `roave/security-advisories: dev-latest`

Single batched `composer require --dev <list>` call.

**Test framework note**: if the user has both `pestphp/pest` and `phpunit/phpunit` from prior installs, ask which to keep. Don't auto-resolve — wrong choice rewrites test scaffolding.

Common: laravel-project usually has `phpunit/phpunit` from `laravel new`. If user opted into Pest in audit, add Pest deps and instruct them to run `vendor/bin/pest --init` separately to migrate tests.

On failure, consult `references/composer-failure-modes.md`.

## Apply OUTDATED files per merge mode

Same logic as upgrade-laravel-package.md — apply each file's mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md`. With laravel-project paths.

**Special handling for `.editorconfig`**: Laravel installer ships its own; ours overrides for strict utf-8/lf/4-space. If user has accepted Laravel's defaults for years, ask before clobbering — they may have intentional team-wide conventions you don't want to override.

**`.gitattributes`**: managed-block merge. The package-boost block may not exist yet on older projects — bootstrap creates it. Upgrade may need to create it on first run; then insert our entries inside.

**`phpunit.xml` vs `phpunit.xml`**: Laravel ships `phpunit.xml` (no `.dist`). Ours says use `.dist`. NON-CANONICAL fix handles the rename — see below.

## Apply composer.json merge-keys patches

Per `references/composer-scripts.md`:

- **`scripts`**: **Read `$REPO_INIT_HOME/references/composer-scripts.md` IN FULL before patching.** Do NOT infer the canonical block from memory — a real laravel-package upgrade (2026-05-25) shipped a Windows-broken `post-install-cmd` and no `post-update-cmd` because the agent auto-completed from training data. For each documented key (10 for laravel-project: baseline 11 minus `sync-ai`; `test` / `test-coverage` may already be present from `laravel new`, don't override): verify present with canonical value. Three cases — **MISSING** (insert), **PRESENT** (leave), **MISMATCH** (prompt — show both sides, offer replace / skip).

  laravel-project does NOT get a `sync-ai` script — `laravel/boost` owns AI-asset sync for applications (`php artisan boost:update`); there is no `vendor/bin/boost` here.

  **`post-install-cmd` / `post-update-cmd` are scaffold-conditional**: the canonical `["SanderMuller\\BoostCore\\Scripts\\BoostAutoSync::run"]` value requires `sandermuller/boost-core` to be in the dependency tree. A vanilla laravel-project does NOT pull boost-core — it uses `laravel/boost`. Check first; if boost-core absent, skip these two keys entirely. If a POSIX-shell `post-install-cmd` is present in a laravel-project without boost-core, the value should be REMOVED (Windows-broken AND the binary doesn't exist) — prompt the user. HIGH severity drift either way.
- **`scripts.dev`**: if absent, suggest adding the multi-process dev script (concurrent server + queue + pail + vite). This is laravel-project canonical. Show example, ask before inserting.
- **`config.allow-plugins`**: insert `phpstan/extension-installer: true`, `pestphp/pest-plugin: true` (if pest), `php-http/discovery: true` (Laravel default).
- **`config.sort-packages`**: set to `true`.

Don't touch `extra.laravel.providers` for laravel-project — Laravel uses `extra.laravel.dont-discover` etc.; user owns the `extra.laravel.*` block.

## Apply NON-CANONICAL fixes (each prompted)

- **`phpunit.xml` (no .dist)**: prompt "rename to `phpunit.xml`?" Only if `.dist` doesn't already exist.
- **PHPUnit cache findings** (if `test-framework=phpunit`): apply `$REPO_INIT_HOME/references/phpunit-config.md` Upgrade-actions section — set `cacheDirectory=".cache/phpunit"`, `rm -rf .phpunit.cache`, `git rm -r --cached .phpunit.cache` if previously committed.
- **CI path filter drift — `phpstan.yml` missing `composer.json` / `composer.lock`**: insert both lines under the `push.paths` and `pull_request.paths` blocks in `.github/workflows/phpstan.yml`.
- **`.gitattributes` missing `.ai/ export-ignore`**: insert `.ai/ export-ignore` line after `.agents/ export-ignore` inside the `# >>> package-boost (managed) >>>` block.
- **PHP floor `^8.2`**: prompt to bump.
- **Both larastan + bare phpstan**: prompt to remove `phpstan/phpstan`.
- **`composer.lock` NOT committed** (rare — Laravel convention is to commit it for apps): prompt to add to git.
- **Two managed blocks in `.gitattributes`**: same as upgrade-laravel-package.md.

## Apply `.gitignore` append-only

Add laravel-project-specific lines if missing:

```
/public/build
/public/hot
/public/storage
/storage/pail
_ide_helper.php
_ide_helper_models.php
.phpstorm.meta.php
```

Dedupe — never add a duplicate.

## Run laravel/boost sync

`laravel-project` uses `laravel/boost` (not `sandermuller/boost-core`) for AI-asset sync. Laravel Boost v2 installs and updates skills from the packages detected in `composer.json`:

```bash
php artisan boost:update
```

If `laravel/boost` isn't installed yet, run `php artisan boost:install` first (or `composer require laravel/boost` then `php artisan boost:install`).

## Verification

Open `$REPO_INIT_HOME/checklists/post-upgrade-verification.md`.

Plus laravel-project-specific:

```bash
php artisan --version
php artisan test --compact
composer phpstan-simplified
```

## What's next

- Keep working: next phase or re-audit.
- Done: stop.

## Common issues

- **`composer dev` script conflicts with existing dev runner**: user may have their own `dev` workflow (Sail, Herd, custom). Ask before inserting our concurrent runner.
- **Laravel installer ships file we want to keep, audit flagged it as OUTDATED**: tell the user — drift from our stub may be intentional Laravel updates. `notify-only` mode catches most of these. If it's a `replace`-mode file, defer to the user.
- **`hihaho/phpstan-rules` not installable** (private repo or auth-required): if user opted in but install fails, surface the auth.json / Packagist credentials guidance; don't strip the opt-in.
