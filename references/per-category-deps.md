# Per-category deps

What each category adds on top of the shared list (`shared-dev-deps.md`). Split into **MANDATORY** (audit flags MISSING if absent) and **OPTIONAL/CONDITIONAL** (audit flags only if user confirmed opt-in at audit-start prompt).

**Hard rule: no package appears in both `require` AND `require-dev` in the same row.** Per-category exclusions (`shared-dev-deps.md`) drop conflicting packages from the shared install for that category.

## MANDATORY (per category)

| Category | Adds to `require-dev` | Adds to `require` |
|---|---|---|
| `laravel-project` | `larastan/larastan`, `laravel/boost`, `laravel/pail`, `laravel/tinker`, `driftingly/rector-laravel` | (the `laravel new` baseline) |
| `laravel-package` | `larastan/larastan`, `driftingly/rector-laravel` | `illuminate/contracts`, `illuminate/support` at `__LARAVEL_VERSIONS__` |
| `php-package` | `phpstan/phpstan`, `stolt/lean-package-validator` | (no `illuminate/*`) |
| `phpstan-extension` | (none beyond shared, minus `phpstan/phpstan` per shared exclusion) | `phpstan/phpstan: ^2` |
| `rector-extension` | `symplify/rule-doc-generator-contracts` (rule doc generation contract) | `rector/rector: ^2` |

`laravel-package` `require` is intentionally minimal — `illuminate/contracts` + `illuminate/support`. Phase file tells the agent to extend per feature (add `illuminate/console`, `illuminate/queue`, `illuminate/redis`, etc. as the package uses them).

## OPTIONAL / CONDITIONAL (only flagged when opt-in confirmed)

| Category | Opt-in flag / sub-flag | Adds to `require-dev` | Adds to `require` |
|---|---|---|---|
| `laravel-project` | `--with-hihaho-rules` (default `y` for vendor=hihaho) | `hihaho/phpstan-rules`, `hihaho/rector-rules`, `symplify/phpstan-rules` | — |
| `laravel-project` | `--with-security-advisories` (default `N`) | `roave/security-advisories: dev-latest` | — |
| `laravel-package` | suggest (not mandatory) | `livewire/livewire` (suggested only — not auto-installed, not audited) | — |
| `laravel-package` | sub-flag `hihaho-package-tools-flavoured` (or `--variant=spatie`) | — | `spatie/laravel-package-tools` |
| `phpstan-extension` | Laravel-aware (has `illuminate/*` in `require`) | `larastan/larastan` (replaces shared `phpstan/phpstan`) | `illuminate/support` |
| `rector-extension` | Laravel-aware (`--with-laravel-sets`) | — | `driftingly/rector-laravel` |

## Opt-in inference (audit + upgrade)

Before walking deps, the audit phase confirms opt-ins. Where possible, infer the default from existing `composer.json` content:

- `--with-hihaho-rules` → `y` if vendor is `hihaho` OR `hihaho/phpstan-rules` already in `require-dev`.
- `--with-security-advisories` → `y` if `roave/security-advisories` already in `require-dev`.
- Laravel-aware phpstan-extension → `y` if `illuminate/*` already in `require`.
- Laravel-aware rector-extension → `y` if `driftingly/rector-laravel` already in `require` OR `require-dev`.
- Spatie-flavoured laravel-package → `y` if `spatie/laravel-package-tools` already in `require`.

For bootstrap, opt-ins come from user input directly (see SKILL.md "Knobs to collect").

## Notes on specific rows

### `phpstan-extension` Laravel-aware

When this opt-in fires:

- `larastan/larastan` REPLACES the bare `phpstan/phpstan` that would otherwise be in `require-dev` (per `larastan` vs `phpstan/phpstan` exclusivity — see `phpstan-config.md`).
- The `require` `phpstan/phpstan: ^2` stays (so the extension's own `composer.json` keeps declaring its phpstan dependency cleanly for consumers).
- The agent's `composer require --dev` call lists `larastan/larastan` but NOT `phpstan/phpstan`. Composer will install both (larastan transitively pulls phpstan), but the lockfile shows only larastan as a direct dep.

### `rector-extension` Laravel-aware

When this opt-in fires:

- `driftingly/rector-laravel` is added to `require` (not `require-dev`) so the extension can use the Laravel rector sets in its own `config/config.php`.

### `--with-hihaho-rules`

Adds three packages to `require-dev`. `symplify/phpstan-rules` is bundled here because hihaho/phpstan-rules has it as a peer dep in practice (see `vendor/hihaho/phpstan-rules/extension.neon`).

### `laravel-package` runtime range

`illuminate/*` constraint defaults to `^11.0||^12.0||^13.0` for new packages. Phase file asks the user if they want to restrict (e.g. `^13.0` only). Existing packages keep whatever they had — audit doesn't second-guess the range.
