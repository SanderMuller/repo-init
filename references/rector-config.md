# Rector config

The `rector.php` shape per category.

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
    ->withImportNames()
    ->withFluentCallNewLine()
    ->withParallel(300, 15, 15)
    ->withMemoryLimit('3G')
    ->withPhpSets(php83: true) // or php84/php85 per --php=
    ->withPreparedSets(
        deadCode: true,
        codeQuality: true,
        codingStyle: true,
        typeDeclarations: true,
        typeDeclarationDocblocks: true,
        privatization: true,
        instanceOf: true,
        earlyReturn: true,
    );
```

## Per-category `withPaths` and `withSets`

| Category | `withPaths` | Extra `withSets` |
|---|---|---|
| `laravel-project` | `app, routes, config, database, tests` | `LaravelSetList::LARAVEL_{XXX}`, `LARAVEL_CODE_QUALITY`, `LARAVEL_FACADE_ALIASES_TO_FULL_NAMES` + `Hihaho\RectorRules\Sets::ALL` when `--with-hihaho-rules` + `PestSetList::*` when test-framework=pest |
| `laravel-package` | `src, tests, workbench` | `LaravelSetList::LARAVEL_{XXX}`, `LARAVEL_CODE_QUALITY`, `LARAVEL_FACADE_ALIASES_TO_FULL_NAMES` + `PestSetList::*` when test-framework=pest |
| `php-package` | `src, tests` | `PestSetList::*` when test-framework=pest |
| `phpstan-extension` | `src, tests` | (none) |
| `rector-extension` | `src, tests, config` | (none) |

## Common `withSkip` defaults

Across the canonical reference repos these rules are skipped by default — too noisy or break legitimate patterns:

```php
->withSkip([
    \Rector\Carbon\Rector\FuncCall\DateFuncCallToCarbonRector::class,
    \Rector\Php81\Rector\FuncCall\NullToStrictStringFuncCallArgRector::class,
    \Rector\TypeDeclaration\Rector\ArrowFunction\AddArrowFunctionReturnTypeRector::class,
    \Rector\CodingStyle\Rector\Encapsed\EncapsedStringsToSprintfRector::class,
    \Rector\CodeQuality\Rector\If_\ExplicitBoolCompareRector::class,
    \Rector\CodeQuality\Rector\ClassMethod\InlineArrayReturnAssignRector::class,
    \Rector\Privatization\Rector\ClassMethod\PrivatizeFinalClassMethodRector::class,
    \Rector\DeadCode\Rector\ClassMethod\RemoveUselessParamTagRector::class,
    \Rector\DeadCode\Rector\ClassMethod\RemoveUselessReturnTagRector::class,
])
```

Phase file allows the agent to ask the user whether to keep this skip list as-is or trim it.

## Rector-extension-specific note

The rector-extension category gets `withPaths([__DIR__ . '/src', __DIR__ . '/tests', __DIR__ . '/config'])` — `config/` is included because the rector extension's own `config/config.php` is non-trivial PHP that benefits from refactoring rules.

## PHP set name derivation

`__PHP_VERSION__` (e.g. `^8.3`) → `php83` (the rector set name). The agent reads `--php=` and writes `withPhpSets(php83: true)` accordingly.
