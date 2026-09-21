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

`containerCacheDirectory` must be set explicitly. Rector's default puts the
container cache in the system temp directory, where
`.github/workflows/rector-check.yml` — which caches `.cache/rectorContainer/` —
cannot see it.

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

`__PHP_VERSION__` (e.g. `^8.4`) → `php84` (the rector set name). The agent reads
`--php=` and writes `withPhpSets(php84: true)` accordingly.
