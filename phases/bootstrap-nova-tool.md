# Bootstrap: nova-tool

Greenfield setup of a Laravel Nova v5 tool — a package that ships a sidebar Nova tool with its own routes and views (Inertia-based).

> **Status**: v0.1 ships bootstrap only. Audit + upgrade defer to `phases/audit-laravel-package.md` and `phases/upgrade-laravel-package.md` (nova-tool is structurally a laravel-package). A dedicated `audit-nova-tool.md` + `upgrade-nova-tool.md` may ship in v0.2.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`. Stop if anything is red. Verify category-fit per `$REPO_INIT_HOME/references/detection-rules.md` (sub-flag for laravel-package: `laravel/nova` in `require`). Placeholder transforms used in this phase come from `$REPO_INIT_HOME/references/placeholder-rules.md`.

Verify Nova auth is configured. Laravel Nova is a paid package distributed via `composer.json` `repositories` entries pointing to `https://nova.laravel.com`. The user must have Nova credentials in `~/.composer/auth.json`:

```bash
grep -i nova ~/.composer/auth.json 2>/dev/null && echo "Nova auth present" || echo "Nova auth missing — surface to user"
```

Alternative (more authoritative, side-effect free) — probe via `composer show`:

```bash
composer show -a laravel/nova:^5.0 2>&1 | head -5
```

If the output contains "Could not find package" or any 401 / authentication error, stop and tell the user to run `composer config --global http-basic.nova.laravel.com <email> <license-key>` (or edit `~/.composer/auth.json` directly) before re-invoking.

## Inputs to collect

- `vendor` — required.
- `name` (kebab-case) — optional per target-dir rule.
- `description` — required.
- `php` — default `8.4` with `test-framework=pest` (Pest 5 requires PHP `^8.4`), `8.3` with `test-framework=phpunit`. Accepted: `8.3`, `8.4`, `8.5`. Reject `8.2`. Reject `pest` + `8.3` — ask the user which of the two to change.
- `laravel` — default `^12.0||^13.0`. (Laravel 11 support dropped in repo-init 0.3.0 — pao 1.x conflicts with Laravel <12.)
- `nova` — default `^5.0`. v4 is also supported but the stubs use v5 patterns.
- `test-framework` — default `pest`.
- `author-name` / `author-email` — defaults from git config.

Confirm derived `__NAMESPACE__` with the user once.

## Steps

### 1. Apply target-dir rule

- Positional `name` → `mkdir <name> && cd <name>`.
- No `name` → cwd must be empty modulo `.git/`.

### 2. Copy shared stubs

For each file under `$REPO_INIT_HOME/stubs/shared/`, copy to cwd. Substitute placeholders. **Boost config:** the shared boost stub lives at `.config/boost.php` (canonical) — skip it if EITHER `.config/boost.php` OR a legacy root `boost.php` already exists; never create both (boost-core ≥ 0.17 errors on two configs). See `$REPO_INIT_HOME/references/placeholder-rules.md` (Boost config location).

### 3. Copy nova-tool stubs

For each file under `$REPO_INIT_HOME/stubs/nova-tool/`:

