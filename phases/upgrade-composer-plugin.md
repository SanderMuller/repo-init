# Upgrade: composer-plugin

Apply audit findings to an existing framework-agnostic Composer plugin.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md` AND re-run audit: open `$REPO_INIT_HOME/phases/audit-composer-plugin.md`.

## Safety rails

Same as `upgrade-laravel-package.md` §Honor the safety rails. Honour `$REPO_INIT_HOME/checklists/per-category-never-touch.md` (no Laravel-specific never-touch; `.env*` and `.git/` apply universally) and the git-dirty rule before every write. Verify category-fit one more time via `$REPO_INIT_HOME/references/detection-rules.md`; dep expectations come from `$REPO_INIT_HOME/references/per-category-deps.md#composer-plugin`.

## Apply MISSING files

For each MISSING file:

1. Read stub from `$REPO_INIT_HOME/stubs/<shared|composer-plugin>/<path>`.
2. Substitute placeholders.
3. Write — prompt on conflict per `replace` mode.

If `extra.class` is missing from composer.json: insert `"extra": { "class": "<derived-FQCN>\\Plugin" }` block, where the FQCN is derived from the PSR-4 mapping in `autoload`.

If `src/Plugin.php` is missing: copy from `$REPO_INIT_HOME/stubs/composer-plugin/src/Plugin.php`, substitute `__NAMESPACE_ESCAPED__`.

## Apply MISSING runtime deps

Single `composer require` for runtime deps:

- `composer-plugin-api: ^2.6` (mandatory). If user is targeting older Composer API, they own the deviation — flag and skip.
- `composer-runtime-api: ^2.2` (only if sub-flag `runtime-api=y`).

## Apply MISSING dev deps

Single batched `composer require --dev <list>`. Shared (minus exclusions) + category-mandatory:

- Mandatory: `composer/composer: ^2.6`, `sandermuller/package-boost-php` (the framework-agnostic boost umbrella; pulls `sandermuller/boost-core` transitively — composer-plugin is a framework-agnostic Composer package, so it gets it like the other agnostic categories).
- Shared list from `references/shared-dev-deps.md`, MINUS: `orchestra/testbench`.
- Plus `phpstan/phpstan` (NEVER `larastan/larastan` — framework-agnostic), `stolt/lean-package-validator`.
- Test-framework: `pestphp/pest` + arch + rector-pest (pest), OR `phpunit/phpunit` (phpunit). NEVER `pestphp/pest-plugin-laravel` — framework-agnostic.

On failure, consult `references/composer-failure-modes.md`.

## Apply OUTDATED files per merge mode

Same logic as upgrade-php-package.md — apply each file's mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md`.

## Apply composer.json merge-keys patches

- **`scripts`**: **Read `$REPO_INIT_HOME/references/composer-scripts.md` IN FULL before patching.** Do NOT infer the canonical block from memory — a real laravel-package upgrade (2026-05-25) shipped a Windows-broken `post-install-cmd` and no `post-update-cmd` because the agent auto-completed from training data. For each documented key (11 for composer-plugin: baseline 11 minus `sync-ai` + `validate-gitattributes`; `qa` includes `@validate-gitattributes`. The composer-plugin stub deliberately omits `sync-ai` because the BoostAutoSync hooks already trigger sync via PHP callback.): verify present with canonical value. Three cases — **MISSING** (insert), **PRESENT** (leave), **MISMATCH** (prompt — show both sides, offer replace / skip). Common drift: POSIX-shell `post-install-cmd` referencing `vendor/bin/boost sync` is Windows-broken (canonical: `["SanderMuller\\BoostCore\\Scripts\\BoostAutoSync::run"]`); `post-update-cmd` often missing entirely. Both HIGH severity.
- **`config.allow-plugins`**: self-allow entry (`"<vendor>/<package>": true`), `pestphp/pest-plugin: true` (if pest), `phpstan/extension-installer: true`, `sandermuller/package-boost-php: true` (MANDATORY — still `type: composer-plugin` post boost-core 0.6.0; without it the first non-interactive `composer install` is blocked). NO `sandermuller/boost-core` entry — boost-core 0.6.0 is `type: library`; if a pre-0.6.0 scaffold left `sandermuller/boost-core: true` in place, remove it (Composer ignores it, harmless but stale). If any other composer-plugin is in require/require-dev, add those too.
- **`config.sort-packages`**: `true`.
- **`extra.class`**: required for composer-plugin. Must resolve to a class implementing `PluginInterface`. If missing, insert per MISSING files step above.

## Apply NON-CANONICAL fixes (each prompted)

