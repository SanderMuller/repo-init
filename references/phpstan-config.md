# PHPStan config

The `phpstan.neon.dist` shape per category. Bootstrap writes this file; audit checks for it; upgrade treats it as `notify-only` (user owns it after bootstrap).

## Always (every category)

```neon
includes:
    - phpstan-baseline.neon
    - phar://phpstan.phar/conf/bleedingEdge.neon
    - vendor/spaze/phpstan-disallowed-calls/disallowed-dangerous-calls.neon
    - vendor/spaze/phpstan-disallowed-calls/disallowed-execution-calls.neon
    - vendor/spaze/phpstan-disallowed-calls/disallowed-insecure-calls.neon

parameters:
    tmpDir: .cache/phpstan
    level: max
    strictRules:
        allRules: true
    editorUrl: 'phpstorm://open?file=%%file%%&line=%%line%%'

    type_coverage:
        return: 100
        param: 100
        property: 100
        constant: 0
        declare: 100

    type_perfect:
        null_over_false: true
        narrow_return: true

    cognitive_complexity:
        class: 80
        function: 20

    treatPhpDocTypesAsCertain: false

    ignoreErrors:
        -
            identifier: trait.unused
            reportUnmatched: false
```

## Per-category overrides

| Category | `paths:` | Extra `includes:` |
|---|---|---|
| `laravel-project` | `[app, routes, config, database, tests]` | `vendor/hihaho/phpstan-rules/extension.neon` when `--with-hihaho-rules` |
| `laravel-package` | `[src, tests, workbench]` | (Larastan auto-included via `phpstan/extension-installer`) |
| `php-package` | `[src, tests]` | (no Laravel-specific includes) |
| `phpstan-extension` | `[src, tests]` | the package's own `extension.neon` (already in `extra.phpstan.includes` of composer.json) |
| `rector-extension` | `[src, tests]` | (none) |

## `larastan` vs `phpstan/phpstan` exclusivity

`larastan/larastan` requires `phpstan/phpstan` transitively. Categories use exactly one of them:

- Laravel-aware (laravel-project, laravel-package, Laravel-aware phpstan-extension) → `larastan/larastan` only.
- Framework-agnostic (php-package, framework-agnostic phpstan-extension, rector-extension) → `phpstan/phpstan` only.

Phase files spell this out — never `composer require` both in the same call.

## Why these parameters

- `level: max` — strictest type-checking.
- `bleedingEdge` — opt into upcoming-default behaviour.
- `strictRules.allRules: true` — enables all strict-rules extension checks.
- `type_coverage` at 100% on return/param/property/declare — enforces typed-everywhere. `constant: 0` because constants frequently lack explicit types in older code; revisit per repo.
- `type_perfect` — narrower return-type inference + nudges toward `null` over `false` for missing values.
- `cognitive_complexity` — defaults are loose (`class: 80, function: 20`); tighten per repo as the codebase tolerates.
- `spaze/phpstan-disallowed-calls` includes — bans debug helpers, exec-family functions, weak hash functions etc. by default. Phase file calls out per-file exceptions.

## What `phpstan.neon.dist` doesn't include

- `paths:` — varies per category, see table above. Bootstrap fills the right one.
- `services:` — only for `phpstan-extension` category; the package's own `extension.neon` (linked via `extra.phpstan.includes`) holds those.
- `parametersSchema:` — same.

## Baseline

`phpstan-baseline.neon` starts empty. The bootstrap phase doesn't pre-populate it. As the user adds code, they run `vendor/bin/phpstan analyse --generate-baseline` themselves.
