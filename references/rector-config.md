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

return RectorConfig::configure()
    ->withCache(
        cacheDirectory: './.cache/rector',
        cacheClass: FileCacheStorage::class,
        containerCacheDirectory: './.cache/rectorContainer',
    )
    ->withPreparedSets(
        deadCode: true,
        codeQuality: true,
        codingStyle: true,
        typeDeclarations: true,
        typeDeclarationDocblocks: true,
        privatization: true,
        instanceOf: true,
        earlyReturn: true,
        carbon: true,
        rectorPreset: true,
        phpunitCodeQuality: true,
    )
    ->withAttributesSets()
    ->withImportNames()
    ->withFluentCallNewLine()
    ->withParallel(300, 15, 15)
    ->withMemoryLimit('3G')
    ->withPhpSets(php83: true) // or php84/php85 per --php=
```

`containerCacheDirectory` must be set explicitly. Rector's default puts the
container cache in the system temp directory, where
`.github/workflows/rector-check.yml` — which caches `.cache/rectorContainer/` —
cannot see it.

## Per-category `withPaths` and `withSets`

| Category | `withPaths` | Extra `withSets` |
|---|---|---|
| `laravel-project` | `app, routes, config, database, tests` | the four Laravel sets below + Pest |
| `laravel-package` | `src, tests, workbench` | the four Laravel sets below + Pest |
| `laravel-package-spatie` | `src, tests, workbench` | the four Laravel sets below + Pest |
| `filament-plugin` | `src, tests, workbench` | the four Laravel sets below + Pest |
| `nova-tool` | `src, tests, workbench` | the four Laravel sets below + Pest |
| `php-package` | `src, tests` | Pest only |
| `composer-plugin` | `src, tests` | Pest only |
| `phpstan-extension` | `src, tests` | Pest only |
| `rector-extension` | `src, tests, config` | Pest only |

The four Laravel sets, in stub order:

```php
LaravelSetList::LARAVEL_CODE_QUALITY,
LaravelSetList::LARAVEL_ARRAYACCESS_TO_METHOD_CALL,
LaravelSetList::LARAVEL_CONTAINER_STRING_TO_FULLY_QUALIFIED_NAME,
LaravelSetList::LARAVEL_FACADE_ALIASES_TO_FULL_NAMES,
```

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

NEEDS-CONFIRMATION (research item, not a blocker): the phase files treat
`PestSetList::CODING_STYLE` as settled canon, so follow them. But no local
reference repo runs `pestphp/pest-plugin-rector` — `hihaho` is PHPUnit, `mijntp`
is Pest 4 on `mrpunyapal/rector-pest` — so the constant name and its coverage of
the old `PEST_CODE_QUALITY` / `PEST_CHAIN` split are untraced here, and `mijntp`
also runs `PEST_LARAVEL`, which has no mapping. Confirm against the plugin's
source when convenient.

## `withSkip` — stub defaults

Every stub ships this list. These are repo-init's own defaults, chosen as rules
that are noisy or that fight the house style. They are NOT drawn from the
reference apps — none of them appears in `hihaho/rector.php` or
`mijntp/rector.php`.

```php
->withSkip([
    NullToStrictStringFuncCallArgRector::class,
    AddArrowFunctionReturnTypeRector::class,
    EncapsedStringsToSprintfRector::class,
    ExplicitBoolCompareRector::class,
    InlineArrayReturnAssignRector::class,
    PrivatizeFinalClassMethodRector::class,
    RemoveUselessParamTagRector::class,
    RemoveUselessReturnTagRector::class,
])
```

The phase file lets the agent ask the user whether to keep this list as-is or
trim it.

## `withSkip` — laravel-project reference list

Verified 2026-09-07 as the blanket (non-path-scoped) skips present in BOTH
`hihaho/rector.php` and `mijntp/rector.php`. This is what a mature Laravel app on
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
BinaryOpNullableToInstanceofRector::class,
CarbonToDateFacadeRector::class,
ClosureToArrowFunctionRector::class,
CollectedByPropertyToCollectedByAttributeRector::class,
CompleteDynamicPropertiesRector::class,
ContainerBindConcreteWithClosureOnlyRector::class,
DeclareStrictTypesRector::class, // Pint does this
DispatchNonShouldQueueToDispatchSyncRector::class,
EnvVariableToEnvHelperRector::class,
FlipTypeControlToUseExclusiveTypeRector::class,
InlineIsAInstanceOfRector::class,
LocallyCalledStaticMethodToNonStaticRector::class,
MigrateToSimplifiedAttributeRector::class,
ObjectExplicitBoolCompareRector::class,
PostIncDecToPreIncDecRector::class,
PreferPHPUnitThisCallRector::class,
RedirectRouteToToRouteHelperRector::class,
RemoveDuplicatedReturnSelfDocblockRector::class,
RenameClassRector::class,
ReplaceServiceContainerCallArgRector::class,
RestoreDefaultNullToNullableTypePropertyRector::class,
ScopeNamedClassMethodToScopeAttributedClassMethodRector::class,
SimplifyIfReturnBoolRector::class,
```

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

`__PHP_VERSION__` (e.g. `^8.3`) → `php83` (the rector set name). The agent reads
`--php=` and writes `withPhpSets(php83: true)` accordingly.
