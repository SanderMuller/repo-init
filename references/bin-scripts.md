# `bin` scripts in pure-PHP packages

When and how a `php-package` should ship one or more executable scripts via Composer's `bin` mechanism. Bootstrap doesn't add a `bin/` by default; this reference is for the agent to consult when scaffolding a CLI-shaped pure-PHP package.

## What it is

Composer's `bin` field in `composer.json` declares scripts that should be symlinked into the consumer's `vendor/bin/`. Example:

```json
{
  "bin": [
    "bin/mytool"
  ]
}
```

After `composer require vendor/package`, the consumer can run `vendor/bin/mytool` directly.

## When to add it

- The package's primary deliverable is a command-line tool (e.g. `sandermuller/php-x402` ships `bin/x402`).
- A linter, scaffolder, validator, or migration tool consumers run from the shell.
- An entry-point script that boots the package's library code with default config.

## When NOT to add it

- Library-only packages — consumers use your classes from PHP, not from the shell.
- Tools that NEED a Laravel app context — those belong in `laravel-package` as artisan commands, not `php-package` bins.
- Scripts that depend on the consumer's working directory in non-portable ways.

## Stub shape

A typical `bin/` script for a pure-PHP package:

```php
#!/usr/bin/env php
<?php declare(strict_types=1);

// Find the consumer's autoload — works both when running standalone
// (vendor/bin/mytool) and when running from within a clone (bin/mytool).
$autoloadPaths = [
    __DIR__ . '/../vendor/autoload.php',           // running from clone
    __DIR__ . '/../../../autoload.php',            // running from vendor/bin/ in consumer
];

foreach ($autoloadPaths as $path) {
    if (file_exists($path)) {
        require $path;
        break;
    }
}

use __NAMESPACE__\Cli\Application;

exit((new Application())->run($argv));
```

The autoload-discovery dance is mandatory — symlinks in `vendor/bin/` resolve from the consumer's perspective.

## composer.json wiring

Add to your `composer.json`:

```json
{
  "bin": [
    "bin/mytool"
  ]
}
```

And ensure the script is executable in git:

```bash
chmod +x bin/mytool
git update-index --chmod=+x bin/mytool
```

The `.gitattributes` should NOT export-ignore `bin/` (consumers need it).

## Audit / upgrade behaviour in repo-init

- Audit phases for `php-package` do NOT flag `bin` as MISSING — it's opt-in per package.
- If the package's `composer.json` already has `bin: [...]`, audit treats it as `EXTRA` (informational, not a problem).
- Upgrade never adds or removes `bin/`.

## Observed pattern in sander packages

- `sandermuller/php-x402` ships `bin/x402`.
- Other sander packages do not.

## Phase 8 / v0.2

If repo-init eventually ships an interactive prompt at bootstrap time ("does this package ship a CLI tool?"), the agent will read this doc to scaffold the bin/ script + composer.json wiring. v0.1 keeps it manual.
