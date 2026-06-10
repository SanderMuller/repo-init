# Bootstrap: filament-plugin

Greenfield setup of a Filament v3/v4 plugin — a Laravel package that registers Filament resources, pages, or widgets via the Plugin contract.

> **Status**: v0.1 ships bootstrap only. Audit + upgrade for this category defer to `phases/audit-laravel-package.md` and `phases/upgrade-laravel-package.md` (filament-plugin is structurally a laravel-package; the audit/upgrade logic applies). A dedicated `audit-filament-plugin.md` + `upgrade-filament-plugin.md` may ship in v0.2 if Filament-specific drift becomes a recurring need.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`. Stop if anything is red. Verify category-fit per `$REPO_INIT_HOME/references/detection-rules.md` (sub-flag for laravel-package: `extra.filament` set OR `filament/filament` in `require`). Placeholder transforms used in this phase come from `$REPO_INIT_HOME/references/placeholder-rules.md`.

## Inputs to collect

- `vendor` — required.
- `name` (kebab-case) — optional per target-dir rule.
- `description` — required.
- `php` — default `8.3`.
- `laravel` — default `^12.0||^13.0`. (Laravel 11 support dropped in repo-init 0.3.0 — pao 1.x conflicts with Laravel <12.)
- `filament` — default `^3.0||^4.0`. User may pin to `^4.0` only if targeting Filament v4 features.
- `test-framework` — default `pest`.
- `author-name` / `author-email` — defaults from git config.

Confirm derived `__NAMESPACE__` with the user once.

## Steps

### 1. Apply target-dir rule

- Positional `name` → `mkdir <name> && cd <name>`.
- No `name` → target IS cwd, must be empty modulo `.git/`.

### 2. Copy shared stubs

For each file under `$REPO_INIT_HOME/stubs/shared/`, copy to cwd. Substitute placeholders. Skip `tests/Pest.php` if `test-framework=phpunit`. **Boost config:** the shared boost stub lives at `.config/boost.php` (canonical) — skip it if EITHER `.config/boost.php` OR a legacy root `boost.php` already exists; never create both (boost-core ≥ 0.17 errors on two configs). See `$REPO_INIT_HOME/references/placeholder-rules.md` (Boost config location).

### 3. Copy filament-plugin stubs

For each file under `$REPO_INIT_HOME/stubs/filament-plugin/`, copy to cwd. Substitute placeholders, including file-path placeholders.

Key files:

- `composer.json` — has `filament/filament: ^3.0||^4.0` in `require`. Substitute `__LARAVEL_VERSIONS__`. Symplify dep is PHP-floor-conditional: the stub ships `symplify/phpstan-extensions: ^12.0` (installable on every accepted floor; matches the default `php=8.3`); if `php=8.4` or `8.5`, replace it with `symplify/phpstan-rules: ^14.11` AND align the `run-tests.yml` matrix with the chosen floor — drop cells below it and add cells the stub matrix lacks (it ships 8.3/8.4 cells only, so `php=8.5` needs an 8.5 cell) (see `references/shared-dev-deps.md` "Symplify formatter dep").
- `src/__PACKAGE_STUDLY__ServiceProvider.php` — extends `Illuminate\Support\ServiceProvider` AND implements `Filament\Contracts\Plugin`. Has dual-mode `register(?Panel $panel = null)` and `boot(?Panel $panel = null)` so the class works both as a Laravel ServiceProvider AND a Filament plugin registered via `$panel->plugin(YourPlugin::make())`.
- `resources/views/.gitkeep` — placeholder for Filament-style Blade views (commented out in stub; user uncomments + uses).

### 4. Compose test-framework variant

Same as `bootstrap-laravel-package.md` step 5.

### 5. Run `composer install`

```bash
composer install
```

On failure, consult `$REPO_INIT_HOME/references/composer-failure-modes.md`.

### 6. Run `composer require --dev` for the per-category dep list

Build the list the same as `bootstrap-laravel-package.md` step 7 (shared + laravel-package mandatory per `$REPO_INIT_HOME/references/per-category-deps.md#laravel-package`). filament-plugin doesn't add extra dev deps beyond what laravel-package already requires.

Suggest: depending on the plugin shape, the user may want `filament/forms`, `filament/tables`, `filament/notifications` etc. in `require-dev` for tests. Defer to user choice.

### 7. Install + sync target-local AI assets (optional)

Same as `bootstrap-laravel-package.md` step 9.

### 8. Run post-bootstrap verification

Open `$REPO_INIT_HOME/checklists/post-bootstrap-verification.md`.

### 9. Print next steps

```
✓ Bootstrap done for {vendor}/{name} (filament-plugin).

Next:
- Implement the plugin's Filament-specific behaviour in src/{__PACKAGE_STUDLY__}ServiceProvider.php's
  register(?Panel $panel) and boot(?Panel $panel) methods.
- Add resources / pages / widgets under src/Resources/, src/Pages/, src/Widgets/.
- Consumers install via `composer require {vendor}/{name}` then register on a panel:
    $panel->plugin({Namespace}\{__PACKAGE_STUDLY__}ServiceProvider::make());
- Set up the GitHub remote: `gh repo create {vendor}/{name} --public --source=. --remote=origin --push`.
- Run `composer qa` to confirm baseline.

For audit / upgrade later, use phases/audit-laravel-package.md and phases/upgrade-laravel-package.md
(filament-plugin uses laravel-package's audit/upgrade logic). A dedicated filament-plugin
audit + upgrade may ship in repo-init v0.2.

Want to keep working, or are you done?
```

## What's next

- Keep working: open `$REPO_INIT_HOME/phases/audit-laravel-package.md` (handles filament-plugin via laravel-package logic).
- Done: stop. Repo-init lives globally; nothing to remove from this target.

## Common issues

- **Filament v3 vs v4 incompatible APIs**: the stub `Plugin` contract works with both. If you pin to `filament/filament: ^4.0` only, you can simplify the `register()`/`boot()` signatures. If you support both v3 + v4, keep the dual-mode signature.
- **`$panel->plugin(MyPlugin::make())` errors with "Plugin not found"**: the stub uses `make()` static returning `new static()`. If consumers use `MyPlugin::make()` in their `PanelProvider`, this should just work. Verify the `Plugin` contract import (`Filament\Contracts\Plugin`).
- **Asset publishing not wired**: the stub has the `loadViewsFrom` / `publishes` lines commented out. Uncomment when you add views.
