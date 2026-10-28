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

    # symplify/phpstan-rules turns these rule sets on by default.
    symplify:
        naming: false
        complexity: false
        configurable: false
        static: false
        modern: false
        symfony: false
        symfonyConfig: false
        doctrine: false
        collections: false
        phpunit: false

    level: max
    strictRules:
        allRules: true
    editorUrl: 'phpstorm://open?file=%%file%%&line=%%line%%'

    type_coverage:
        return: 100
        param: 100
        property: 100
        constant: 100

    type_perfect:
        null_over_false: true
        narrow_return: true
        narrow_param: true

    cognitive_complexity:
        class: 80
        function: 20

    # Off at every level, and phpstan-strict-rules does not set them.
    checkTooWideReturnTypesInProtectedAndPublicMethods: true
    checkTooWideParameterOutInProtectedAndPublicMethods: true
    checkTooWideThrowTypesInProtectedAndPublicMethods: true
    reportAlwaysTrueInLastCondition: true
    reportAnyTypeWideningInVarTag: true

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

From 14.17.0, `symplify/phpstan-rules` loads all its rule sets through
`phpstan/extension-installer`: naming, complexity, configurable, static,
symfony, symfonyConfig, doctrine and phpunit are on by default, switched by
`parameters.symplify.*`. Traced in the installed package, 14.17.0
(`config/phpstan-extensions.neon`). With the sets on, a plain `abstract class
Base` already fails (`symplify.explicitAbstractPrefixName`).

14.19.0 adds two more default-on sets: `modern` (`ForbiddenTraitRule`,
`ForbiddenExtendOfNonAbstractClassRule`, `NoReferenceRule`, `NoDynamicNameRule`,
`ForeachCeptionRule`) and `collections` (Doctrine collection docblock rules).
`ForbiddenTraitRule` reports every trait declaration. Traced in 14.19.0 and
14.19.3 (`config/modern-rules.neon`, `config/collection-rules.neon`).

So every canonical `phpstan.neon.dist` sets all ten to `false`, and the
`rules:` block is the whole of what repo-init enables. Older versions do not
know these keys: the 14.15.3 schema has only `mocks`, `ctor` and the three
return-type switches, and 14.17/14.18 do not know `modern` or `collections`,
so PHPStan rejects the config. The floor is therefore `^14.19` (see
`shared-dev-deps.md` "Symplify formatter dep"). 14.19 requires
`phpstan/phpstan: ^2.3`, so it also sets the effective PHPStan floor.

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

`laravel-project` also sets `checkConfigTypes: true`. Larastan then reads
`config()` types from `config/*.php` instead of `mixed`. `configDirectories:
[config]` is not needed: with no directories set, larastan falls back to
`config_path()` (`ConfigParser::getConfigPaths()`, traced in 3.10.0 and
3.13.1). `configDirectories` without `checkConfigTypes` does nothing. In
`hihaho/phpstan.neon` the check found `env()` integers and booleans that arrive
as strings in typed parameters; the fix is a cast in the config file, for
example `(int) (env('X') ?: 60)`. The type is the literal value in the file, so a
`config()->set()` in a test does not change it: keep a guard on a value that
tests override, even when PHPStan calls it unnecessary. Package categories do not set it: how
larastan reads a Testbench package's config is not traced.

## `larastan` vs `phpstan/phpstan` exclusivity

`larastan/larastan` requires `phpstan/phpstan` transitively. Categories use exactly one of them:

- Laravel-aware (laravel-project, laravel-package, Laravel-aware phpstan-extension) → `larastan/larastan` only.
- Framework-agnostic (php-package, framework-agnostic phpstan-extension, rector-extension) → `phpstan/phpstan` only.

Phase files spell this out — never `composer require` both in the same call.

## Why these parameters

