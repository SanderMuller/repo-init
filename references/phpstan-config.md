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

rules:
    - Symplify\PHPStanRules\Rules\StringFileAbsolutePathExistsRule
    - Symplify\PHPStanRules\Rules\Complexity\NoArrayMapWithArrayCallableRule
    - Symplify\PHPStanRules\Rules\Complexity\ForbiddenArrayMethodCallRule
    - Symplify\PHPStanRules\Rules\ForbiddenMultipleClassLikeInOneFileRule
    - Symplify\PHPStanRules\Rules\NoDynamicNameRule
    - Symplify\PHPStanRules\Rules\NoGlobalConstRule
    - Symplify\PHPStanRules\Rules\PreventParentMethodVisibilityOverrideRule
    - Symplify\PHPStanRules\Rules\Enum\RequireUniqueEnumConstantRule
    - Symplify\PHPStanRules\Rules\UppercaseConstantRule
    - Symplify\PHPStanRules\Rules\PHPUnit\PublicStaticDataProviderRule
    - Symplify\PHPStanRules\Rules\Explicit\NoMissingVariableDimFetchRule

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
        constant: 100
        declare: 100

    type_perfect:
        null_over_false: true
        narrow_return: true
        narrow_param: true

    cognitive_complexity:
        class: 80
        function: 20

    treatPhpDocTypesAsCertain: false

    ignoreErrors:
        -
            identifier: trait.unused
            reportUnmatched: false
        # Pest's expectation API is @internal but is the intended public surface.
        -
            identifier: method.internalClass
            paths:
                - tests/*
            reportUnmatched: false
        # NoDynamicNameRule fires on the dynamic dispatch test helpers use.
        # hihaho/phpstan.neon scopes the same identifier out of tests/.
        -
            identifier: symplify.noDynamicName
            paths:
                - tests/*
            reportUnmatched: false
```

## Symplify rules — opt-in, registered by hand

`symplify/phpstan-rules` spreads its rules over opt-in config files. Its
`composer.json` `extra.phpstan.includes` lists only four —
`config/services/services.neon`, `config/ctor-rules.neon`,
`config/mock-rules.neon` and `config/phpstan-extensions.neon` (the error
formatter the dep is carried for). Traced in the installed package, 14.13.1.

So `phpstan/extension-installer` registers NONE of the rules above. A config that
only requires the package gets the formatter and nothing else. The `rules:` block
is the whole of what repo-init enables.

Provenance: the list is `hihaho/phpstan.neon`'s, which a large application
converged on. It is NOT the reference-app intersection — `mijntp` registers no
Symplify rule at all — and it is not the package's own grouping. Changing it is a
policy decision, not drift.

`PublicStaticDataProviderRule` matches PHPUnit data-provider methods only. It is
harmless on a Pest repo (it matches nothing), so every category carries the same
list.

## PHP version — derived, never declared

No stub sets `phpVersion:`. PHPStan 2's `ComposerPhpVersionFactory` reads the
project `composer.json` `require.php` constraint and derives the min/max version
range from it whenever `phpVersion` is null (the default). `require.php` is
therefore the single source of truth, and a declared `phpVersion` can only drift
from it.

Two limits worth knowing, traced in `phpstan.phar/conf/parametersSchema.neon`
(PHPStan 2.2.14): `phpVersion` accepts an int or a `{min, max}` structure, and
its accepted range tops out at `80599` — PHP 8.6 cannot be expressed yet.

Version-specific analysis is therefore a property of the floor, and the floors
are in `version-defaults.md`: `^8.5` for `laravel-project`, `^8.4` for every
package category.

## Per-category overrides

| Category | `paths:` | Extra `includes:` |
|---|---|---|
| `laravel-project` | `[app, routes, config, database, tests]` | `vendor/hihaho/phpstan-rules/extension.neon` when `--with-hihaho-rules` |
| `laravel-package` | `[src, tests, workbench]` | (Larastan auto-included via `phpstan/extension-installer`) |
| `php-package` | `[src, tests]` | (no Laravel-specific includes) |
| `phpstan-extension` | `[src, tests]` | the package's own `extension.neon` (already in `extra.phpstan.includes` of composer.json) |
| `rector-extension` | `[src, tests]` | (none) |

`laravel-project` additionally carries four larastan parameters that exist only
when larastan is installed — `noEnvCallsOutsideOfConfig: true`,
`checkModelProperties: true`, `checkModelAppends: true`,
`checkOctaneCompatibility: false` — plus `excludePaths: [bootstrap/cache, .cache]`.
All six are set the same way in `hihaho/phpstan.neon` and `mijntp/phpstan.neon`.

## `larastan` vs `phpstan/phpstan` exclusivity

`larastan/larastan` requires `phpstan/phpstan` transitively. Categories use exactly one of them:

- Laravel-aware (laravel-project, laravel-package, Laravel-aware phpstan-extension) → `larastan/larastan` only.
- Framework-agnostic (php-package, framework-agnostic phpstan-extension, rector-extension) → `phpstan/phpstan` only.

Phase files spell this out — never `composer require` both in the same call.

## Why these parameters

- `level: max` — strictest type-checking.
- `bleedingEdge` — opt into upcoming-default behaviour.
- `strictRules.allRules: true` — enables all strict-rules extension checks.
- `type_coverage` at 100% everywhere, constants included. Both reference apps run `constant: 100`; the earlier `constant: 0` in this canon was looser than either of them.
- `type_perfect` — `null_over_false`, `narrow_return` and `narrow_param`. `no_mixed` stays OFF: it rejects every `mixed`, including the ones a framework or PSR interface forces on an implementer, which is the workability line. Both reference apps run all three narrowing flags off, but they are large legacy codebases; a repo starting clean holds the stricter line.
- `cognitive_complexity` — defaults are loose (`class: 80, function: 20`); tighten per repo as the codebase tolerates.
- `spaze/phpstan-disallowed-calls` includes — bans debug helpers, exec-family functions, weak hash functions etc. by default. Phase file calls out per-file exceptions.

## What `phpstan.neon.dist` doesn't include

- `paths:` — varies per category, see table above. Bootstrap fills the right one.
- `services:` — only for `phpstan-extension` category; the package's own `extension.neon` (linked via `extra.phpstan.includes`) holds those.
- `parametersSchema:` — same.

## Baseline

`phpstan-baseline.neon` starts empty. The bootstrap phase doesn't pre-populate it. As the user adds code, they run `vendor/bin/phpstan analyse --generate-baseline` themselves.
