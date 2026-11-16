# Shared Rector Preset Package (`sandermuller/rector-preset`)

## Overview

About 27 repos each keep their own `rector.php` with the same cache, parallel, memory, prepared-set and skip settings, and these copies drift. This spec defines a Composer package with two presets, `Preset::app()` and `Preset::package()`. Each preset returns a configured `RectorConfigBuilder`. A repo then only adds its paths override, its PHP set and its project-specific rules and skips. The package version follows Rector's minor version, so a Rector upgrade is one package bump in each repo.

**Status:** draft. The user made the design decisions on 2026-11-11 (see `## Resolved Questions`). The assumptions audit is in `## Assumptions`.

## Assumptions

Confirmed by the user in the audit:

- The package is `sandermuller/rector-preset` with namespace `SanderMuller\RectorPreset`.
- `withFluentCallNewLine()` is on in both presets. A repo turns it off with `->withFluentCallNewLine(false)`. There is no extra parameter, because the builder method already overwrites the value. The user first asked for more research: the option only re-formats chains that Rector rewrites.
- `app()` skips the rules that all 7 apps skip and adds `PreferPHPUnitSelfCallRector` and `PrivatizeFinalClassPropertyRector`. The user first confirmed 7 skips. A later review removed `PostIncDecToPreIncDecRector` because it is deprecated in Rector 2.8.4 (§1.7).
- `package()` skips the repo-init list. The user first confirmed all 8 rules. A later review removed `ExplicitBoolCompareRector`, `EncapsedStringsToSprintfRector` and `NullToStrictStringFuncCallArgRector`, because they do nothing in Rector 2.8.4 (§1.7).
- The `instanceOf` parameter is removed, because the set has been empty since Rector 2.6 (§1.7).
- The preset adds every skip only after a `class_exists()` check, including core rules. A scheduled CI job reports a skipped rule that has disappeared (§1.7, §6).
- Preset changes ship in any patch release, and the release notes list each change in rule behaviour.
- An `unskip` parameter exists, because `withSkip()` cannot remove entries.
- FluentValidation detection adds `ALL`, `POLISH` and `SIMPLIFY`. `SCHEMA` stays opt-in.
- `carbon` is on only when `nesbot/carbon` is installed. This changed from "always on in `package()`".
- `LARAVEL_COLLECTION` is in both presets. This changed from "`app()` only" after research.
- Path detection adds `database/factories` and `database/seeders`, never `database/migrations`. This was decided after research.
- The container cache default is `.cache/phpstan`. This changed from `.cache/rectorContainer`. 26 of 27 repos use that `tmpDir`.

Not asked one by one. These follow from facts, or the user can correct them by reading this list:

- PHP floor `^8.4`, confirmed by the user during Phase 1. The spec first said `^8.3`. The repo-init scaffold uses Pest 5, PHPUnit 13 and boost-skills, which all require PHP `^8.4`, so the package's own tests cannot run on 8.3. Repos with PHP 8.2 or 8.3 test legs remove the preset on those legs with `composer remove --dev`, as laravel-fluent-validation already does for other 8.3-only tools.
- The first release is `2.8.0` with `rector/rector: ~2.8.0`. Repos locked below 2.8 must upgrade Rector first.
- The project root comes from `InstalledVersions::getRootPackage()['install_path']`, with a `projectRoot` parameter to override it.
- `detect: false` exists as a full opt-out.
- The CPU reserve, the clamp and the 300 s timeout come from hihaho as they are.
- The spec lives in `repo-init/specs/`, because Phase 7 changes repo-init. Move it into the new package repo when that repo exists.
- The auto-detection ignores the root package (relevant for hihaho/rector-rules and laravel-fluent-validation-rector).
- The Pest detection adds `PEST_LARAVEL` only when `pestphp/pest-plugin-laravel` is installed.

---

## 1. Current State (research)

### 1.1 Scope of the survey

The survey parsed the `rector.php` of 27 primary repos under `~/Documents/GitHub` with a PHP-Parser script. It left out worktree copies (`mijntp-*`, `hihaho-wt-*`, `dev-null.sh-*`, `laravel-brain-*`, `finconnect-*`) and third-party repos (rector-src, tempest, laravel/ai, swiss-knife, symplify-phpstan-rules, shopware-bench). Nobody ran Rector during the survey. All counts come from the config source.

### 1.2 Two families

| | App family (7) | Package family (19) |
|---|---|---|
| Repos | hihaho, mijntp, dipcatch, 123metpensioen, finconnect, collectiq, blinqx-shared-services | boost-pipeline, laravel-queue-insights, phpstan-to-mago, richter, productaivideo, laravel-fluent-validation, laravel-fluent-validation-rector, project-boost-laravel, laravel-model-stats, boost-core, Stopwatch, qore, package-boost-php, laravel-ai-qore, phpstan-rules, repo-new, rector-rules, dev-null.sh, laravel-fluent-validation-phpstan |
| Origin | copied from hihaho | copied from the repo-init stubs |
| `codingStyle` / `privatization` / `instanceOf` | off (5–6 of 7) | on (15–19 of 19) |
| `typeDeclarationDocblocks` | 2 of 7 | 17 of 19 |
| Parallel workers | CPU detection in 4 of 7, else 15 | 15 |
| `withFluentCallNewLine()` | 0 of 7 | 14 of 19 |

`instanceOf` has had no effect since Rector 2.6 (§1.7).

rivalbyte mixes both families: it has package prepared sets, CPU detection and the hihaho rules. The survey counts it in neither column.

### 1.3 Settings shared by (almost) all repos

- `withMemoryLimit('3G')`: 26 of 27.
- `withParallel(300, …, 15)`: 26 of 27.
- `withCache(cacheDirectory: './.cache/rector')`: 23 of 27.
- `withPreparedSets(typeDeclarations: true)`: 27 of 27. `rectorPreset` and `phpunitCodeQuality`: 25 of 27.
- `withAttributesSets()`: 24 of 27. `withImportNames()`: 23 of 27.

### 1.4 Shared skips

- **App family, all 7:** `ApplyDefaultInsteadOfNullCoalesceRector`, `ArgumentAdderRector`, `ClosureToArrowFunctionRector`, `PreferPHPUnitThisCallRector`, `ReplaceServiceContainerCallArgRector` and `RestoreDefaultNullToNullableTypePropertyRector`. `PostIncDecToPreIncDecRector` is in 6 of 7. mijntp does not skip it.
- **Package family (repo-init stub list):** `AddArrowFunctionReturnTypeRector`, `InlineArrayReturnAssignRector`, `PrivatizeFinalClassMethodRector`, `RemoveUselessParamTagRector` and `RemoveUselessReturnTagRector` are in 17 of 19. `NullToStrictStringFuncCallArgRector` and `ExplicitBoolCompareRector` are in 13 of 19. `EncapsedStringsToSprintfRector` is in 12 of 19.
- **App family, always added as rules:** `PreferPHPUnitSelfCallRector` (7 of 7) and `PrivatizeFinalClassPropertyRector` (6 of 7, all apps except collectiq).

### 1.5 Drift found

- **CPU detection.** The code exists in 5 copies. hihaho keeps 2 cores free locally and 0 on CI (`getenv('CI')`). mijntp, dipcatch, 123metpensioen and rivalbyte keep 1 core free everywhere.
- **`containerCacheDirectory`.** It is `.cache/rectorContainer` in 15 repos, `.cache/phpstan` in 2 (hihaho, productaivideo) and not set in 10. Only rivalbyte creates the directory before Rector asserts that it exists.
- **Dead argument.** 24 repos pass `cacheClass: FileCacheStorage::class`. Rector ignores this argument: see the docblock in `vendor/rector/rector/src/Configuration/RectorConfigBuilder.php` in hihaho (2.6.6) and mijntp (2.8.4).
- **repo-init stubs.** `references/rector-config.md` lists `containerCacheDirectory` and `withParallel(300, 15, 15)`. The stubs in `stubs/*/rector.php` do not set `containerCacheDirectory`.
- **Rector versions.** The locked `rector/rector` versions go from 2.4.2 (collectiq) to 2.8.4 (mijntp, rector-rules). driftingly/rector-laravel in mijntp requires `rector/rector: ^2.8`.

### 1.6 Rector builder facts that constrain the design

All of these were read in `rector-src/src/Configuration/RectorConfigBuilder.php` (main, 2026-10-26, after the 2.8.0 tag) and confirmed in vendor copies where noted.

