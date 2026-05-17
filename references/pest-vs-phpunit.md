# Pest vs PHPUnit

`--test-framework` decides which test runner the scaffold uses.

## Default per vendor

| Vendor / category | Default | Why |
|---|---|---|
| `sandermuller/*` packages | `pest` | All canonical sander packages use Pest (queue-insights, fluent-validation, solana-pubkey, socialite-solana, package-boost, stopwatch). |
| `hihaho/*` L-packages | `phpunit` | hihaho/laravel-js-store + others use PHPUnit. |
| `hihaho/*` L-projects | `phpunit` | hihaho main app + pipedrive-migration-tool use PHPUnit. |
| `phpstan-extension` (any vendor) | `phpunit` | Canonical for phpstan rule testing — PHPStan's own `RuleTestCase` is PHPUnit-based. Pest can wrap it but it's awkward. |

User can override at bootstrap time via `--test-framework=pest|phpunit`.

## What the choice affects

### Composer deps

- `pest`: `pestphp/pest`, `pestphp/pest-plugin-arch`, `mrpunyapal/rector-pest`. Laravel categories also add `pestphp/pest-plugin-laravel`.
- `phpunit`: `phpunit/phpunit`.

### Test stub files

- `pest`: `tests/Pest.php` (Pest's bootstrap file with `pest()->extend(...)` for assertions).
- `phpunit`: `phpunit.xml` (PHPUnit config with `<testsuites>`, `<source>`, `<env>`).

### Composer scripts

- `pest`: `"test": "vendor/bin/pest"`, `"test-coverage": "vendor/bin/pest --coverage"`.
- `phpunit`: `"test": "vendor/bin/phpunit"`, `"test-coverage": "vendor/bin/phpunit --coverage-html=coverage"`.

### Rector sets

- `pest`: include `PestSetList::PEST_CODE_QUALITY`, `PEST_CHAIN`, and (for Laravel categories) `PEST_LARAVEL`.
- `phpunit`: include `LevelSetList::UP_TO_PHPUNIT_*` if migrating; otherwise no PHPUnit-specific sets.

### `config.allow-plugins`

- `pest`: `"pestphp/pest-plugin": true` required.
- `phpunit`: no plugin needed.

## Migrating an existing repo

Audit phase asks: "Detected `phpunit/phpunit` in require-dev. Switch to Pest, or keep PHPUnit?" Defaults to "keep" — switching frameworks rewrites every test file, which is out of scope for repo-init.

## Phpstan-extension exception

For `phpstan-extension`, `test-framework` is forced to `phpunit` even if the vendor default would say Pest. The user can override but the phase file warns: PHPStan's `RuleTestCase` is PHPUnit-based; wrapping in Pest works but adds friction. Existing repos with Pest for a phpstan-extension are tolerated by the audit (no `NON-CANONICAL` flag).