- **`extra.class` missing**: insert per MISSING files step.
- **`extra.class` points to a nonexistent class**: surface to user — either create the class file (offer to copy from stub) or fix the FQCN to match an existing class.
- **`extra.class` resolves to a class that doesn't implement `PluginInterface`**: prompt to add `implements PluginInterface` + the three required no-op methods (activate/deactivate/uninstall). Offer the stub skeleton.
- **`composer/composer` in `require` instead of `require-dev`**: `composer remove composer/composer && composer require --dev "composer/composer:^2.6"`. Heavy dep; never ship at runtime.
- **Self-allow missing in `config.allow-plugins`** (and any other composer-plugin deps): insert via merge-keys patch above. Without these, `composer install` blocks with "blocked by your allow-plugins config".
- **`command-provider` shape commands extend wrong parent**: Composer's plugin command-provider path requires commands to extend `Composer\Command\BaseCommand` (the native parent for plugin commands). Change each offending command class's parent to `Composer\Command\BaseCommand`. A Symfony-Console-style adapter wrapping is technically possible but solves a dual-surface problem (a plugin that also ships a standalone bin without `composer/composer` available) — not a general fix path. Prefer the native parent.
- **`event-subscriber` shape with empty `getSubscribedEvents()`**: confirm intent with user. If the plugin should hook events, list the missing handlers (commonly POST_AUTOLOAD_DUMP for sync-on-install plugins).
- **`larastan/larastan` / `illuminate/*` / `orchestra/testbench`**: confirm "does this plugin need Laravel runtime?" If yes (rare), suggest re-categorizing as `laravel-package` with a composer-plugin wrapper. If no, remove the offending deps.
- **`composer.lock` committed**: prompt to `git rm --cached composer.lock`.
- **`phpunit.xml` (no .dist)**: prompt rename.
- **PHPUnit cache findings** (if `test-framework=phpunit`): apply `$REPO_INIT_HOME/references/phpunit-config.md` Upgrade-actions section — set `cacheDirectory=".cache/phpunit"`, `rm -rf .phpunit.cache`, `git rm -r --cached .phpunit.cache` if previously committed.
- **CI path filter drift — `phpstan.yml` missing `composer.json` / `composer.lock`**: insert both lines under the `push.paths` and `pull_request.paths` blocks in `.github/workflows/phpstan.yml`.
- **`.gitattributes` missing `.ai/ export-ignore`**: insert `.ai/ export-ignore` line after `.agents/ export-ignore` inside the `# >>> package-boost (managed) >>>` block.
- **PHP floor `^8.2`**: prompt bump.
- **Missing `validate-gitattributes` script**: insert it.
- **`.lpv` warnings**: each missing export-ignore line listed in the audit. Add to `.lpv` AND to `.gitattributes` managed block.

## Run package-boost sync

Composer plugins don't typically ship `.ai/` or use package-boost. SKIP unless the plugin is itself a boost-skill-provider (`resources/boost/skills/` present) — then:

```bash
vendor/bin/boost sync
```

(boost-core's binary, not testbench — composer-plugin category doesn't have testbench in deps.)

## Verification

Open `$REPO_INIT_HOME/checklists/post-upgrade-verification.md`. Plus:

```bash
composer validate-gitattributes
composer dump-autoload
php -r "require 'vendor/autoload.php'; new <FQCN-from-extra.class>();"
```

If the last command exits 0, plugin class autoloads cleanly. Non-zero exit = autoload mapping issue; re-check PSR-4 + `extra.class` consistency.

## What's next

- Keep working: next phase or re-audit.
- Done: stop.

## Common issues

- **`composer install` errors with "Plugin capability X returned an invalid value"**: command-provider sub-flag declared but commands extend `Symfony\Component\Console\Command\Command` instead of `Composer\Command\BaseCommand`. Change the parent class to `Composer\Command\BaseCommand` (the native parent for plugin commands).
- **Plugin not loading at all (silent)**: `extra.class` typo or PSR-4 mismatch. `composer dump-autoload -v` shows the resolved autoload paths.
- **End users blocked by allow-plugins**: document in README — consumers must run `composer config allow-plugins.{vendor}/{name} true` once, OR `composer global require` answers the interactive prompt.
- **`composer/composer` install pulls dozens of transitive deps**: expected; `composer/composer` itself depends on symfony/console, react/promise, etc. Live with it — dev-only.
- **PHPStan complains about `Composer\*` namespace not autoloadable in CI**: needs `composer/composer` in `require-dev` (it is, mandatory). If CI's `composer install --no-dev`, PHPStan can't analyse. Run PHPStan with dev deps installed.