| Fact | Consequence |
|---|---|
| `final class RectorConfigBuilder` (also in vendor 2.8.4) | The package cannot extend the builder. It returns a configured builder from a static factory. |
| `withPreparedSets()` only appends the sets that are `true`. Calling it with `false` does nothing. | A repo cannot turn off a prepared set that the preset enabled. The preset takes each prepared set as a parameter and calls `withPreparedSets()` once. |
| `withSkip()`, `withSets()` and `withRules()` use `array_merge`. | A repo can add skips, sets and rules. A repo cannot remove a skip that the preset added, so the preset takes an `unskip` parameter (see §3.3). |
| `withPaths()` replaces the list. | Auto-detected paths are a default that a repo can replace. |
| `withPhpSets()` throws an error on a second call. | The preset never calls `withPhpSets()`. |
| `withCache()` sets every argument it does not get to `null`. | The preset owns the cache. The container cache location is a preset parameter. |
| `withParallel()`, `withMemoryLimit()`, `withImportNames()` and `withFluentCallNewLine(bool)` overwrite. | A repo can override these after the preset. |
| `withComposerBased()` appends version-matched sets. For `laravel` it checks `class_exists(LaravelSetList)` itself. | The preset can call it for each installed framework. |
| `RectorConfig::containerCacheDirectory()` calls `Assert::directory()`. | The preset must create the directory first, as rivalbyte does. |
| `RectorConfigValidator` throws `ShouldNotHappenException` for a skipped Rector class that does not exist. | A skip of a rule from an extension that is not installed breaks the config. Skips from rector-laravel or rector-pest need a `class_exists` check. A Rector bump that removes a skipped core rule also breaks the config, so the package CI must catch it. |
| `LEVEL_METHOD_TO_SET`: `withTypeCoverageDocblockLevel()` together with the `typeDeclarationDocblocks` set throws an error. | The app preset leaves `typeDeclarationDocblocks` off. hihaho and collectiq call `withTypeCoverageDocblockLevel()`. |
| `ProcessCommand` prints a warning when a skipped rule implements `DeprecatedInterface` ("These rules are skipped, but are deprecated…"). This is checked in vendor 2.8.4. | The preset must not skip deprecated rules (§1.7). |

### 1.7 Rector changes inside a minor version

Checked in the rector-src tags and in mijntp's vendor copy of Rector 2.8.4.

- **Rules disappear in patch releases.**
  - 2.5.0 → 2.5.9 deleted 7 rule classes, for example `SortNamedParamRector` and `FirstClassCallableRector`.
  - 2.6.0 → 2.6.7 deleted 4, for example `NewInInitializerRector`.
  - None of them exists under the same name elsewhere in the later tag.
  - Because a skip of a missing rule throws an error (§1.6), a Rector patch release can break a config that skips a rule. A `~2.8.0` constraint does not prevent this.
