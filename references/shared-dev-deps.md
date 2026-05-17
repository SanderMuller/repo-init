# Shared dev deps

Universal `require-dev` list applied to every category (with per-category exclusions listed below).

## Shared list

```
laravel/pao
laravel/pint
phpstan/extension-installer
phpstan/phpstan-strict-rules
phpstan/phpstan-deprecation-rules
phpstan/phpstan-phpunit
rector/rector
rector/type-perfect
spaze/phpstan-disallowed-calls
symplify/phpstan-extensions
tomasvotruba/cognitive-complexity
tomasvotruba/type-coverage
nunomaduro/collision
sandermuller/package-boost
orchestra/testbench
```

Test-framework split (`test-framework=pest|phpunit`):

- **`pest`** adds: `pestphp/pest`, `pestphp/pest-plugin-arch`, `mrpunyapal/rector-pest`. Laravel categories also add `pestphp/pest-plugin-laravel`.
- **`phpunit`** adds: `phpunit/phpunit`.

## Why these

- `laravel/pao` — agent-optimized output for phpunit/pest/pint/phpstan/rector/paratest. Framework-agnostic. Floor `^8.3` (matches our hard floor; see `version-defaults.md`).
- `laravel/pint` — code formatter.
- `phpstan/extension-installer` — auto-includes phpstan extension configs.
- `phpstan/phpstan-strict-rules`, `-deprecation-rules`, `-phpunit` — common rule packs.
- `rector/rector`, `rector/type-perfect` — refactoring + type checking.
- `spaze/phpstan-disallowed-calls` — bans dangerous/execution/insecure calls.
- `symplify/phpstan-extensions` — adds the symplify error formatter (`phpstan-simplified` script).
- `tomasvotruba/cognitive-complexity` — complexity rules.
- `tomasvotruba/type-coverage` — enforces 100% type coverage.
- `nunomaduro/collision` — better error output in CLI.
- `sandermuller/package-boost` — AI tooling propagation (`.ai/skills/` → agent dirs).
- `orchestra/testbench` — required by `package-boost:sync` invocation; used by all package categories.

## Per-category exclusions

When a category puts a package in its `require` (per `per-category-deps.md`), it must be REMOVED from the shared dev-deps install for that category — Composer rejects a package being in both `require` and `require-dev`.

| Category | Drop from shared list | Because added to `require` |
|---|---|---|
| `rector-extension` | `rector/rector` | `rector/rector: ^2` |
| `phpstan-extension` | `phpstan/phpstan` (bare) — the `-strict-rules`/`-deprecation-rules`/`-phpunit`/`-extension-installer` stay | `phpstan/phpstan: ^2` |
| `laravel-package` (sub-flag `hihaho-package-tools-flavoured`) | (none — `spatie/laravel-package-tools` isn't in shared) | `spatie/laravel-package-tools` |
| Others | (none) | — |

Note: the shared list above does not directly include bare `phpstan/phpstan`. It enters transitively via `larastan/larastan` (Laravel categories) or via `phpstan/phpstan-strict-rules`. For non-Laravel categories (`php-package`, `phpstan-extension`), `phpstan/phpstan` is added explicitly via `per-category-deps.md` (in `require-dev` for php-package; in `require` for phpstan-extension).

## Audit honours exclusions

A `rector-extension` repo with `rector/rector` in `require` and absent from `require-dev` is **correct**, not MISSING. Same for `phpstan/phpstan` in `phpstan-extension`.