- `composer.json` — has `laravel/nova: ^5.0` in `require` AND a `repositories` block pointing at `https://nova.laravel.com` (mandatory — Nova isn't on Packagist). The stub is Pest-flavoured, so it ships the PHP >= 8.4 dep set: `pestphp/*: ^5.0`, `symplify/phpstan-rules: ^14.12`, `tomasvotruba/type-coverage: ^2.3`, and NO `rector/type-perfect` (keeping type-perfect alongside type-coverage >= 2.3 double-registers `MethodNodeAnalyser` and PHPStan aborts at boot). Pest 5 requires PHP `^8.4`, so `php=8.3` is valid only with `test-framework=phpunit` — that combination has to restore the PHP 8.3 set (`symplify/phpstan-extensions: ^12.0`, `rector/type-perfect: ^2.1`, `tomasvotruba/type-coverage: >=2.2.0 <2.2.2`) and the 8.3 matrix cells. If `php=8.5`, add an `8.5` cell to `run-tests.yml`. For a Laravel package, `require-dev` takes `orchestra/testbench: ^11.0` and the CI matrix runs Laravel 13 cells only — Pest 5 needs `symfony/process: ^8.1` and testbench 10 pins `^7.2`. The runtime `illuminate/*` range stays `^12.0||^13.0` for consumers. See `references/shared-dev-deps.md` "Symplify formatter dep" and "Type-perfect dep".
- `src/__PACKAGE_STUDLY__ServiceProvider.php` — boots the tool's routes + assets when Nova is being served.
- `src/__PACKAGE_STUDLY__.php` — the actual `Laravel\Nova\Tool` subclass with `menu()` + `boot()`.
- `routes/inertia.php` — placeholder for tool routes (commented out in stub).
- `resources/views/.gitkeep`, `resources/js/.gitkeep`, `resources/css/.gitkeep`, `dist/js/.gitkeep`, `dist/css/.gitkeep` — placeholders for tool assets.

### 4. Compose test-framework variant

Same as `bootstrap-laravel-package.md` step 5.

### 5. Run `composer install`

```bash
composer install
```

If `laravel/nova` 401s, surface to user — they need `auth.json` with Nova license credentials. Do NOT proceed without it.

On other failures, consult `$REPO_INIT_HOME/references/composer-failure-modes.md`.

### 6. Run `composer require --dev` for the per-category dep list

Same as `bootstrap-laravel-package.md` step 7 (shared + laravel-package mandatory per `$REPO_INIT_HOME/references/per-category-deps.md#laravel-package`). nova-tool doesn't add extra dev deps. The boost-family member is `sandermuller/package-boost-laravel`, already in the stub `composer.json` `require-dev` — never the bare `sandermuller/package-boost-php`.

### 7. Install + sync target-local AI assets (optional)

Same as `bootstrap-laravel-package.md` step 9.

### 8. Run post-bootstrap verification

Open `$REPO_INIT_HOME/checklists/post-bootstrap-verification.md`.

Additionally for nova-tool:

```bash
php artisan nova:install --help    # confirms Nova is callable from this package's testbench
```

(Will fail if not in a Laravel app — that's fine; bootstrap is just confirming the binary is installed.)

### 9. Print next steps

```
✓ Bootstrap done for {vendor}/{name} (nova-tool).

Next:
- Implement the tool's menu + view in src/{__PACKAGE_STUDLY__}.php.
- Add routes in routes/inertia.php.
- Build the frontend (Vue/JS for Nova v4, Inertia/Vue for v5) and emit to dist/js/tool.js + dist/css/tool.css.
  Most Nova tools ship a Vite or webpack config separately (out of scope for repo-init scaffolding).
- Consumers install via `composer require {vendor}/{name}` then register in app/Providers/NovaServiceProvider.php:
    public function tools(): array {
        return [
            new \{Namespace}\{__PACKAGE_STUDLY__}(),
        ];
    }
- Set up the GitHub remote: `gh repo create {vendor}/{name} --public --source=. --remote=origin --push`.

For audit / upgrade later, use phases/audit-laravel-package.md and phases/upgrade-laravel-package.md.

Want to keep working, or are you done?
```

## What's next

- Keep working: open `$REPO_INIT_HOME/phases/audit-laravel-package.md`.
- Done: stop.

## Common issues

- **`composer require laravel/nova` 401s**: user lacks Nova license auth. Document the fix (add to `auth.json` with their nova.laravel.com credentials).
- **Tool not showing in Nova sidebar**: check `NovaServiceProvider::tools()` in the consuming app actually returns the tool. The stub doesn't auto-register; consumers must add it explicitly.
- **Asset publishing — `dist/` empty**: `dist/js/tool.js` + `dist/css/tool.css` are placeholders. User builds the frontend separately and emits to those paths. The `__PACKAGE_STUDLY__ServiceProvider` calls `Nova::script` + `Nova::style` pointing at them.