- **Sets change in patch releases.**
  - 2.6.x deprecated `SetList::INSTANCEOF` and `SetList::IF` and moved their rules into `codeQuality`, `codingStyle` and `typeDeclarations` (PRs #8408 and #8414).
  - In 2.8.4, `config/set/instanceof.php` registers no rules, and the `$instanceOf` argument of `withPreparedSets()` carries `@deprecated`.
  - So the apps that pass `instanceOf: false` already run those rules through `codeQuality`.
- **Skips that do nothing in 2.8.4:**

| Rule | State in 2.8.4 | Since |
|---|---|---|
| `ExplicitBoolCompareRector` | `DeprecatedInterface`, in no set or level list | PR #8412, 2026-08-30 |
| `EncapsedStringsToSprintfRector` | `DeprecatedInterface`, in no set | PR #8265, 2026-08-02 |
| `PostIncDecToPreIncDecRector` | `DeprecatedInterface`, in no set | PR #8583, 2026-10-10 |
| `NullToStrictStringFuncCallArgRector` | not deprecated, in no set | removed from the PHP 8.1 set in PR #8234, 2026-07-30 |

  15 surveyed repos skip `ExplicitBoolCompareRector`, and 8 skip `PostIncDecToPreIncDecRector`. Each of them gets the deprecation warning on every run once it uses a Rector version that has the deprecation. Not checked: which exact release first shipped each deprecation.

- **Skips that are still active in 2.8.4:**
  - `AddArrowFunctionReturnTypeRector` (`TypeDeclarationLevel`), `InlineArrayReturnAssignRector` (`CodeQualityLevel`), and `RemoveUselessParamTagRector` and `RemoveUselessReturnTagRector` (`DeadCodeLevel`).
  - `PrivatizeFinalClassMethodRector` (privatization set).
  - `ArgumentAdderRector`, `ClosureToArrowFunctionRector` and `RestoreDefaultNullToNullableTypePropertyRector` (PHP version sets).
  - `PreferPHPUnitThisCallRector` (`phpunit-code-quality.php`).

---

## 2. Package Identity and Versioning

- **Composer name:** `sandermuller/rector-preset`. **Namespace:** `SanderMuller\RectorPreset`.
- **Type:** `library`. Consumers install it with `require-dev`.
- **PHP floor:** `^8.4`. The package's test stack (Pest 5, PHPUnit 13) requires PHP 8.4. Repos with PHP 8.2 or 8.3 test legs run Rector on a newer PHP version anyway. They add the preset to the `composer remove --dev` line of those legs, as laravel-fluent-validation already does for other tools (`.github/workflows/run-tests.yml`).
- **`require`:** `rector/rector: ~2.8.0` and `composer-runtime-api: ^2.2` (for `Composer\InstalledVersions::getRootPackage()['install_path']`).
- **`suggest`, not `require`:** `driftingly/rector-laravel`, `mrpunyapal/rector-pest`, `hihaho/rector-rules` and `sandermuller/laravel-fluent-validation-rector`. rector-laravel 2.7.3 requires `rector/rector: ^2.8`.
- **Version scheme:** the package major and minor are the same as the Rector major and minor. The patch number is the package's own. Package `2.8.0` is the first release and requires `rector/rector: ~2.8.0`. When Rector releases 2.9.0, the package releases `2.9.0` with `~2.9.0`.
- **Preset changes:** a new skip, a new set or a changed default ships in any patch release. The release notes list every change in rule behaviour. This matches how Rector itself ships (§1.7). Consumers see the effect in their `rector --dry-run` CI job.
- **Consumers** require `sandermuller/rector-preset: ~2.8.0`. Dependabot already raises out-of-range constraints of this kind. In hihaho it changed `hihaho/rector-rules` from `^0.12.1` to `^0.14.0` (PR #10028), and a caret on `0.x` behaves like this tilde.
- **Built from:** the repo-init `php-package` category, which gives Pest, PHPStan, Pint, Rector and CI.

---

## 3. Public API

### 3.1 Factory

```php
namespace SanderMuller\RectorPreset;

final class Preset
{
    public static function package(
        ?string $projectRoot = null,
        ?string $containerCacheDirectory = null,
        bool $deadCode = true,
        bool $codeQuality = true,
        bool $codingStyle = true,
        bool $typeDeclarations = true,
        bool $typeDeclarationDocblocks = true,
        bool $privatization = true,
        ?bool $carbon = null,         // null: true when nesbot/carbon is installed
        bool $rectorPreset = true,
        bool $phpunitCodeQuality = true,
        array $unskip = [],
        bool $detect = true,
        bool $composerBased = false,  // app(): true. See §5.
    ): RectorConfigBuilder;

    public static function app(
        // same parameters; defaults per §4.2
    ): RectorConfigBuilder;
}
```

Usage in a repo:

```php
return Preset::app()
    ->withPhpSets(php85: true)
    ->withConfiguredRule(/* project values */)
    ->withSkip([/* project-specific skips only */]);
```

### 3.2 Project root

- The default is the root of the Composer installation that contains `sandermuller/rector-preset`, through `realpath()`. It is not `InstalledVersions::getRootPackage()`: see the Phase 2 finding.
- A repo can pass `projectRoot: __DIR__`. The preset uses this root for the cache paths and for path detection.

### 3.3 `unskip`

`unskip` is a list of rule classes. The preset removes these rules from its own skip list before it calls `withSkip()`. This is the only way to undo a preset skip, because of the `withSkip()` merge (see §1.6).

### 3.4 `detect`

`detect: false` turns off everything in §5. The preset then sets only the base and the prepared sets. This exists for repos where the detection gives the wrong result.

---

## 4. Preset Contents

### 4.1 Base (both presets)

| Setting | Value |
|---|---|
| Cache | `withCache(cacheDirectory: <root>/.cache/rector, containerCacheDirectory: <dir>)`. `<dir>` is the parameter, or `<root>/.cache/phpstan` by default. The default shares PHPStan's `tmpDir`: 26 of 27 repos set `tmpDir: .cache/phpstan` (dev-null.sh uses `tmp/phpstan`). hihaho measured that 99% of Rector's container cache entries are entries PHPStan also writes. hihaho and productaivideo already share it this way. The preset creates `<dir>` with a race-tolerant `mkdir`. It does not pass `cacheClass`. |
| Parallel | `withParallel(300, CpuCores::workers(), 15)` |
| Memory | `withMemoryLimit('3G')` |
| Imports | `withImportNames()` |
| Attributes | `withAttributesSets()` |
| Prepared sets | One `withPreparedSets()` call with the preset's parameters |

**`CpuCores::workers()`** uses the hihaho algorithm:

1. Count the `^processor\s*:` lines in `/proc/cpuinfo` when it is readable.
2. Otherwise, when `shell_exec` exists, run `sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null`.
3. Otherwise, use 4.
4. Keep 0 cores free when `getenv('CI') !== false`, else keep 2.
5. Clamp the result to 2..15.

### 4.2 Prepared-set defaults

| Set | `package()` | `app()` | Evidence |
|---|---|---|---|
| `deadCode` | true | true | packages 19/19, apps 6/7 |
| `codeQuality` | true | true | packages 19/19, apps 5/7 |
| `codingStyle` | true | false | packages 19/19, apps 5/7 false |
| `typeDeclarations` | true | true | 27/27 |
| `typeDeclarationDocblocks` | true | false | packages 17/19. Must be off in hihaho and collectiq (§1.6). |
| `privatization` | true | false | packages 19/19, apps 6/7 false |
| `carbon` | when installed | when installed | apps 7/7, packages 13/19. `null` resolves to `isInstalled('nesbot/carbon')`. The set adds rules such as `DateFuncCallToCarbonRector`, which would bring Carbon into a package that does not depend on it. |
| `rectorPreset` | true | true | 25/27 |
| `phpunitCodeQuality` | true | true | 25/27 |

`instanceOf` and `earlyReturn` are not parameters. Both sets have been empty since Rector 2.6, and their rules run through `codeQuality` and `typeDeclarations` (§1.7 and the Phase 7 finding).

### 4.3 Skips

`package()` skips:

- `AddArrowFunctionReturnTypeRector`, `InlineArrayReturnAssignRector`, `PrivatizeFinalClassMethodRector`, `RemoveUselessParamTagRector`, `RemoveUselessReturnTagRector`

`app()` skips:

- `ApplyDefaultInsteadOfNullCoalesceRector`, `ReplaceServiceContainerCallArgRector` (rector-laravel)
- `ArgumentAdderRector`, `ClosureToArrowFunctionRector`, `PreferPHPUnitThisCallRector`, `RestoreDefaultNullToNullableTypePropertyRector`

Not skipped, because they do nothing in Rector 2.8.4 (§1.7): `ExplicitBoolCompareRector`, `EncapsedStringsToSprintfRector`, `PostIncDecToPreIncDecRector` and `NullToStrictStringFuncCallArgRector`. The first three are deprecated, so a skip would also print Rector's deprecation warning on every run.

**Every skip is guarded.** The preset adds a skip only when `class_exists()` is true for the rule. This includes core rules, because Rector deletes rules in patch releases (§1.7) and a skip of a missing rule throws an error. A deleted rule then loses its skip without an error, which is correct because the rule no longer runs. A renamed rule would lose its skip without notice, so the scheduled CI job in §6 fails when a guarded skip no longer resolves.

`app()` adds the rules `PreferPHPUnitSelfCallRector` and `PrivatizeFinalClassPropertyRector` (see §1.4). It adds `PrivatizeFinalClassPropertyRector` only when `privatization` is false. That rule is in `config/set/privatization.php`, and Rector warns when a rule is in a set and in `withRules()` at the same time (`ProcessCommand`, "registered in both sets and withRules()").

All rules in these lists exist in rector/rector 2.8.4 and rector-laravel 2.7.3 (checked in mijntp's vendor), and none of them is deprecated. `PreferPHPUnitThisCallRector` and `PreferPHPUnitSelfCallRector` come from rector-phpunit, which rector/rector bundles, so they need no `class_exists` check.

`withFluentCallNewLine()`: on in both presets. It only affects a method chain that a Rector rule rewrites. `BetterStandardPrinter::pExpr_MethodCall` prints that chain one call per line, and the format-preserving printer leaves all other code as it is. None of the apps turned it off on purpose: hihaho never had it, and dipcatch only had a commented-out line. All surveyed `pint.json` files use the `laravel` preset with no chain rule. To turn it off, a repo calls `->withFluentCallNewLine(false)` after the preset. The builder stores `false` and passes it to `newLineOnFluentCall(false)` (`RectorConfigBuilder.php:333`, `:981`).

---

## 5. Auto-Detection (`detect: true`)

The preset detects installed packages with `Composer\InstalledVersions::isInstalled()`. It never treats the root package as an installed dependency (see Edge Cases). This reads the project's Composer data: rector/rector ships its own copy under the `RectorPrefix202611\Composer` namespace (`vendor/rector/rector/vendor/composer/InstalledVersions.php`), so the two copies do not clash.

| Detection | Condition | Effect |
|---|---|---|
| Default paths | Each of `app`, `src`, `config`, `routes`, `database/factories`, `database/seeders`, `tests`, `workbench` and `bootstrap` that exists under the root. Never `database/migrations`: hihaho commit `2cf7dab2b1` keeps migrations out on purpose ("never rewrite migrations"). The same commit added `database/factories`, which was missing by accident. | `withPaths([...])`, plus `withSkip([<root>/bootstrap/cache, <root>/.cache])` when they exist |
| Composer-based sets | `app()` only, or `package(composerBased: true)`. `phpunit/phpunit`, `laravel/framework`, `symfony/framework-bundle`, `doctrine/orm` and `twig/twig` installed (see the Phase 4 finding). | `withComposerBased(phpunit:, laravel:, symfony:, doctrine:, twig:)` with each flag set from detection. For Laravel apps this also loads rector-laravel's Livewire 3 and 4 rules, bound to the installed Livewire version. |
| Laravel sets | `driftingly/rector-laravel` installed | `LARAVEL_CODE_QUALITY`, `LARAVEL_ARRAYACCESS_TO_METHOD_CALL`, `LARAVEL_CONTAINER_STRING_TO_FULLY_QUALIFIED_NAME`, `LARAVEL_FACADE_ALIASES_TO_FULL_NAMES` (18/27) and `LARAVEL_COLLECTION`, in both presets. `LARAVEL_COLLECTION` has 5 rules, and the ones read check `isObjectType(..., Illuminate\Support\Enumerable)` first. The repo-init stubs never had this set (`git log -S` finds nothing), so packages lack it by omission. |
| Pest (community) | `mrpunyapal/rector-pest` installed (`RectorPest\Set\PestSetList`; 9 repos) | `PEST_CODE_QUALITY`, `PEST_CHAIN`; plus `PEST_LARAVEL` when `pestphp/pest-plugin-laravel` is installed |
| Pest (official) | `pestphp/pest-plugin-rector` installed (`Pest\Rector\Set\PestSetList`; 4 repos) | `CODING_STYLE`, the only set this package has in 5.0.6 |
| hihaho rules | `hihaho/rector-rules` installed and not the root | `HihahoSetList::ALL` |
| FluentValidation | `sandermuller/laravel-fluent-validation-rector` installed and not the root | `FluentValidationSetList::ALL`, `POLISH`, `SIMPLIFY` (4/4 users). `SCHEMA` stays opt-in (2/4). |

**Why `package()` leaves composer-based sets off:**

- Rector picks version-bound rules from the installed version in `vendor/composer/installed.json` (`InstalledPackageResolver::resolve()`). It does not use the range in `composer.json`.
- A Laravel package installs the newest Laravel in development. For example, laravel-model-stats locks `laravel/framework v13.30.1` and supports `^12.0||^13.0`.
- rector-laravel's Laravel 13 attribute rules use `ComposerPackageConstraint('laravel/framework', '>=13.0')`, for example `SignaturePropertyToSignatureAttributeRector`. In laravel-queue-insights (`^11||^12||^13`, 5 commands with `protected $signature`), these rules would produce code that fails on Laravel 11 and 12.
- PHPUnit's composer-based set has the same risk for packages that test against several PHPUnit versions.
- A package that supports one major version only can pass `composerBased: true`.

**No separate Livewire detection:**

- `LivewireLevelSetList::UP_TO_LIVEWIRE` points to `up-to-livewire-30.php`, so it only holds the Livewire 3 upgrade rules.
- rector-laravel's `composer-based.php` has Livewire rules bound to the installed version (`'livewire/livewire', '>=3.0'` and `'>=4.0'`).

The preset references every extension set by its constant only after a `class_exists` check on the set-list class. The package does not autoload the extension, so a constant of a missing class must never be evaluated.

---

## 6. Testing and CI

- **Unit tests (Pest):**
  - `CpuCores` with an injected reader for cpuinfo, shell and env.
  - Path detection against fixture directories.
  - `unskip` filtering.
  - Prepared-set mapping for each preset.
- **Boot tests:**
  - For each preset, build the config with the real `RectorConfigBuilder` and run `vendor/bin/rector process --dry-run` on a fixture project.
  - Do it once with every extension installed and once with none. This proves that no skipped class is missing and that no set constant is unresolved.
- **Skip-health test:** for every rule in both skip lists, assert that `class_exists()` is true and that the rule does not implement `DeprecatedInterface`. Run it in the normal CI and in a weekly scheduled job on `prefer-stable`, so a Rector patch release that deletes, renames or deprecates a skipped rule fails within a week. The guard in §4.3 keeps consumers working in the meantime.
- **CI matrix:** PHP 8.4 and 8.5 × `prefer-lowest`/`prefer-stable`. `prefer-lowest` resolves `rector/rector` to `2.8.0`.
- **Detection in tests:** the package's own tests run with the package as the root, so `InstalledVersions` shows the package's dev dependencies, not the fixture's. The `Installed` helper therefore takes an injectable package list, and the detection tests use it.
- **Dependabot:** watch `rector/rector`. In consumer apps, Dependabot already raises out-of-range constraints (hihaho PR #10028). NEEDS-CONFIRMATION: for this package, which is a library, set `versioning-strategy: increase` explicitly, and check on the first Rector minor release that the PR changes `~2.8.0` to `~2.9.0` and does not widen it. The `2.9.0` release itself stays a manual step.

---

## 7. Migration

### 7.1 repo-init

- Replace the rector body in the 8 `stubs/*/rector.php` files with `Preset::package()` or `Preset::app()` plus `withPhpSets(php__PHP_VERSION_NEON__: true)`.
- Add `sandermuller/rector-preset` to the per-category dev deps.
- Rewrite `references/rector-config.md` to describe the preset and what a repo still owns.
- Update the audit and upgrade phases. The audit flags a repo that does not use the preset. The upgrade replaces a hand-written config, and it keeps the project-specific skips and configured rules.

### 7.2 Repos

Pilot one package (boost-core) and one app (hihaho). Then migrate the other repos. Remove from each config what the preset now covers. Check that `vendor/bin/rector --dry-run` produces no diff before and after.

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| rector-laravel or rector-pest is not installed, but the preset skips one of its rules | Skip only after `class_exists()` (§4.3). Covered by the boot test without extensions (Phase 5). |
| A Rector release (patch or minor) deletes or renames a skipped rule | The guard drops the skip, so consumers do not break. The weekly skip-health job fails, and the maintainer adds the new name or removes the entry in a patch release (Phase 5). |
| A Rector release deprecates a skipped rule | Consumers see Rector's deprecation warning until the next preset patch. The weekly skip-health job fails and names the rule (Phase 5). |
| A repo calls `withCache()` after the preset | The repo's call resets `containerCacheDirectory` to `null`. The README tells repos to use the preset parameter. Not prevented in code. |
| A repo calls `withPhpSets()` | Works, because the preset never calls it (§1.6). |
| A repo calls `withPaths()` | Replaces the detected paths (§5). Tested in Phase 4. |
| A repo wants a prepared set or skip that the preset turns off | Pass the preset parameter or `unskip` (§3). Tested in Phase 2. |
| The container cache directory does not exist (fresh clone, CI) | The preset creates it before `withCache()`. Parallel workers load the config again, so `mkdir` is race-tolerant: `! is_dir() && ! mkdir() && ! is_dir()` → throw. Tested in Phase 2. |
| `shell_exec` is disabled and `/proc/cpuinfo` is not readable | `CpuCores` returns 4 before the reserve and the clamp. Tested in Phase 2. |
| A container sees the host's cores, not its vCPU quota | The clamp to 15 limits the worst case to today's fixed value (§4.1). |
| The root package is `hihaho/rector-rules` or `laravel-fluent-validation-rector` itself | The detection ignores the root package, so the extension does not run its own set on its own source. Tested in Phase 4. |
| A folder from the path list does not exist | Not added. A repo with none of the folders gets an empty path list, and Rector reports that no files were found. Tested in Phase 4. |
| A Laravel package supports several Laravel majors and dev installs the newest | `package()` does not call `withComposerBased()`, so no Laravel-13-only rules run (§5). Tested in Phase 4. |
| A Livewire app | `app()` gets the version-bound Livewire rules through `withComposerBased(laravel: true)`. There is no separate Livewire set (§5). |
| `app(privatization: true)` | The preset does not add `PrivatizeFinalClassPropertyRector` as well, so Rector does not warn about a duplicate (§4.3). Tested in Phase 3. |
| `withTypeCoverageDocblockLevel()` in a repo that uses `package()` | Rector throws an error. The README says to pass `typeDeclarationDocblocks: false` together with the level method. |
| A repo locked on Rector < 2.8 | Composer refuses the install. The repo must upgrade Rector first. This is accepted (§2). |
| `InstalledVersions` gives a root path through a symlink | `realpath()` resolves it (§3.2). |
| A repo has no Carbon dependency | `carbon` resolves to false, so no Carbon rules run (§4.2). Tested in Phase 3. |
| A repo's PHPStan `tmpDir` is not `.cache/phpstan` (dev-null.sh: `tmp/phpstan`) | The preset still uses `.cache/phpstan`. Both tools keep working, but the cache is not shared. The repo passes `containerCacheDirectory:` to share it. |
| Rector and PHPStan run at the same time and share the cache directory | hihaho and productaivideo already run this way. Not handled in the package. Write it in `## Findings` if the pilots show cache corruption. |
| A repo wants Rector to rewrite migrations | It calls `withPaths([...])` with `database/migrations` added (§5). |
| A repo does not want fluent new lines | It calls `->withFluentCallNewLine(false)` after the preset (§4.3). Tested in Phase 3. |

## Implementation

### Phase 1: Scaffold the package (Priority: HIGH)

- [x] Create `SanderMuller/rector-preset` from the repo-init `php-package` stub — the standard tooling and CI
- [x] Set up `composer.json`: `rector/rector: ~2.8.0`, `composer-runtime-api: ^2.2`, PHP `^8.4`, and the extensions as `suggest` and `require-dev` — §2
- [x] Add the fixture projects under `tests/Fixtures/` (package-shaped and Laravel-app-shaped) — needed for the boot tests
- [x] Tests — a smoke test that the autoload works and that `Preset` exists

### Phase 2: Base settings (Priority: HIGH)

- [x] `ProjectRoot::resolve(?string)` — `InstalledVersions` root plus `realpath`, §3.2
- [x] `CpuCores::workers()` with injectable readers — the hihaho algorithm, §4.1
- [x] Container cache directory creation, race-tolerant — §1.6, Edge Cases
- [x] The shared base builder: cache, parallel, memory, import names, attribute sets — §4.1
- [x] Prepared-set parameters mapped to one `withPreparedSets()` call — §1.6
- [x] `unskip` filtering — §3.3
- [x] Tests — CPU detection: cpuinfo, sysctl, no shell, CI reserve, clamp to 2 and 15; mkdir when the directory is missing and when it already exists; `unskip` removes only the listed rules

### Phase 3: Presets (Priority: HIGH)

- [x] `Preset::package()`: defaults and skip list from §4.2 and §4.3, plus `withFluentCallNewLine()`
- [x] `Preset::app()`: defaults, skip list and the two added rules from §4.2 and §4.3, plus `withFluentCallNewLine()`
- [x] `carbon: null` resolves from `nesbot/carbon` — §4.2
- [x] `class_exists` check for every skip, core and extension — §4.3
- [x] Tests — each preset produces the expected sets, skips and rules; `typeDeclarationDocblocks` is off in `app()`; `app(privatization: true)` does not add `PrivatizeFinalClassPropertyRector`; overrides of the parameters work; `carbon` follows detection; a later `withFluentCallNewLine(false)` turns it off

### Phase 4: Auto-detection (Priority: HIGH)

- [x] `Installed` helper — `ComposerProject::isInstalled()` from Phase 2, which reads only the project's installation and ignores the root package
- [x] Default paths from the existing folders, including `database/factories` and `database/seeders` but never `database/migrations`, with the `bootstrap/cache` and `.cache` skips — §5
- [x] `withComposerBased()` flags from detection, on in `app()` and off in `package()` unless `composerBased: true` — §5
- [x] Laravel, Pest, hihaho and FluentValidation sets behind `class_exists` — §5
- [x] `detect: false` switches all of it off — §3.4
- [x] Tests — each detection row on and off; the root package is ignored; a later `withPaths()` replaces the defaults; `package()` adds no composer-based sets unless `composerBased: true`; `database/migrations` is never in the paths

### Phase 5: Boot tests and CI (Priority: HIGH)

- [x] Boot test: each preset runs `rector process --dry-run` on its fixture with all extensions installed — proves the sets resolve
- [x] Boot test without the extensions (a separate CI job that runs `composer remove` on them) — proves the `class_exists` checks
- [x] Skip-health test: every skipped rule exists and is not deprecated — §6
- [x] Weekly scheduled workflow that runs the skip-health test on `prefer-stable` — catches Rector patch releases that delete, rename or deprecate a skipped rule
- [x] CI matrix PHP 8.4–8.5 × lowest/stable — §6
- [x] Dependabot config for `rector/rector` with `versioning-strategy: increase` — §6
- [x] Tests — the CI workflow is green on all matrix legs: run 43049814007 on `c64ac64836f2ef2457e60b8da1b4fdc2821fdefd`, all 5 jobs succeeded (8.4 and 8.5 × prefer-lowest and prefer-stable, and 8.4 without extensions).

### Phase 6: Docs and first release (Priority: HIGH)

- [x] README: install, the two presets, the parameter table, what a repo still owns (`withPhpSets`, configured rules, project skips), the `withCache` warning and the version scheme
- [x] Release notes in `internal/release-notes-2.8.0.md` (draft; its `verified-sha` line waits for the first commit); the user tags `2.8.0` — the repo's release flow. Every later release note lists each change in rule behaviour — §2
- [x] Tests — the README examples are copied into a boot test fixture

### Phase 7: repo-init migration (Priority: MEDIUM)

- [x] Rewrite the 8 `stubs/*/rector.php` files to use the preset — §7.1
- [x] Add `sandermuller/rector-preset` to the per-category dev deps
- [x] Rewrite `references/rector-config.md`
- [x] Update the audit and upgrade phases for rector — §7.1
- [x] Tests — the repo-init stub checks pass; a newly scaffolded package runs `rector --dry-run` with no errors

### Phase 8: Pilot migrations (Priority: MEDIUM)

- [x] Migrate boost-core to `Preset::package()` — before the switch, list the expected differences (for example `config/` in the paths, `carbon` detection); the dry-run diff contains only those
- [x] Migrate hihaho to `Preset::app()` — keep its configured rules and path skips; the dry-run diff is empty except for the changes the new defaults bring (seeders in the paths, fluent new lines)
- [x] Write down each difference the pilots find in `## Findings`, and fix the preset where the difference is not project-specific
- [x] Tests — `vendor/bin/rector --dry-run` in each pilot repo

### Phase 9: Rollout (Priority: LOW)

- [x] Migrate the remaining apps and packages one PR per repo — §7.2. Done for the in-scope repos: 8 PRs opened, 7 repos left out with a recorded reason (see the Phase 9 findings table).
- [x] Tests — the dry-run diff is empty in each repo: in each of the 8 PRs, `rector process --dry-run` gives the same files and diff as the base branch, and `rector list-rules` differs only as listed in the table.

---

## Open Questions

None.

---

## Resolved Questions

1. **Extend the builder, or something else?** **Decision:** a static factory that returns the real `RectorConfigBuilder`. **Rationale:** the builder is `final`. A `__call` wrapper would lose IDE completion.
2. **One preset or two?** **Decision:** two, `app()` and `package()`. **Rationale:** the families have opposite settings for `codingStyle`, `privatization` and `instanceOf`, and a repo cannot turn off a prepared set afterwards.
3. **Version scheme?** **Decision:** mirror Rector's major and minor version, with the package's own patch number. **Rationale:** one bump per Rector upgrade, and package fixes do not need a Rector release.
4. **Vendor?** **Decision:** `sandermuller/*`, public. **Rationale:** the user's choice. No project-specific paths go into the package.
5. **What does the package own?** **Decision:** CPU-aware parallel, the container cache directory, `withFluentCallNewLine`, and the Laravel and Pest sets when installed. **Rationale:** the user's choice.
6. **What does it detect?** **Decision:** `withComposerBased` (in `app()` only, see 12), default paths, and the hihaho and FluentValidation sets when installed. The Livewire set was dropped in the review (see 13). **Rationale:** the user's choice. The PHP level, the preset choice and PHPStan's `tmpDir` are not detected (see §1.6 and the conversation of 2026-11-11).
7. **Which `database/` folders?** **Decision:** `factories` and `seeders`, never `migrations`. **Rationale:** hihaho never rewrites migrations on purpose (commit `2cf7dab2b1`), and its factories were missing only by accident.
8. **Container cache default?** **Decision:** `.cache/phpstan`. **Rationale:** 26 of 27 repos use it as PHPStan's `tmpDir`, and hihaho measured a 99% overlap.
9. **`LARAVEL_COLLECTION` in packages?** **Decision:** yes, in both presets. **Rationale:** the rules only act on `Enumerable` types, and packages lacked the set only because the stub did.
10. **`carbon` default?** **Decision:** on when `nesbot/carbon` is installed. **Rationale:** the set adds Carbon calls, which a package without Carbon must not get.
11. **Turn off fluent new lines?** **Decision:** `->withFluentCallNewLine(false)` after the preset. There is no extra parameter. **Rationale:** the builder method overwrites the value.
12. **`withComposerBased()` in packages?** **Decision:** on in `app()`, off in `package()` unless `composerBased: true`. **Rationale:** Rector binds these rules to the installed version, not the supported range. Packages that support several Laravel majors would get Laravel-13-only code (§5).
13. **Separate Livewire detection?** **Decision:** dropped. **Rationale:** `UP_TO_LIVEWIRE` only holds the Livewire 3 rules, and `withComposerBased(laravel: true)` already loads Livewire 3 and 4 rules bound to the installed version.
14. **Skips that do nothing in Rector 2.8.4?** **Decision:** drop `ExplicitBoolCompareRector`, `EncapsedStringsToSprintfRector`, `PostIncDecToPreIncDecRector` and `NullToStrictStringFuncCallArgRector`. **Rationale:** no set contains them. The first three are deprecated and cause a warning on every run (§1.7).
15. **`instanceOf` parameter?** **Decision:** removed. **Rationale:** the set has been empty since Rector 2.6, and the argument is `@deprecated` (§1.7).
16. **How to guard skips?** **Decision:** a `class_exists()` check on every skip, plus a weekly skip-health CI job. **Rationale:** Rector deleted 11 rules inside the 2.5.x and 2.6.x patch series, and a skip of a missing rule throws an error (§1.7).
17. **PHP floor?** **Decision:** `^8.4`. This changed from `^8.3` during Phase 1. **Rationale:** Pest 5, PHPUnit 13 and boost-skills in the standard scaffold require PHP 8.4, so the package's tests cannot run on 8.3. Repos with older PHP test legs remove the preset on those legs.
18. **How do preset changes ship?** **Decision:** in any patch release, with every change in rule behaviour in the release notes. **Rationale:** Rector itself changes sets and deprecates rules in patch releases (§1.7). A preset that changes only at minor bumps would not make consumer output stable.
19. **Lower the preset's PHP floor to `^8.3`?** **Decision:** Keep `^8.4` (user, 2026-11-11). **Rationale:** The 13 repos that still allow PHP 8.3 migrate only after they raise their own floor to 8.4.

## Findings

<!-- Notes added during implementation. Do not remove this section. -->

### Phase 1

- **Location:** the package lives in `~/Documents/GitHub/rector-preset`. It was scaffolded with `repo new rector-preset --type=php-package --vendor=sandermuller --php=8.4 --test-framework=pest --license=MIT`. There is no GitHub remote yet, and no commit.
- **Namespace:** `repo new` generated `Sandermuller\RectorPreset`. It was changed to `SanderMuller\RectorPreset`, the spelling the spec and the other SanderMuller packages use (for example `SanderMuller\FluentValidationRector`). Not fixed in repo-new itself.
- **PHP floor:** `^8.4` instead of `^8.3` (see Resolved Question 17).
- **Two Pest Rector packages:** the spec only knew `mrpunyapal/rector-pest`. `pestphp/pest-plugin-rector` is its official successor (same author, PHP `^8.4`, Pest 5), and Composer reports `mrpunyapal/rector-pest` as abandoned in its favour. 9 surveyed repos use the old one and 4 use the new one (dipcatch, productaivideo, laravel-model-stats, boost-pipeline). §5 now detects both.
- **Locked versions:** rector/rector 2.8.4, driftingly/rector-laravel 2.7.3, mrpunyapal/rector-pest 0.2.17, pestphp/pest-plugin-rector 5.0.6, hihaho/rector-rules 1.2.1, sandermuller/laravel-fluent-validation-rector 1.11.1.
- **Fixtures:** `tests/Fixtures/` is excluded from the package's own PHPStan, Pint and Rector runs. Pest does not scan it, because `phpunit.xml` lists only `tests/Unit` and `tests/Feature`.

### Phase 2

- **`InstalledVersions::getRootPackage()` is not reliable inside Rector.** rector/rector bundles its own Composer installation (`vendor/rector/rector/vendor`, root `rector/rector-src`, 43 packages). Herd's `dump.phar` adds a third one in this environment (159 packages, including `symfony/console`). `getRootPackage()` returns the first registered installation, so the result depends on the load order. In a real `vendor/bin/rector process` run, the project came first (checked with a probe config). When the project autoloader loaded before Rector's, it returned `rector/rector-src`. `InstalledVersions::isInstalled()` also searches every installation, so it would report Rector's and Herd's bundled packages as project dependencies. The new `Internal\ComposerProject` picks the installation whose root is, or requires, `sandermuller/rector-preset`. `ProjectRoot` and the Phase 4 detection use it. A test covers both load orders in a child process.
- **The container cache path is relative to the project root.** `containerCacheDirectory: '.cache/phpstan'` and `'./.cache/phpstan'` resolve against the root. An absolute path is kept as it is.
- **`withFluentCallNewLine()` is in the shared base**, because both presets turn it on (Resolved Question 11).
- **Test helper:** `tests/Support/BuilderInspector` reads the builder's private properties with reflection. The property names are those of rector/rector 2.8.4. A Rector minor bump can rename them, and the tests then fail on purpose.

### Phase 3

- **Structure:** `Preset` is a thin public wrapper. `Internal\PresetFactory` builds the preset from an `Internal\Profile` (the enum with the skip and rule lists), an `Internal\PreparedSets` value and an injected `ComposerProject` and `CpuCores`. The tests use the factory with a fake project.
- **Added rules are guarded too.** `withRules()` gets only rules whose class exists, the same as the skips.
- **Not proven in a unit test:** that `withTypeCoverageDocblockLevel()` works on `app()`. Rector checks the level against the sets when it applies the config, not in the builder. The Phase 5 boot tests cover this.

### Phase 4

- **Symfony detection uses `symfony/framework-bundle`, not `symfony/http-kernel`.** Every Laravel app installs `symfony/http-kernel` and `symfony/console`. Those markers would turn on the Symfony composer-based set in every app, and none of the surveyed apps turns it on. `doctrine/orm`, `twig/twig`, `phpunit/phpunit` and `laravel/framework` are the other markers.
- **Rector 2.8.4 has its own detection, which the preset does not use.** `withComposerBased()` without arguments uses `ComposerBasedTriggerPackages`. That list turns on Symfony for any of 50+ `symfony/*` components, Doctrine for `doctrine/collections`, and Laravel for `illuminate/support`. That is too broad for Laravel apps and wrong for Laravel packages (§5).
- **Path skips:** `.cache` is always skipped, because the preset creates the container cache directory under it.

### Phase 5

- **Boot tests** (`tests/Feature/BootTest.php`) copy a fixture to a temporary folder, write a `rector.php` that calls the preset, and run the real `vendor/bin/rector process --dry-run`. They check that Rector reports no errors, that `app()` never changes `database/migrations` or `bootstrap/cache`, that the fixture migration would change if it were scanned, that `withTypeCoverageDocblockLevel()` works on `app()` and is rejected on `package()` unless `typeDeclarationDocblocks: false` is passed, and that the README example boots.
- **Rector's exit code is 2 when a dry run finds changes**, 0 when it finds none. Config errors come back as JSON.
- **laravel/pao changes Rector's output** when it detects an AI agent: it replaces Rector's JSON with an agent format that reports config errors under `fatal_errors`. The boot tests read both formats.
- **Real incompatibility found with `prefer-lowest`:** rector-laravel 2.7.0 and 2.7.1 allow `rector/rector: ^2.7`, but their `LARAVEL_ARRAYACCESS_TO_METHOD_CALL` set uses `Rector\Transform\ValueObject\ArrayDimFetchToMethodCall`, which Rector 2.8 no longer ships. Rector then fails with "Class ... not found". rector-laravel 2.7.2 requires `^2.8` and ships its own rules. The package now declares `"conflict": {"driftingly/rector-laravel": "<2.7.2"}`, and its dev constraint is `^2.7.2`.
- **Deprecation noise with `prefer-lowest`:** old transitive packages (for example `symfony/translation`) print PHP 8.5 deprecations in child processes. The tests run child PHP processes with deprecations hidden and filter `Deprecated:` lines from Rector's worker output.
- **Test groups:** tests that reference an extension class are in the `extensions` group. The CI job without extensions runs `--exclude-group=extensions`, plus one test that runs only when rector-laravel is missing. The skip-health test is in the `skip-health` group, which the weekly workflow runs.
- **Verified locally, not on GitHub:** the full suite on the locked versions (80 pass, 1 skipped), without the five extensions (66 pass), and with `--prefer-lowest` (80 pass, 1 skipped; rector/rector 2.8.0, rector-laravel 2.7.2, hihaho/rector-rules 1.2.0). All of these ran on PHP 8.5.12, the only PHP version on this machine. The PHP 8.4 legs did not run.

- Local run of every CI matrix leg on the final tree (2026-11-11), each in a scratch copy with `composer update` for that leg and `CI=true`: PHP 8.4.27 prefer-lowest (Rector 2.8.0) 90 passed; PHP 8.4.27 prefer-stable (Rector 2.8.4) 90 passed; PHP 8.5.12 prefer-lowest (Rector 2.8.0) 90 passed; PHP 8.5.12 prefer-stable (Rector 2.8.4) 90 passed; PHP 8.4.27 without the 5 extensions with `--exclude-group=extensions`, 74 passed. The user then approved a commit and push to `main`. GitHub run 43049814007 on `c64ac64836f2ef2457e60b8da1b4fdc2821fdefd` passed all 5 jobs; pint-check, phpstan and rector-check passed too.

### Phase 6

- **README** follows the `readme` skill's comprehensive shape: install, usage, what the presets set up, detection, parameters, things to know, versioning.
- **Release notes** are in `rector-preset/internal/release-notes-2.8.0.md`. The first line has no sha yet: the package has no commit, and a sha must be read from the repo, not invented. Add it at the ready-to-tag handoff.

### Changes from the spec after repo-init 1.21 (found during Phase 7)

The local repo-init `main` was 64 commits behind `origin/main` when Phase 7 started. It was fast-forwarded. The untracked `AGENTS.md` collided with a newly tracked upstream file; the old copy is saved in the session scratchpad. The upstream `references/rector-config.md` (commit `76cac42`, 2026-10-28) is newer than the 27-repo survey and changed three things in the preset:

- **`earlyReturn` is removed as a parameter**, like `instanceOf`. Rector 2.8.4 marks the argument `@deprecated`, and `config/set/early-return.php` registers no rules. The same reasoning as Resolved Question 15 applies.
- **Two shared skips are added to both presets:** `TernaryToNullsafeCoalesceRector` (its output fails PHPStan's `nullsafe.neverNull`) and `ExplicitNullableObjectInstanceRector` (on a nullable enum, its rewrite lets `deadCode` delete reachable code). Both are active in Rector 2.8.4 (PHP 8.0 set and `CodeQualityLevel`) and not deprecated.
- **The PHPUnit composer-based set follows the test framework.** It turns on only when `phpunit/phpunit` is installed and `pestphp/pest` is not, because a Pest suite has no `TestCase` classes. That matches upstream. `composerBased` is now `?bool`: `null` (the default) means every installed framework in `app()` and PHPUnit only in `package()`. `true` means every framework, and `false` means none. The Laravel range concern of Resolved Question 12 still holds: `package()` does not turn on the Laravel set by itself.

Two upstream points were not taken over, because a user decision in this spec covers them:

- The upstream laravel-project stub scans all of `database/` (migrations included). Resolved Question 7 keeps migrations out.
- The upstream laravel-project stub turns on `codingStyle`, `privatization` and `typeDeclarationDocblocks`. The `app()` defaults stay as decided (§4.2). The Phase 7 stub passes them explicitly, so a new laravel-project keeps the same prepared sets. Its skip list becomes the `app()` list.

### Skips follow the sets (found during Phase 7)

- Rector prints "These skipped rules are never registered" on every run when a skipped rule is in no turned-on set (`MissConfigurationReporter::reportSkippedNeverRegisteredRules`, called from `ProcessCommand`). A repo that turned off `privatization` or `codeQuality` got this warning for the preset's own skips.
- Each skip now names the set that registers it (`Profile::skipSources()`), and `Profile::activeSkips()` keeps only the skips of turned-on sets. The rector-laravel skips need the detected rector-laravel sets. The PHP-version skips always stay, because the repo adds `withPhpSets()` after the preset and the preset cannot see it.
- Checked: `package()` with `privatization`, `codeQuality` and `deadCode` off and no PHP sets now warns only about `TernaryToNullsafeCoalesceRector` (expected, no PHP sets). The stub-shaped `package()` and `app()` configs with `withPhpSets(php84: true)` on both fixtures print no warning.

### Phase 7

- repo-init ships 9 `rector.php` stubs, not 8: the `laravel-package-spatie` variant has its own. All 9 now call the preset. The `laravel-project` stub calls `Preset::app(codingStyle: true, privatization: true, typeDeclarationDocblocks: true)`; the other 8 call `Preset::package()`. Each adds only `withPhpSets(php__PHP_VERSION_NEON__: true)`.
- `references/rector-config.md` now describes what the preset owns. It keeps the `laravel-project` reference skip list (six entries marked as already in `Preset::app()`), the hihaho configured-rule notes and the PHP set derivation. The per-stub `withComposerBased()` table and the test-framework flip are gone: the preset reads the installed test framework.
- Bootstrap phases: the test-framework variant step no longer edits `rector.php` (laravel-project, laravel-package, php-package). `with-hihaho-rules` no longer edits `rector.php`, because the preset detects `hihaho/rector-rules`.
- Audit phases (6 PHP categories): the shared dep checklist has `sandermuller/rector-preset: ~2.8.0`. A new MEDIUM finding flags a `rector.php` that does not use the preset; a repo on the preset skips the hand-written findings. Upgrade phases: a new section "Migrate `rector.php` to the preset (prompted)" runs after "Apply MISSING dev deps", so the preset is installed, on every test framework. It asks first (`rector.php` is notify-only) and lists what to keep and what to drop; extension sets the preset does not register, such as `FluentValidationSetList::SCHEMA`, stay. (Codex review moved it out of the Pest 4→5 section and added the extension-set rule.)
- `.github/scripts/check-rector-sync.py` checked the hand-written shape and failed on every new stub. It now checks the preset shape: only the `Preset` import, the preset call that the doc table names (arguments included), `withPhpSets(php__PHP_VERSION_NEON__: true)`, no call the preset owns, no deprecated argument, every expected stub present, and the dep listed in `per-category-deps.yml`. Five mutations in a scratch copy (wrong preset, an owned `withCache()`, a dropped `privatization` argument, a deleted stub, a removed dep line) each fail the check.
- Checks run: all integrity scripts (`check-layout`, `check-paths`, `check-phase-coverage`, `check-placeholders`, `check-merge-keys-coverage`, `check-audit-scoping`, `check-yaml-validity`, `check-stub-composer-validity`, `check-bootstrap-idempotency`, `check-dep-sync`, `check-rector-sync`) pass; `vendor/bin/pint --test` passes; markdownlint-cli2 0.18 on the changed docs reports 0 errors. Not run: `check-stub-drift.sh` (needs `GH_TOKEN` and clones other repos).
- Scaffold test: a scratch package with the `php-package` stub `rector.php`, the preset from a path repository and Pest 5 ran `vendor/bin/rector process --dry-run` with exit 0 and no warnings. The `laravel-project` stub was not scaffolded end to end (it needs `laravel new`); the preset's own boot test covers `Preset::app()` on a Laravel fixture.
- **Release order:** repo-init must not release these changes before `sandermuller/rector-preset` 2.8.0 is on Packagist. Until then, `composer require --dev sandermuller/rector-preset:~2.8.0` fails in every new scaffold.
- **Follow-up for repo-new** (not changed here): `LaravelProjectScaffolder::wireHihahoRules` looks for the hint comment the old stub had and will warn falsely. `TestFrameworkSwapper::setRectorComposerBased` edits `withComposerBased()`, which the stubs no longer have, so it becomes a no-op. Both need an update in repo-new before or with the repo-init release.

### Phase 8

Expected differences, written before the pilot runs.

boost-core (`Preset::package()`, on the same lock as the baseline):

- The container cache moves from `.cache/rectorContainer` to `.cache/phpstan`. No code diff.
- The paths stay `src` and `tests`: boost-core has no `config`, `workbench` or `bootstrap` folder.
- `instanceOf: true`, `earlyReturn: true` and the skips of `NullToStrictStringFuncCallArgRector`, `EncapsedStringsToSprintfRector` and `ExplicitBoolCompareRector` go. On Rector 2.8 they do nothing. No code diff.
- The two shared skips are added. The diff can only lose changes from `TernaryToNullsafeCoalesceRector` and `ExplicitNullableObjectInstanceRector`.
- The Pest sets stay `PEST_CODE_QUALITY` and `PEST_CHAIN`: `pestphp/pest-plugin-laravel` is not installed, so no `PEST_LARAVEL`.
- No composer-based set: Pest is installed, and `package()` does not turn on Laravel. Today there is no `withComposerBased()` call either.
- `carbon` stays on, because `nesbot/carbon` is installed.
- The project keeps `withPhpSets(php82: true)` and its own skips `TimeFuncCallToCarbonRector => [src]` and `UseToBeDirectoryRector`.
- Expected result: the same per-file rule list as the baseline, minus any hit of the two shared skips.

hihaho (`Preset::app()`, worktree of `origin/develop` at `c53a2cbac5e615d211b91c611d2d87112ea9e8f7`; it already locks Rector 2.8.4, rector-laravel 2.7.3 and hihaho/rector-rules 1.2.0, so no Rector upgrade mixes in):

- hihaho scans `database/migrations` today. The preset never does (Resolved Question 7). Migration files leave the diff.
- hihaho does not call `withFluentCallNewLine()` today. The preset turns it on, so fluent chains in many files gain new lines.
- The other paths, `bootstrap/cache` and `.cache` skips, the container cache in `.cache/phpstan`, `withComposerBased(phpunit, laravel)`, the five Laravel sets, `HihahoSetList::ALL`, `FluentValidationSetList::ALL/POLISH/SIMPLIFY`, `carbon`, and the rules `PreferPHPUnitSelfCallRector` and `PrivatizeFinalClassPropertyRector` match the preset. No diff from these.
- `earlyReturn: true` goes (no-op on 2.8). Parallel reserves 2 cores locally instead of 4. No code diff.
- The project keeps: its configured rules, its own skips (the `app()` list is a subset of hihaho's), `withTypeCoverageDocblockLevel(2)`, `withPhpSets(php85: true)` and `FluentValidationSetList::SCHEMA` (opt-in in the preset).
- Check: a migrated config that also passes `withFluentCallNewLine(false)` and re-adds `database/migrations` with `withPaths()` gives the same diff as the baseline. The pure migrated config differs only by migration files and fluent new lines.

Results. Both pilots ran in scratchpad worktrees with the preset from a path repository. Nothing was committed, and the user's checkouts were not changed.

- boost-core (worktree of `243abbf5fc56052bbecb18e57dc9630df06f5645`, same lock as the baseline, Rector 2.8.3): the baseline and the migrated config both change the same 7 files with `SimplifyQuoteEscapeRector`, and the diff text is identical. `rector list-rules` gives 511 rules for the baseline and 509 for the preset. The two missing rules are `ExplicitNullableObjectInstanceRector` and `TernaryToNullsafeCoalesceRector`, the two shared skips. The console run prints no warning. The migrated `rector.php` is 16 lines instead of 65.
- hihaho (worktree of `origin/develop`, Rector 2.8.4): the baseline, the migrated config, and the migrated config with migrations and `withFluentCallNewLine(false)` all report 0 changes and 0 errors on the current tree. `rector list-rules` gives 576 rules for the baseline and the same 576 for the migrated config. The console run prints no warning. The migrated `rector.php` is 278 lines instead of 373: the configured rules and the project skips stay.
- Fluent new lines did not change any file in hihaho. Rector applies them only to nodes it prints again, so they show up only together with another change.
- No difference called for a preset fix.

Found on the way:

- **The baseline boost-core config fails on a fresh checkout**: `The path "./.cache/rectorContainer" is not a directory.` The preset creates its cache directory, so the migrated config does not have this problem.
- **Rector reads `vendor/composer/installed.json` from the working directory.** Run from another directory with `--config`, both the baseline and the preset config fail every file with "The installed package json not found". This is Rector's behaviour, not the preset's. Run Rector from the project root.
- **PHP floor blocks part of the rollout.** The preset requires `php: ^8.4`. Composer refuses to install it on a PHP 8.3 CI leg. 13 local repos that use Rector still have a floor below 8.4 (boost-core, package-boost-php, project-boost-laravel, laravel-fluent-validation, -rector and -phpstan, laravel-queue-insights, laravel-ai, laravel-ai-qore, qore, phpstan-rules, rector-rules, Stopwatch; local checkouts, some may be stale). See Resolved Question 19.
- **Extension constants are now guarded.** The preset does not constrain extension versions, so an older release can have a set list class without one of the constants the preset reads. `Detection::constants()` reads each constant only when `defined()`, and leaves a missing one out instead of failing the config. Test: `DetectionTest` "leaves out a set constant that an older extension release does not have".

### Final verification

- PHPStan ran for the first time and found 108 errors. 93 were tests that use the package's `@internal` classes: Pest test files have no namespace, so PHPStan counts them as outside the `SanderMuller` root namespace. `phpstan.neon.dist` now ignores those 8 identifiers in `tests/*` only.
- Fixed in `src/`: `Profile::rules()` returns `list<class-string<RectorInterface>>`, which `withRules()` needs. The `shell_exec()` in `CpuCores` keeps an inline ignore with its reason (fixed command, no user input). `Detection::constants()` takes a plain string, because it checks `class_exists()` itself.
- Fixed in tests: typed helper parameters instead of `mixed ...$options`, narrowed `mixed` values, and an inline ignore where a test checks that deprecated set constants stay off.
- `CacheDirectory::ensure()` used `@mkdir`, and PHPUnit still reported the suppressed "Not a directory" warning. It now uses a scoped error handler.
- Gates on the current tree: Pest 87 passed (194 assertions) on PHP 8.5.12 and on PHP 8.4 (Herd); PHPStan `[OK] No errors`; Pint passed; Rector dry-run on the package `[OK] Rector is done!`. repo-init `check-rector-sync` and `check-dep-sync` pass again; the scaffold test runs with no warning.
- Codex review: the package body was reviewed in a scratch copy, because the initial commit `f553f88` (not made by this session) holds it. Round 1 found that `workbench` scanning reached `workbench/database/migrations`; the preset now skips that folder by exact path (a glob would also block a project that adds root migrations back on purpose). Round 2 was clean. repo-init needed 3 rounds: the migration step moved out of the Pest 4→5 section, and it now keeps extension sets the preset does not register. Round 3 was clean.
- After the last clean rounds, only this spec file changed.
- Final gates: Pest 90 passed (197 assertions) on PHP 8.5.12 and on PHP 8.4; PHPStan, Pint and the Rector dry-run clean; all 11 repo-init integrity scripts exit 0.

### Phase 9

The user tagged `v2.8.0` on `c64ac64836f2ef2457e60b8da1b4fdc2821fdefd` and Packagist serves it. The user chose all three repo groups and the title `chore: use sandermuller/rector-preset`. The 13 repos that allow PHP 8.3 stay out (Resolved Question 19).

Method, per repo: a scratchpad worktree of the default branch, the old config on the current lock, the old config on the upgraded lock where Rector had to move, then the preset config. Comparison: `rector list-rules` sets, the JSON dry-run diff per file, and one console run for warnings. The lock change adds only the preset, unless the table says more. Org repos keep their behaviour: where the preset would change paths, fluent new lines or import names, the config keeps the old value and the PR says so.

| Repo | Result | Rules before → after | Dry-run | CI |
|---|---|---|---|---|
| boost-pipeline | PR SanderMuller/boost-pipeline#9 | 543 → 546 (+5 `LARAVEL_COLLECTION`, −2 shared skips) | same 33 files | all green except `rector-check`: 33 changes from `UnlinkFuncCallToFileFacadeDeleteRector` already pending on `main` |
| phpstan-to-mago | PR SanderMuller/phpstan-to-mago#21 | 510 → 508 (−2 shared skips) | same 12 files | phpstan, tests, pint and rector-check red; the same failures are on the open Dependabot PR or in unchanged files |
| richter | PR SanderMuller/richter#9 | 525 → 525 | none | all green |
| laravel-model-stats (GitHub: census) | PR SanderMuller/census#1 | 489 → 527 (+5 `LARAVEL_COLLECTION`, +33 PHPUnit composer-based, −2) | same 7 files | phpstan red: the old config gives the same errors on the same dependencies; rector-check red on 7 pending changes |
| repo-new | PR SanderMuller/repo-new#7 | 517 → 515 (−2) | same 1 file | phpstan red: the old config gives the same 3 errors; rector-check red on 1 pending change |
| hihaho | PR hihaho/hihaho#11839 | 576 → 576 | none | all green except `security/snyk`, which fails only on this PR (details on app.snyk.io, not checked) |
| mijntp | PR blinqx-vh/mijntp#6637 | 609 → 609 | none | all green |
| blinqx-shared-services | PR blinqx-vh/blinqx-shared-services#476 | 445 → 486 (+attribute sets, +PHPUnit composer-based, −`TernaryToNullsafeCoalesceRector`) | none | all green |
| 123metpensioen | left out | — | 5 files change | The preset turns on `HihahoSetList::ALL`; the repo uses single hihaho rules only. `AliasImportRector` then changes 5 files. Needs a preset opt-out per extension, or the user accepts the changes. Also: `master` crashes on Rector today (rector-laravel 2.6.2 on Rector 2.8.3). |
| dipcatch, collectiq, rivalbyte | left out | — | — | Rector 2.8 needs PHPStan ≥ 2.3.5, and their hihaho/rector-rules 0.x crashes on Rector 2.8 (`Skipper::shouldSkipElementAndFilePath()`). Needs a dependency-upgrade PR first. |
| finconnect | left out | — | 1,283 files | The Rector and rector-laravel upgrade alone changes 1,283 files with the old config. |
| productaivideo | left out | 597 → 595 | none | Every Rector 2.8 patch needs PHPStan 2.3; that upgrade adds 2 PHPStan errors (5 → 7). |
| dev-null.sh | waits | — | — | `laravel/vet` `minimum-release-age` is 1 day, so Composer skips v2.8.0 until 2026-11-12. |

Preset issue found: hihaho/rector-rules 1.2.0 `AliasImportRector` uses `Rector\PhpDocParser\PhpDocParser\PhpDocNodeTraverser`, which Rector 2.8 does not have; 1.2.1 fixes it. The user committed the fix as `4f2104b` on rector-preset `main`: it adds `"hihaho/rector-rules": "<1.2.1"` to `conflict` and raises the dev constraint to `^1.2.1`. It ships in 2.8.1 when the user tags it.

### After Phase 9

- `withoutSets` (rector-preset `3c09584c2aee8321836a2f0df161603bf8d3078c`, unreleased, for 2.8.1): `Preset::app()` and `Preset::package()` take a list of detected extension sets to leave out, for example `withoutSets: [HihahoSetList::ALL]` for 123metpensioen. A set the preset did not detect throws an `InvalidArgumentException`. Each rector-laravel skip now follows the set that registers its rule: `ApplyDefaultInsteadOfNullCoalesceRector` follows `LARAVEL_CODE_QUALITY`, and `ReplaceServiceContainerCallArgRector` follows `LARAVEL_CONTAINER_STRING_TO_FULLY_QUALIFIED_NAME`. Tests: 95 passed; the 4 new detection tests fail without the change. The upgrade phases and `rector-config.md` now say when to pass `withoutSets`. 123metpensioen still needs a rector-laravel upgrade (2.6.2 is below the preset's 2.7.2 minimum) and a fix for its current Rector crash before it can migrate.
- Sweep of the 8 PR branches: a fresh worktree and install per branch, then a Rector dry-run and a PHPStan run with `error_reporting=-1`. Rector: no warnings on any PR branch; the four packages with pending changes change the same files with the same code on the base branch. PHPStan: no errors in richter, boost-pipeline, hihaho, mijntp and blinqx-shared-services; phpstan-to-mago (64), census (15) and repo-new (3) report the same errors on the base branch. hihaho and mijntp need `.env.ci` copied to `.env`, as their CI does, and more than 7 GB for PHPStan with its workers.
- The only deprecation notice: PHPStan's `The "type_coverage.declare" parameter is deprecated and has no effect` in blinqx-shared-services, boost-pipeline, census, phpstan-to-mago and repo-new. It comes from each repo's own config, not from the PRs. A second commit on each PR removes the setting; PHPStan then prints no notice and reports the same errors. The repo-init stubs do not set `declare`.
- mijntp has a post-checkout hook that runs `composer run refresh` (`composer install`, then `artisan migrate`) in the background. Create mijntp worktrees with `git -c core.hooksPath=/dev/null worktree add`.
