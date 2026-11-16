# Rector config

The `rector.php` shape per category. This file and `stubs/*/rector.php` must
agree, and both must agree with the `phases/*-<category>.md` files. A
disagreement between them is a defect to trace and fix, not a precedence
question — either side can be the stale one.

## The preset

Every stub builds on `sandermuller/rector-preset`, a shared `require-dev`
dependency (see `shared-dev-deps.md`). Its version follows Rector's minor:
`~2.8.0` requires `rector/rector: ~2.8.0`. Bump the preset to move Rector to a
new minor. The preset's own README
(`vendor/sandermuller/rector-preset/README.md`) is the full reference; this file
records what repo-init relies on.

| Category | Stub |
|---|---|
| `laravel-project` | `Preset::app(codingStyle: true, privatization: true, typeDeclarationDocblocks: true)` |
| every other category | `Preset::package()` |

Each stub then adds `->withPhpSets(php__PHP_VERSION_NEON__: true)` and nothing
else. A project adds its configured rules and its own skips to the result.

The preset sets up, in both presets:

- `withCache()` with `.cache/rector`, and the container cache in
  `.cache/phpstan` (the `tmpDir` of the canonical `phpstan.neon.dist`). It
  creates that directory, so the stub needs no `mkdir` line.
- CPU-aware `withParallel()`, `withMemoryLimit('3G')`, `withImportNames()`,
  `withAttributesSets()` and `withFluentCallNewLine()`.
- One `withPreparedSets()` call. `package()` turns on `deadCode`,
  `codeQuality`, `codingStyle`, `typeDeclarations`, `typeDeclarationDocblocks`,
  `privatization`, `rectorPreset` and `phpunitCodeQuality`. `app()` leaves
  `codingStyle`, `typeDeclarationDocblocks` and `privatization` off; the
  laravel-project stub turns them on. `carbon` is on only when `nesbot/carbon`
  is installed. A preset never passes the deprecated `instanceOf`, `if` or
  `earlyReturn` arguments.
- The paths that exist: `app`, `src`, `config`, `routes`,
  `database/factories`, `database/seeders`, `tests`, `workbench`, `bootstrap`.
  `database/migrations` is never scanned, and `bootstrap/cache` and `.cache`
  are skipped.
- The sets of the installed Rector extensions: the five rector-laravel sets
  (`LARAVEL_CODE_QUALITY`, `LARAVEL_ARRAYACCESS_TO_METHOD_CALL`,
  `LARAVEL_COLLECTION`, `LARAVEL_CONTAINER_STRING_TO_FULLY_QUALIFIED_NAME`,
  `LARAVEL_FACADE_ALIASES_TO_FULL_NAMES`), `PestSetList::CODING_STYLE` from
  `pestphp/pest-plugin-rector`, `HihahoSetList::ALL` and the
  laravel-fluent-validation sets.
- `withComposerBased()`: `app()` turns on the set of each installed framework
  (Laravel, Symfony, Doctrine, Twig). Both presets turn on the PHPUnit set only
  when `phpunit/phpunit` is installed and `pestphp/pest` is not, because a Pest
  suite has no `TestCase` classes. `package()` never turns on the Laravel set by
  itself: Rector binds those rules to the installed Laravel version, and a
  package supports a range.

Do not call `withPreparedSets()` or `withCache()` again in a stub.
`withPreparedSets()` only adds sets, so turn a set off with its preset
parameter. `withCache()` resets the container cache directory.

The test-framework variant needs no `rector.php` edit: the preset reads the
installed test framework.

## Skips in the preset

Both presets skip:

- `TernaryToNullsafeCoalesceRector`. It is in the `php80` set, so
  `withPhpSets()` runs it in every category, and its output fails the canonical
  PHPStan config. Reproduced with Rector 2.8.1 and PHPStan 2.3.3:
  `$user !== null ? $user->name : 'guest'` on a `?self` with a non-null
  `string $name` becomes `$user?->name ?? 'guest'`, which PHPStan reports as
  `nullsafe.neverNull`.