- `level: max` — strictest type-checking.
- `bleedingEdge` — opt into upcoming-default behaviour.
- `strictRules.allRules: true` — enables all strict-rules extension checks.
- `type_coverage` at 100% everywhere, constants included. Both reference apps run `constant: 100`; the earlier `constant: 0` in this canon was looser than either of them. No `declare` key: type-coverage 2.5.1 deprecates it with no effect, and Pint's `declare_strict_types` rule enforces `declare(strict_types=1)` instead.
- `type_perfect` — `null_over_false`, `narrow_return` and `narrow_param`. `no_mixed` stays OFF: it rejects every `mixed`, including the ones a framework or PSR interface forces on an implementer, which is the workability line. Both reference apps run all three narrowing flags off, but they are large legacy codebases; a repo starting clean holds the stricter line.
- `checkTooWideReturnTypesInProtectedAndPublicMethods`, `checkTooWideParameterOutInProtectedAndPublicMethods`, `checkTooWideThrowTypesInProtectedAndPublicMethods`, `reportAlwaysTrueInLastCondition`, `reportAnyTypeWideningInVarTag` — PHPStan sets all five `false` in `conf/config.neon`, no level turns them on, and `phpstan-strict-rules` does not set them (traced in PHPStan 2.3.3 and strict-rules `rules.neon`). All five are in the schema from PHPStan 2.2.0. `hihaho/phpstan.neon` turned them on in Oct 2026; the too-wide-return check found 0 hits there, so it is cheap to start with. `reportMaybesInPropertyPhpDocTypes` is not listed: `phpstan-strict-rules` already sets it `true`.
- `type_perfect.narrow_return` — PHPStan 2.3.2 crashes in this rule on `return once(fn ...)`. The fix (phpstan/phpstan-src#6852) shipped in 2.3.3. If a repo resolves a version below 2.3.3, run `composer update phpstan/phpstan`; do not turn the flag off.
- `cognitive_complexity` — defaults are loose (`class: 80, function: 20`); tighten per repo as the codebase tolerates.
- `spaze/phpstan-disallowed-calls` includes — bans debug helpers, exec-family functions, weak hash functions etc. by default. Phase file calls out per-file exceptions.

## What `phpstan.neon.dist` doesn't include

- `paths:` — varies per category, see table above. Bootstrap fills the right one.
- `services:` — only for `phpstan-extension` category; the package's own `extension.neon` (linked via `extra.phpstan.includes`) holds those.
- `parametersSchema:` — same.

## Container cache — no prune script

PHPStan compiles a DI container into `.cache/phpstan/cache/nette.configurator/`
for each distinct config and environment, and Rector adds its own there (see
`rector-config.md`). The canon ships no prune script, because PHPStan cleans the
directory itself. From 2.0.0, `phpstan analyse` writes `container.journal` and
deletes each container that no run used in the last 7 days. From 2.3.3, a
container that another process has not journaled yet is deleted only when its
file is 7 days old (phpstan-src #6797). Rector does not journal, so PHPStan
deletes a Rector container when its file is 7 days old, and Rector compiles a
new one. Traced in `src/DependencyInjection/Configurator.php` (2.0.0 and 2.3.3)
and `src/Command/AnalyseCommand.php`.

2.3.3 also drops the restart ini path, which has a random name for each run,
from the container key (phpstan-src `a51e744132`). Each config change still
compiles a new container, so a repo keeps the containers of one week.

## Probed and rejected

`hihaho/phpstan.neon` measured these in Oct 2026 and left them off. Do not add
them to the canon, and do not report their absence as drift:

- `checkMissingCallableSignature` — about 174 hits, mostly middleware `$next` and factory closures.
- `checkUninitializedProperties` — Livewire properties that the framework fills; `additionalConstructors` did not help.
- `checkBenevolentUnionTypes` — about 1,200 hits.
- `featureToggles.reportNestedTooWideType` — mostly inherited signatures.
- `reportPossiblyNonexistentConstantArrayOffset` — noise.
- `type_perfect.no_mixed` — about 2,200 hits; see "Why these parameters".
- `checkMissingOverrideMethodAttribute` (`#[Override]` everywhere) — the user rejected it.

The counts come from one large application. A small new repo can hit fewer, but
the decision is the user's, not drift.

## Baseline

`phpstan-baseline.neon` starts empty. The bootstrap phase doesn't pre-populate it. As the user adds code, they run `vendor/bin/phpstan analyse --generate-baseline` themselves.

When a repo needs a baseline (for example after a level raise), these practices
held up in `hihaho/phpstan.neon`:

- Split baselines by cause, one file per cause, each `includes:`d with a one-line comment. hihaho keeps `phpstan-baseline-level8.neon` for the findings that existed when the level was raised. New code is held to the level, and later rounds burn the file down folder by folder.
- Prefer an `ignoreErrors` entry with an `identifier:` and `path:`/`paths:` plus a one-line why comment over a broad message regex. When a message regex is the only option, scope it to the exact names, so a typo still fails.
- Keep `reportUnmatchedIgnoredErrors` on (the PHPStan default). Ignores then clear themselves when the code is fixed.
- Run `vendor/bin/phpstan clear-result-cache` before the final run. A stale result cache hid an unmatched ignore in hihaho.
