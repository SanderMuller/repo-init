# Canonical reference repos

One per category. Each stub in `stubs/` was generated from the corresponding canonical reference — the CI drift-detection job (Phase 7) diffs stubs against these.

## `laravel-package` (sander-style)

**Reference**: [`SanderMuller/laravel-queue-insights`](https://github.com/SanderMuller/laravel-queue-insights)

What to look at:

- `composer.json` — `extra.laravel.providers`, the multi-version `illuminate/*` range `^12.0||^13.0` (Laravel 11 dropped in repo-init 0.3.0), the `qa` script chain.
- `testbench.yaml` — providers list, dev `APP_KEY`, array stores.
- `workbench/app/Providers/WorkbenchServiceProvider.php` — the bootstrap helper for Testbench-served preview.
- `.github/workflows/run-tests.yml` — the matrix structure (PHP × Laravel × stability × redis-client).
- `phpstan.neon.dist` — level=max + bleedingEdge + type_coverage + cognitive_complexity + strictRules.allRules + spaze/disallowed-calls includes.
- `rector.php` — withCache + withParallel + Laravel sets + Pest sets.

## `laravel-package-spatie` (hihaho-style)

**Reference**: [`hihaho/laravel-js-store`](https://github.com/hihaho/laravel-js-store)

What to look at:

- `composer.json` — `spatie/laravel-package-tools` in `require`, PHPUnit (not Pest) for `test` script.
- `src/<Package>ServiceProvider.php` — extends `Spatie\LaravelPackageTools\PackageServiceProvider`, implements `configurePackage(Package $package)`.
- Use this variant when the user is on `vendor=hihaho` OR when the audit detects `spatie/laravel-package-tools` already in `require`.

## `php-package` (framework-agnostic)

**Reference**: [`SanderMuller/solana-pubkey`](https://github.com/SanderMuller/solana-pubkey)

What to look at:

- `composer.json` — NO `illuminate/*` in `require`, only `php` + `ext-sodium`. `stolt/lean-package-validator` in `require-dev`, `validate-gitattributes` script.
- `.lpv` — lean-package-validator config.
- `PUBLIC_API.md` — semver surface doc.
- `phpstan.neon.dist` — same shape as laravel-package but no Larastan.

## `phpstan-extension`

**Reference**: [`SanderMuller/laravel-fluent-validation-phpstan`](https://github.com/SanderMuller/laravel-fluent-validation-phpstan)

What to look at:

- `composer.json` — `type: phpstan-extension`, `extra.phpstan.includes: ["extension.neon"]`, `phpstan/phpstan: ^2` in `require`, `classmap` in `autoload-dev` for `tests/Rules/stubs/`.
- `extension.neon` — `parametersSchema` + `parameters` + `services` blocks registering rules.
- Tests use PHPUnit (canonical for phpstan extensions).

Secondary reference (Laravel-aware variant): [`hihaho/phpstan-rules`](https://github.com/hihaho/phpstan-rules) — adds `illuminate/support` in `require` + `larastan/larastan` in `require-dev`.

## `rector-extension`

**Reference**: [`SanderMuller/laravel-fluent-validation-rector`](https://github.com/SanderMuller/laravel-fluent-validation-rector)

What to look at:

- `composer.json` — `type: rector-extension`, `extra.rector.includes: ["config/config.php"]`, `rector/rector: ^2` in `require` (NOT in `require-dev` — see §5.1.1), `symplify/rule-doc-generator-contracts` in `require`, `config.allow-plugins.rector/extension-installer: true`.
- `config/config.php` — Rector service registration.

Secondary reference (Laravel-aware variant): [`hihaho/rector-rules`](https://github.com/hihaho/rector-rules) — adds `driftingly/rector-laravel`.

## `laravel-project`

**Reference**: [`hihaho/pipedrive-migration-tool`](https://github.com/hihaho/pipedrive-migration-tool) (clean recent project) and [`hihaho/hihaho`](https://github.com/hihaho/hihaho) (mature long-running project).

What to look at:

- `composer.json` — `type: project`, hihaho/phpstan-rules + hihaho/rector-rules in `require-dev`, laravel/boost direct (not via testbench), laravel/pail + laravel/pao + laravel/tinker, phpunit/phpunit explicit, `dev` script (concurrently).
- `boost.json` — laravel/boost configuration.
- `.gitignore` — extras for `/public/build`, `/public/hot`, `/public/storage`, `/storage/pail`, `_ide_helper*`.
- `phpstan.neon.dist` — `paths: [app, routes, config, database, tests]` (NOT `src tests` like packages).

## Drift detection (Phase 7 CI)

A weekly GitHub Actions workflow fetches each reference repo's relevant files via `gh api` and diffs them against the corresponding stub in `stubs/`. Warns and opens an issue if drift exceeds a threshold.
