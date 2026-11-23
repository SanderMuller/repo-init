<?php declare(strict_types=1);

use Hihaho\RectorRules\Rector\CodeQuality\FirstPartyFlagArgumentToNamedRector;
use Hihaho\RectorRules\Rector\CodeQuality\NamedArgumentFromManifestRector;
use Hihaho\RectorRules\Rector\CodeQuality\NativeFunctionFlagArgumentToNamedRector;
use Hihaho\RectorRules\Rector\CodeQuality\RemoveDefaultValuedArgumentRector;
use Hihaho\RectorRules\Rector\Routing\MiddlewareStringToClassRector;
use Hihaho\RectorRules\Rector\Testing\TestFieldStringToConstantRector;
use Illuminate\Auth\Middleware\Authenticate;
use Illuminate\Routing\Middleware\ThrottleRequests;
use SanderMuller\FluentValidationRector\Set\FluentValidationSetList;
use SanderMuller\RectorPreset\Preset;

// sandermuller/rector-preset configures paths (never database/migrations), cache,
// sets and skips. Add only your own rules and skips. withPaths() and withCache()
// replace the preset's values; turn a prepared set off with a preset parameter.
// See vendor/sandermuller/rector-preset/README.md.

$firstPartyNamespaces = ['App\\', 'Database\\Factories\\', 'Tests\\'];

// Every route file, nested ones included, for TestFieldStringToConstantRector.
$routeFiles = [];

foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator(__DIR__ . '/routes', FilesystemIterator::SKIP_DOTS)) as $routeFile) {
    if ($routeFile->getExtension() === 'php') {
        $routeFiles[] = $routeFile->getPathname();
    }
}

sort($routeFiles);

return Preset::app(
    // app() defaults these three to false; a new project starts with them on.
    codingStyle: true,
    privatization: true,
    typeDeclarationDocblocks: true,
)
    // HihahoSetList::ALL registers the next three rules unconfigured.
    ->withConfiguredRule(FirstPartyFlagArgumentToNamedRector::class, [
        FirstPartyFlagArgumentToNamedRector::FIRST_PARTY_NAMESPACES => $firstPartyNamespaces,
        FirstPartyFlagArgumentToNamedRector::CASCADE_TRAILING_ARGS => true,
    ])
    ->withConfiguredRule(RemoveDefaultValuedArgumentRector::class, [
        RemoveDefaultValuedArgumentRector::FIRST_PARTY_NAMESPACES => $firstPartyNamespaces,
        RemoveDefaultValuedArgumentRector::CASCADE_DROP => true,
        // ThrottleRequests::with(60, 1) becomes the string 'throttle:60,1'. Dropping
        // an argument that equals its default changes that string.
        RemoveDefaultValuedArgumentRector::EXCLUDE_CALLS => [
            ThrottleRequests::class => ['with'],
        ],
    ])
    ->withConfiguredRule(NativeFunctionFlagArgumentToNamedRector::class, [
        NativeFunctionFlagArgumentToNamedRector::FUNCTION_FLAG_ARGUMENTS => [
            'in_array' => [2 => 'strict'],
            'array_search' => [2 => 'strict'],
            'json_decode' => [1 => 'associative'],
        ],
    ])
    // The next three rules are in no hihaho set.
    ->withConfiguredRule(MiddlewareStringToClassRector::class, [
        MiddlewareStringToClassRector::CONVERT_BARE_ALIASES => true,
        // `throttle` resolves to ThrottleRequests. When bootstrap/app.php calls
        // throttleWithRedis(), change the class to ThrottleRequestsWithRedis.
        MiddlewareStringToClassRector::INCLUDE_THROTTLE => true,
        MiddlewareStringToClassRector::THROTTLE_CLASS => ThrottleRequests::class,
    ])
    // Reads the manifest that PHPStan writes (namedArgumentManifest in
    // phpstan.neon.dist). Run PHPStan before Rector to refresh it.
    ->withConfiguredRule(NamedArgumentFromManifestRector::class, [
        NamedArgumentFromManifestRector::MANIFEST => __DIR__ . '/.config/named-arguments-manifest.json',
    ])
    // Test payload keys become FormRequest constants on internal routes, and
    // literals on public routes. A route is internal when one of these tokens is
    // in its middleware in the route files. List every alias form, for example
    // 'auth:sanctum'.
    ->withConfiguredRule(TestFieldStringToConstantRector::class, [
        TestFieldStringToConstantRector::ROUTE_FILES => $routeFiles,
        TestFieldStringToConstantRector::INTERNAL_MIDDLEWARE => ['auth', Authenticate::class],
        TestFieldStringToConstantRector::FIRST_PARTY_PREFIX => 'App\\',
    ])
    // The preset adds FluentValidationSetList::ALL, POLISH and SIMPLIFY. These two are opt-in.
    ->withSets([
        FluentValidationSetList::SCHEMA,
        FluentValidationSetList::VALIDATED_INPUT,
    ])
    ->withPhpSets(php__PHP_VERSION_NEON__: true);
