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
orchestra/testbench
```

The boost-family umbrella (`sandermuller/package-boost-php` / `package-boost-laravel`) is **NOT** in this shared list — it is assigned per category. See `per-category-deps.md` → "boost-family umbrella".

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
- `orchestra/testbench` — package-category test bootstrap (no longer required for AI sync; boost-core's standalone bin handles that).

The boost-family umbrella is assigned **per category** — see the line above the "Why these" heading and, for the full mapping + the `config.allow-plugins` rule, `per-category-deps.md` → "boost-family umbrella" (its single source of truth).

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

## Audit verification protocol (MANDATORY)

**The agent MUST check each package line-by-line, not skim.** Real audits have missed `laravel/pao` (and similar) because the agent read the section structure and assumed compliance instead of verifying each entry.

Required protocol for the `## MISSING dev deps` section of every audit phase:

1. **Read the target's `composer.json` `require-dev` block once.** Extract package names into a set.
2. **For each bullet in the canonical list** (shared + category-mandatory + test-framework, minus per-category exclusions): explicitly state "PRESENT" or "MISSING" against the extracted set. Don't aggregate ("looks fine") — call each one out by name.
3. **Print a verification line** in the audit report listing every MISSING entry. If none are missing, print "all required dev-deps present (N/N checked)" with the count.
4. **Do NOT trust visual scanning.** If the canonical list has 16 entries and you only mentioned 8 in your response, you skipped half. The check is mechanical: 1 bullet = 1 explicit verdict.

This protocol applies regardless of category. Per-category exclusions (above) trim the canonical list BEFORE this check runs — once trimmed, every remaining bullet gets verified.
