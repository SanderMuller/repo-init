# Rector config

The `rector.php` shape per category. This file and `stubs/*/rector.php` must
agree, and both must agree with the `phases/*-<category>.md` files. A
disagreement between them is a defect to trace and fix, not a precedence
question — either side can be the stale one.

## Always (every category)

```php
<?php declare(strict_types=1);

use Rector\Caching\ValueObject\Storage\FileCacheStorage;
use Rector\Config\RectorConfig;

// Rector rejects a containerCacheDirectory that does not exist yet.
is_dir(__DIR__ . '/.cache/phpstan') || mkdir(__DIR__ . '/.cache/phpstan', recursive: true);

return RectorConfig::configure()
    ->withCache(
        cacheDirectory: './.cache/rector',
        cacheClass: FileCacheStorage::class,
        // Rector boots a PHPStan container and writes the same reflection cache
        // entries PHPStan does, so it shares PHPStan's tmpDir: one copy, not two.
        containerCacheDirectory: './.cache/phpstan',
    )
    ->withPreparedSets(
        deadCode: true,
        codeQuality: true,
        codingStyle: true,
        typeDeclarations: true,
        typeDeclarationDocblocks: true,
        privatization: true,
        carbon: true,
        rectorPreset: true,
        phpunitCodeQuality: true,
    )
    ->withAttributesSets()
    ->withImportNames()
    ->withFluentCallNewLine()
    ->withParallel(300, 15, 15)
    ->withMemoryLimit('3G')
    ->withPhpSets(php84: true) // php85 for laravel-project, or per --php=
```

`withPreparedSets()` must NOT pass `instanceOf`, `if` or `earlyReturn`. Rector
2.6 marks all three `@deprecated`: the instanceof and early-return rules moved
into `codeQuality`, and the `if` rules moved into `codeQuality` / `codingStyle`
or were dropped. `codeQuality: true` already covers them. Verified against
`rector/rector` 2.6.7, `src/Configuration/RectorConfigBuilder.php`.

## `withComposerBased()` — conditional, never unconditional

`withComposerBased()` is the only builder path that pushes
`PHPUnitSetList::COMPOSER_BASED` and `LaravelSetList::COMPOSER_BASED` into the
set list — traced in `RectorConfigBuilder::withComposerBased()`. The older
`withSetProviders()` is `@deprecated` in favour of it. Nothing else registers a
composer-based set.

Each flag has its own condition. A config that meets no condition omits the call
entirely — an argument-less `withComposerBased()` registers nothing.

| Flag | Condition |
|---|---|
| `phpunit: true` | `--test-framework=phpunit` ONLY |
| `laravel: true` | category `laravel-project` ONLY |

`phpunit: true` registers the PHPUnit upgrade set, whose rules rewrite
`PHPUnit\Framework\TestCase` subclasses. A Pest suite has no such classes, so
the set is noise there. This matches the reference apps: `hihaho` is PHPUnit and
passes the flag, `mijntp` is Pest and does not.

`laravel: true` derives Laravel upgrade rules from the installed Laravel
version. An app pins one version, so that is safe. A package supports a Laravel
range, and rules derived from the dev-installed version can rewrite code that
must still run on the package's lower bound.

