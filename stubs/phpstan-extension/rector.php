<?php declare(strict_types=1);

use SanderMuller\RectorPreset\Preset;

// sandermuller/rector-preset configures paths, cache, sets and skips. Add only your
// own rules and skips. withPaths() and withCache() replace the preset's values;
// turn a prepared set off with a preset parameter. See
// vendor/sandermuller/rector-preset/README.md.
return Preset::package()
    ->withPhpSets(php__PHP_VERSION_NEON__: true);