- `ExplicitNullableObjectInstanceRector`. It is in `codeQuality` from Rector
  2.8.0, and every stub runs that set together with `deadCode`. Reproduced on
  Rector 2.8.1 with the full `hihaho/rector.php` minus this one skip: guards on
  a nullable enum parameter turn into `instanceof` checks, then
  `RemoveAlwaysTrueIfConditionRector` and `RemoveUnreachableStatementRector`
  empty a private method to `return;`. A queued job dispatch and a failure
  notification disappeared that way.

`package()` also skips `AddArrowFunctionReturnTypeRector`,
`InlineArrayReturnAssignRector`, `PrivatizeFinalClassMethodRector`,
`RemoveUselessParamTagRector` and `RemoveUselessReturnTagRector`: rules that are
noisy or that fight the house style.

`app()` also skips `ArgumentAdderRector`, `ClosureToArrowFunctionRector`,
`PreferPHPUnitThisCallRector`, `RestoreDefaultNullToNullableTypePropertyRector`,
and rector-laravel's `ApplyDefaultInsteadOfNullCoalesceRector` and
`ReplaceServiceContainerCallArgRector`. It adds `PreferPHPUnitSelfCallRector`,
and `PrivatizeFinalClassPropertyRector` while `privatization` is off.

A project removes a preset skip with `unskip: [...]`. A skip whose rule class
does not exist, or whose set is turned off, is left out, so Rector does not
warn that it is never registered.

A project leaves out one detected extension set with `withoutSets: [...]`, for
example `withoutSets: [HihahoSetList::ALL]` in a project that runs single
hihaho rules. The other detected sets stay on. The preset throws for a set it
did not detect. `withoutSets` needs rector-preset 2.8.1 or later: 2.8.0
fails on the unknown parameter, so a project that uses it requires `~2.8.1`.

## `withSkip` — laravel-project reference list

Verified 2026-10-28 (both apps on `rector/rector` 2.8.1) as the blanket
(non-path-scoped) skips present in BOTH `hihaho/rector.php` and
`mijntp/rector.php`, minus the two exceptions below. This is what a mature Laravel app on
this toolchain converges on. Offer it to a `laravel-project` target on top of
`Preset::app()`; it does not apply to package categories. `Preset::app()`
already skips six of these rules (marked below), so add only the rest to the
project's `withSkip()`.

```php
AddMockConsoleOutputFalseToConsoleTestsRector::class,
AddOverrideAttributeToOverriddenPropertiesRector::class,
AppToResolveRector::class,
ApplyDefaultInsteadOfNullCoalesceRector::class, // in Preset::app()
ArgumentAdderRector::class, // in Preset::app()
ArrayExplicitBoolCompareRector::class,
AssertSeeToAssertSeeHtmlRector::class,
CarbonToDateFacadeRector::class,
ClosureToArrowFunctionRector::class, // in Preset::app()
CollectedByPropertyToCollectedByAttributeRector::class,
ContainerBindConcreteWithClosureOnlyRector::class,
DispatchNonShouldQueueToDispatchSyncRector::class,
EnvVariableToEnvHelperRector::class,
InlineIsAInstanceOfRector::class,
LocallyCalledStaticMethodToNonStaticRector::class,
MigrateToSimplifiedAttributeRector::class,
PreferPHPUnitThisCallRector::class, // in Preset::app()
RedirectRouteToToRouteHelperRector::class,
RenameClassRector::class,
ReplaceServiceContainerCallArgRector::class, // in Preset::app()
RestoreDefaultNullToNullableTypePropertyRector::class, // in Preset::app()
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
the list: both presets skip it, so every category skips it.

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
`rector/extension-installer`, which neither reference app installs.

Both presets add `HihahoSetList::ALL` when `hihaho/rector-rules` is installed,
so `--with-hihaho-rules` only adds the package to `require-dev`. The stub needs
no set line.

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