Each stub ships the flags its own default test framework earns. Four stubs are
PHPUnit-flavoured — `laravel-project`, `laravel-package-spatie`,
`phpstan-extension` (PHPStan's `RuleTestCase` is PHPUnit-based) and
`rector-extension`; the rest ship Pest:

| Stub | Call |
|---|---|
| `laravel-project` | `->withComposerBased(phpunit: true, laravel: true)` |
| `laravel-package-spatie`, `phpstan-extension`, `rector-extension` | `->withComposerBased(phpunit: true)` |
| every other stub | no call |

The bootstrap "compose test-framework variant" step flips the `phpunit:` flag
when the user picks the other framework: it adds the flag on a PHPUnit target
and removes it on a Pest target. Removing the last flag removes the whole call.

`containerCacheDirectory` must be set explicitly, to `./.cache/phpstan` — the
`tmpDir` of the canonical `phpstan.neon.dist`. Rector's default puts the
container cache in the system temp directory, where
`.github/workflows/rector-check.yml` — which caches
`.cache/phpstan/cache/PHPStan` — cannot see it. Rector boots a PHPStan container, so it writes the same reflection and
PHPDoc cache entries PHPStan does. `hihaho/rector.php` measured 1118 of the 1131
entries Rector writes (99%) as entries PHPStan also wants; a separate
`.cache/rectorContainer/` keeps a second copy of them. The cache keys carry the
dependency and PHP versions, so a mismatch misses instead of returning stale
data, and the two tools can write there at the same time.
Rector also fails when that directory does not exist, so each stub creates it
before `RectorConfig::configure()`. Without that line, a local run on a fresh
clone fails. CI does not hit this, because `rector-check.yml` creates the directory.

## Per-category `withPaths` and `withSets`

| Category | `withPaths` | Extra `withSets` |
|---|---|---|
| `laravel-project` | `app, routes, config, database, tests` | the five Laravel sets below + Pest |
| `laravel-package` | `src, tests, workbench` | the five Laravel sets below + Pest |
| `laravel-package-spatie` | `src, tests, workbench` | the five Laravel sets below + Pest |
| `filament-plugin` | `src, tests, workbench` | the five Laravel sets below + Pest |
| `nova-tool` | `src, tests, workbench` | the five Laravel sets below + Pest |
| `php-package` | `src, tests` | Pest only |
| `composer-plugin` | `src, tests` | Pest only |
| `phpstan-extension` | `src, tests` | Pest only |
| `rector-extension` | `src, tests, config` | Pest only |

The five Laravel sets, in stub order:

```php
LaravelSetList::LARAVEL_CODE_QUALITY,
LaravelSetList::LARAVEL_ARRAYACCESS_TO_METHOD_CALL,
LaravelSetList::LARAVEL_COLLECTION,
LaravelSetList::LARAVEL_CONTAINER_STRING_TO_FULLY_QUALIFIED_NAME,
LaravelSetList::LARAVEL_FACADE_ALIASES_TO_FULL_NAMES,
```

`LARAVEL_COLLECTION` is present in both `hihaho/rector.php` and
`mijntp/rector.php`.

No stub ships a version-pinned `LaravelSetList::LARAVEL_{XXX}` set.

The `rector-extension` category includes `config/` because the extension's own
`config/config.php` is PHP that benefits from refactoring rules.

## Pest set

With `--test-framework=pest`, `pestphp/pest-plugin-rector` supplies one set:

```php
use Pest\Rector\Set\PestSetList;

->withSets(class_exists(PestSetList::class) ? [
    PestSetList::CODING_STYLE,
] : [])
```

A repo still importing `RectorPest\Set\PestSetList` from `mrpunyapal/rector-pest`
is NON-CANONICAL — swap the import and the set names in the same pass that drops
the package.

Confirmed 2026-09-21 against the installed plugin source
(`vendor/pestphp/pest-plugin-rector/src/Set/PestSetList.php`): `CODING_STYLE` is
the class's only constant. The `PEST_CODE_QUALITY` / `PEST_CHAIN` / `PEST_LARAVEL`
constants belong to `mrpunyapal/rector-pest` and have no first-party equivalent;
`mijntp` still runs that package and is NOT canonical on this point.

## `withSkip` — stub defaults

Every stub ships this list. These are repo-init's own defaults, chosen as rules
that are noisy or that fight the house style. Most are NOT drawn from the
reference apps. The exception is `TernaryToNullsafeCoalesceRector`, which
`hihaho/rector.php` skips: it is in the `php80` set, so `withPhpSets()` runs it
in every category, and its output fails the canonical PHPStan config. Reproduced
with Rector 2.8.1 and PHPStan 2.3.3: `$user !== null ? $user->name : 'guest'`
on a `?self` with a non-null `string $name` becomes `$user?->name ?? 'guest'`,
which PHPStan reports as `nullsafe.neverNull`.

`ExplicitNullableObjectInstanceRector` is the second exception; both reference
apps skip it. It is in `codeQuality` from Rector 2.8.0, and every stub runs that
set together with `deadCode`. Reproduced on Rector 2.8.1 with the full
`hihaho/rector.php` minus this one skip: guards on a nullable enum parameter turn
into `instanceof` checks, then `RemoveAlwaysTrueIfConditionRector` and
`RemoveUnreachableStatementRector` empty a private method to `return;`. A queued
job dispatch and a failure notification disappeared that way. All cases found
involve a nullable enum. A single-rule fixture and a run with only the `deadCode`
set did not reproduce it, so the chain needs more of a full config.

```php
->withSkip([
    AddArrowFunctionReturnTypeRector::class,
    InlineArrayReturnAssignRector::class,
    PrivatizeFinalClassMethodRector::class,
    RemoveUselessParamTagRector::class,
    RemoveUselessReturnTagRector::class,
    // Its `$x?->prop ?? $d` output fails PHPStan's nullsafe.neverNull.
    TernaryToNullsafeCoalesceRector::class,
    // On a nullable enum, its rewrite lets the deadCode set delete reachable code.
    ExplicitNullableObjectInstanceRector::class,
])
```

The phase file lets the agent ask the user whether to keep this list as-is or
trim it.

The list holds no `@deprecated` rule. Rector 2.8.0 removed every deprecated rule
from the prepared sets and levels, so a skip for one is a no-op. Traced in
`rector-src` 2.8.0 (`src/Config/Level/*.php`, `config/set/*.php`) and in the
installed 2.8.1. `EncapsedStringsToSprintfRector` and `ExplicitBoolCompareRector`
left the list for that reason, and the `rector/rector` floor is `^2.8`.
`NullToStrictStringFuncCallArgRector` left too: it is not deprecated, but
rector-src #8234 removed it from the `php81` set before 2.6.0, so no set runs
it. Rector 2.8.1 warns "This skipped rule is never registered" for it.

## `withSkip` — laravel-project reference list

Verified 2026-10-28 (both apps on `rector/rector` 2.8.1) as the blanket
(non-path-scoped) skips present in BOTH `hihaho/rector.php` and
`mijntp/rector.php`, minus the two exceptions below. This is what a mature Laravel app on
this toolchain converges on. Offer it to a `laravel-project` target on top of the
stub defaults; it does not apply to package categories.

```php
AddMockConsoleOutputFalseToConsoleTestsRector::class,
AddOverrideAttributeToOverriddenPropertiesRector::class,
AppToResolveRector::class,
ApplyDefaultInsteadOfNullCoalesceRector::class,
ArgumentAdderRector::class,
ArrayExplicitBoolCompareRector::class,
AssertSeeToAssertSeeHtmlRector::class,
CarbonToDateFacadeRector::class,
ClosureToArrowFunctionRector::class,
CollectedByPropertyToCollectedByAttributeRector::class,
ContainerBindConcreteWithClosureOnlyRector::class,
DispatchNonShouldQueueToDispatchSyncRector::class,
EnvVariableToEnvHelperRector::class,
InlineIsAInstanceOfRector::class,
LocallyCalledStaticMethodToNonStaticRector::class,
MigrateToSimplifiedAttributeRector::class,
PreferPHPUnitThisCallRector::class,
RedirectRouteToToRouteHelperRector::class,
RenameClassRector::class,
ReplaceServiceContainerCallArgRector::class,
RestoreDefaultNullToNullableTypePropertyRector::class,
ScopeNamedClassMethodToScopeAttributedClassMethodRector::class,
SimplifyIfReturnBoolRector::class,
```

Both apps dropped seven skips for rules that Rector 2.8 deprecates and no
longer runs: `BinaryOpNullableToInstanceofRector`,
`CompleteDynamicPropertiesRector`, `DeclareStrictTypesRector`,
`FlipTypeControlToUseExclusiveTypeRector`, `ObjectExplicitBoolCompareRector`,
`PostIncDecToPreIncDecRector`, `RemoveDuplicatedReturnSelfDocblockRector`. Pint's
`declare_strict_types` still adds `declare(strict_types=1)`.

`ExplicitNullableObjectInstanceRector` is skipped in both apps but is NOT in
the list: it is in the stub defaults, so every category skips it.

`RemoveDefaultAuthorizeTrueFromFormRequestRector` is skipped in both apps but is
NOT in the list. Up to `driftingly/rector-laravel` 2.7.2 it read only the last
statement, so it removed an `authorize()` that throws on a denied Gate check.
2.7.3 (rector-laravel #598) only removes a method whose single statement is
`return true`, which matches the `FormRequest` default. A fixture with
`Gate::inspect()` and a `throw` stays unchanged on 2.7.3. The rule is in
`LARAVEL_CODE_QUALITY`, so every Laravel stub floors `driftingly/rector-laravel`
at `^2.7.3`.

Five more rules are skipped in both apps but scoped to project-specific paths, so
they carry over as a prompt rather than a default:
`ArrayToFirstClassCallableRector`, `ReadOnlyClassRector`, `ReadOnlyPropertyRector`,
`RemoveNullPropertyInitializationRector`, `RequestVariablesToRequestFacadeRector`.

## `--with-hihaho-rules` wiring (laravel-project)

`hihaho/rector-rules` does NOT self-register its rules. Its `composer.json` sets
`type: rector-extension` and `extra.rector.includes: ["config/config.php"]`, but
that file is an empty closure by design, and the mechanism needs
`rector/extension-installer`, which neither reference app installs. The consuming
`rector.php` must wire the rules itself.

Minimum wiring — the set list, whose class is
`Hihaho\RectorRules\Set\HihahoSetList` (note `Set`, singular):

```php
use Hihaho\RectorRules\Set\HihahoSetList;

->withSets([
    HihahoSetList::ALL,
])
```

`HihahoSetList::ALL` imports the code-quality, eloquent, imports, migrations,
naming, routing and testing sets. Three further rules ship in the package but
belong to no set, so `ALL` does not reach them. Both reference apps configure
them by hand:

- `MiddlewareStringToClassRector`
- `NamedArgumentFromManifestRector` (needs a PHPStan-produced manifest; see below)
- `TestFieldStringToConstantRector`

`ALL` also registers `FirstPartyFlagArgumentToNamedRector`,
`NativeFunctionFlagArgumentToNamedRector` and `RemoveDefaultValuedArgumentRector`
unconfigured; both apps re-declare them through `withConfiguredRule()` to supply
first-party namespaces and call exclusions.

NOT YET CANONICAL: `NamedArgumentFromManifestRector` needs a PHPStan producer
(`namedArgumentManifest` in the PHPStan config) run before Rector, plus a
`ManifestCacheMetaExtension` binding that the fluent builder cannot express. The
two reference apps implement this incompatibly and `hihaho` omits the cache
extension. Do not scaffold it until that is settled.

## PHP set name derivation

`__PHP_VERSION__` (e.g. `^8.4`) → `php84` (the rector set name). The agent reads
`--php=` and writes `withPhpSets(php84: true)` accordingly.
