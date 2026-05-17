# Detection rules

A flat decision table the agent runs against the target repo's `composer.json`. **First match wins.**

## Decision table

| # | Check | If true → category |
|---|---|---|
| 1 | `type: project` AND `laravel/framework` in `require` | `laravel-project` |
| 2 | `type: phpstan-extension` OR `extra.phpstan.includes` exists | `phpstan-extension` |
| 3 | `type: rector-extension` OR `extra.rector.includes` exists | `rector-extension` |
| 4 | (`type: library` OR missing) AND any of: `extra.laravel.providers` set, `illuminate/*` in `require`, `socialiteproviders/manager` in `require`, `spatie/laravel-package-tools` in `require` | `laravel-package` |
| 5 | `type: library` AND none of the above | `php-package` |
| 6 | None match | `unknown` — ask user |

## Sub-flags (informational; may modify chosen phase)

After the category is decided, also record:

- **`socialite-provider`** — `socialiteproviders/manager` in `require` → no `extra.laravel.providers` expected; Socialite providers register via the manager extension, not Laravel auto-discovery.
- **`mcp-bridge`** — `laravel/mcp` in `require` → workbench scripts recommended.
- **`hihaho-package-tools-flavoured`** — `spatie/laravel-package-tools` in `require` → use the `laravel-package-spatie` stub variant (ServiceProvider extends `PackageServiceProvider`).
- **`filament-plugin`** — `filament/filament` in `require` OR `extra.filament` set → route bootstrap to `phases/bootstrap-filament-plugin.md` instead of generic laravel-package bootstrap. Audit / upgrade fall through to laravel-package phases.
- **`nova-tool`** — `laravel/nova` in `require` → route bootstrap to `phases/bootstrap-nova-tool.md`. Audit / upgrade fall through to laravel-package phases.
- **`laravel-aware-extension`** (phpstan-extension / rector-extension only) — any `illuminate/*` in `require` → opt-in for Laravel-aware sub-recipe (adds `larastan/larastan` for phpstan extensions, `driftingly/rector-laravel` for rector extensions).

## Out-of-scope `type:` values

If `composer.json` `type:` is one of the following, the repo is out of scope for repo-init's five-category model:

- **`composer-plugin`** — composer plugins use composer-internal APIs and don't fit testbench-based testing. Conceptually closest to `php-package` but require `composer/composer` in `require-dev` + `extra.class` autoload entry. No repo-init stub variant; suggest the user run `audit-php-package.md` manually and skip testbench-related checks.
- **`metapackage`** — pure dependency aggregator; no source/tests/CI.
- **`drupal-*`, `wordpress-*`, `magento-*`** — out of scope, not PHP-package-shaped.

In all of these, the audit phase should detect early, print "category out of scope" naming the matched `type:`, and stop.

## Error cases

- `composer.json` missing AND user has not picked a category → ask user to confirm category.
- `composer.json` exists but is invalid JSON → stop and report the parse error to the user.
- User-supplied category value not in the five-category list → reject and re-prompt.

## How the audit phase consumes this

Audit phases call `detection-rules.md` once at the start, then ask the user to confirm any OPT-IN sub-flags (see `per-category-deps.md` for which opt-ins exist). Auto-inference: if the existing repo already shows evidence of the opt-in (e.g. `hihaho/phpstan-rules` already in `require-dev`), the opt-in defaults to `y`; otherwise to `N` (user can override).

## How the bootstrap phase consumes this

Bootstrap doesn't auto-detect — the user picks the category up front. The skill prompts.
