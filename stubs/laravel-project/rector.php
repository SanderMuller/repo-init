<?php declare(strict_types=1);

use Pest\Rector\Set\PestSetList;
use Rector\Caching\ValueObject\Storage\FileCacheStorage;
use Rector\CodeQuality\Rector\ClassMethod\InlineArrayReturnAssignRector;
use Rector\CodeQuality\Rector\If_\ExplicitNullableObjectInstanceRector;
use Rector\Config\RectorConfig;
use Rector\DeadCode\Rector\ClassMethod\RemoveUselessParamTagRector;
use Rector\DeadCode\Rector\ClassMethod\RemoveUselessReturnTagRector;
use Rector\Php80\Rector\Ternary\TernaryToNullsafeCoalesceRector;
use Rector\Privatization\Rector\ClassMethod\PrivatizeFinalClassMethodRector;
use Rector\TypeDeclaration\Rector\ArrowFunction\AddArrowFunctionReturnTypeRector;
use RectorLaravel\Set\LaravelSetList;

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
    ->withPaths([
        __DIR__ . '/app',
        __DIR__ . '/routes',
        __DIR__ . '/config',
        __DIR__ . '/database',
        __DIR__ . '/tests',
    ])
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
    ->withComposerBased(
        phpunit: true,
        laravel: true,
    )
    ->withAttributesSets()
    ->withImportNames()
    ->withFluentCallNewLine()
    ->withParallel(300, 15, 15)
    ->withMemoryLimit('3G')
    ->withPhpSets(php__PHP_VERSION_NEON__: true)
    ->withSets(array_merge(
        [
            LaravelSetList::LARAVEL_CODE_QUALITY,
            LaravelSetList::LARAVEL_ARRAYACCESS_TO_METHOD_CALL,
            LaravelSetList::LARAVEL_COLLECTION,
            LaravelSetList::LARAVEL_CONTAINER_STRING_TO_FULLY_QUALIFIED_NAME,
            LaravelSetList::LARAVEL_FACADE_ALIASES_TO_FULL_NAMES,
            // With --with-hihaho-rules, add HihahoSetList::ALL here. ALL does not
            // cover every rule in the package — see references/rector-config.md.
        ],
        class_exists(PestSetList::class) ? [
            PestSetList::CODING_STYLE,
        ] : [],
    ))
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
    ]);
