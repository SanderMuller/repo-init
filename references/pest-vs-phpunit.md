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

## Pest forces a PHP `^8.4` floor

Pest 5 requires PHP `^8.4` and PHPUnit 13. So `--test-framework=pest` and `--php=8.3` are **incompatible**. The phase resolves the clash before it writes `composer.json`:

- Bootstrap: if the user asks for `pest` with `php=8.3`, ask which one to change. Do not silently scaffold Pest 4.
- Audit: a Pest repo with `require.php: ^8.3` is `NON-CANONICAL` — the fix is the PHP floor bump, not a Pest downgrade.
- Upgrade: raise `require.php` to `^8.4` in the same composer.json pass that raises `pestphp/*` to `^5.0`.

A `^8.4` floor also drops the two abandoned packages a `^8.3` floor carries (`symplify/phpstan-extensions`, `rector/type-perfect`) — see `shared-dev-deps.md`. So every Pest repo takes the PHP ≥ 8.4 dep set, and only PHPUnit repos can still be on the `^8.3` set.

## What the choice affects

### Composer deps

- `pest`: `pestphp/pest: ^5.0`, `pestphp/pest-plugin-arch: ^5.0`, `pestphp/pest-plugin-rector: ^5.0`, `pestphp/pest-plugin-phpstan: ^5.0`, `pestphp/pest-plugin-agent: ^5.0`. Laravel categories also add `pestphp/pest-plugin-laravel: ^5.0`.
- `phpunit`: `phpunit/phpunit`.

`pestphp/pest-plugin-rector` is first-party and replaces `mrpunyapal/rector-pest` — that package targets Pest 4 idioms and is not part of the canonical set any more.

`pestphp/pest-plugin-phpstan` registers itself through `phpstan/extension-installer` (its `extra.phpstan.includes` names `extension.neon`), so `phpstan.neon.dist` needs no include line.

`pestphp/pest-plugin-agent` adds `vendor/bin/pest --agent='<php snippet>'`, which runs a snippet inside the test environment. It is a tool for agents, not for the suite.

### Test stub files

- `pest`: `tests/Pest.php` (Pest's bootstrap file with `pest()->extend(...)` for assertions, plus `pest()->tia()->locally()` for the Tia engine).
- `phpunit`: `phpunit.xml` (PHPUnit config with `<testsuites>`, `<source>`, `<env>`).

### Composer scripts

- `pest`: `"test": "vendor/bin/pest"`, `"test-coverage": "vendor/bin/pest --coverage"`. No `--tia` flag anywhere — `tests/Pest.php` turns Tia on locally, and CI must run the full suite.
- `phpunit`: `"test": "vendor/bin/phpunit"`, `"test-coverage": "vendor/bin/phpunit --coverage-html=coverage"`.

### Rector sets

- `pest`: include `Pest\Rector\Set\PestSetList::CODING_STYLE` — the plugin's only set. It replaces the `PEST_CODE_QUALITY` / `PEST_CHAIN` pair from `mrpunyapal/rector-pest`; the first-party set carries both rule groups.
- `phpunit`: include `LevelSetList::UP_TO_PHPUNIT_*` if migrating; otherwise no PHPUnit-specific sets.

### `config.allow-plugins`

- `pest`: `"pestphp/pest-plugin": true` required.
- `phpunit`: no plugin needed.

## Migrating an existing repo

Audit phase asks: "Detected `phpunit/phpunit` in require-dev. Switch to Pest, or keep PHPUnit?" Defaults to "keep" — switching frameworks rewrites every test file, which is out of scope for repo-init.

A repo already on Pest takes the Pest 4 → 5 path instead. See `version-defaults.md` → "Migrating an existing Pest codebase".

## Tia engine

Every Pest scaffold gets the Tia engine through `tests/Pest.php`:

```php
pest()->tia()->locally();
```

`locally()` enables Tia and switches it off for any run carrying `--ci` — that flag is the mechanism, not CI-environment detection. The stub `run-tests.yml` runs `vendor/bin/pest --ci`, so CI keeps the full suite. Tia records the test-to-file graph on its first run, which needs PCOV or Xdebug, and stores it in `~/.pest/tia/<project-key>/` — outside the repo, so `.gitignore` stays as it is.

Tia needs the repository to have **at least one commit**. A freshly scaffolded repo has none, and `vendor/bin/pest` then aborts with `The feature "Tia mode" requires "git"` instead of running the suite (verified against Pest 5). Run the suite after the initial commit, or pass `--no-tia` for that one run. A remote is not required.

Alternatives the phases do NOT scaffold: `always()` (Tia in CI too), `baselined()` plus a baseline workflow (built for very large suites), and a `--tia` composer script.

### Pest 5 and orchestra/testbench

Pest 5 requires `symfony/process: ^8.1`. `orchestra/testbench` 10 (Laravel 12) pins `symfony/process: ^7.2`, so **Pest 5 and testbench 10 cannot install together** — verified with `composer update --dry-run --prefer-lowest`. This holds for EVERY category that carries `orchestra/testbench`, `php-package` included; the Laravel package categories (`laravel-package`, `filament-plugin`, `nova-tool`) carry the extra matrix rule:

- `require-dev` takes `orchestra/testbench: ^11.0` — not `^10.0||^11.0`.
- `require` keeps `illuminate/*: ^12.0||^13.0`, so Laravel 12 consumers can still install the package. Only the package's own suite is limited to Laravel 13.
- The `run-tests.yml` matrix carries Laravel 13 / testbench 11 cells only. Do not add a Laravel 12 cell — it cannot resolve.
- A package that must test against Laravel 12 has to stay on Pest 4. Record that as a deliberate exception.
- The reverse also holds: a PHPUnit Laravel package that keeps Laravel 12 in `require` needs `orchestra/testbench: ^10.0||^11.0` and Laravel 12 matrix cells. Testbench 11 resolves against Laravel 13 only.

## Phpstan-extension exception

For `phpstan-extension`, `test-framework` is forced to `phpunit` even if the vendor default would say Pest. The user can override but the phase file warns: PHPStan's `RuleTestCase` is PHPUnit-based; wrapping in Pest works but adds friction. Existing repos with Pest for a phpstan-extension are tolerated by the audit (no `NON-CANONICAL` flag).
