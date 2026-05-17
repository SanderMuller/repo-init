# Composer scripts

Exact scripts block per category. Phase files write these into the target's `composer.json` `scripts` key. Upgrade phases patch in missing entries via the `merge-keys` mode (`upgrade-merge-modes.md`).

## Always present (every category)

```json
{
  "scripts": {
    "phpstan": "vendor/bin/phpstan analyse --memory-limit=2G",
    "phpstan-simplified": "vendor/bin/phpstan analyse --memory-limit=2G --error-format symplify",
    "phpstan-clear-cache": "vendor/bin/phpstan clear-result-cache",
    "format": "vendor/bin/pint",
    "rector": "vendor/bin/rector process",
    "test": "vendor/bin/pest",
    "test-coverage": "vendor/bin/pest --coverage",
    "sync-ai": "vendor/bin/testbench package-boost:sync",
    "qa": ["@rector", "@format", "@phpstan-simplified"],
    "post-install-cmd": [
      "if [ \"$COMPOSER_DEV_MODE\" = \"1\" ]; then vendor/bin/testbench package-boost:sync 2>/dev/null || true; fi"
    ]
  }
}
```

## Substitutions

### `test-framework=phpunit`

- `"test": "vendor/bin/phpunit"`
- `"test-coverage": "vendor/bin/phpunit --coverage-html=coverage"`

### `laravel-project`

- `"sync-ai": "@php artisan package-boost:sync"` (artisan is available; no testbench wrapper needed in a real Laravel app).

## Always added for `laravel-package`

The workbench scripts. Per RQ13/RQ39, these are unconditional for the laravel-package category — every canonical sander L-package has them.

```json
{
  "scripts": {
    "post-autoload-dump": ["@clear", "@prepare"],
    "clear": "@php vendor/bin/testbench package:purge-skeleton --ansi",
    "prepare": "@php vendor/bin/testbench package:discover --ansi",
    "build": "@php vendor/bin/testbench workbench:build --ansi",
    "serve": [
      "Composer\\Config::disableProcessTimeout",
      "@build",
      "@php vendor/bin/testbench serve --ansi"
    ]
  }
}
```

Note: `post-autoload-dump` is an array — Composer runs each entry in order. If the target's existing `composer.json` already has a different `post-autoload-dump` (e.g. a `laravel-project` running `package:discover` already from the laravel skeleton), the upgrade phase prompts before merging.

## Always added for `php-package`

```json
{
  "scripts": {
    "validate-gitattributes": "vendor/bin/lean-package-validator validate"
  }
}
```

Add `@validate-gitattributes` to the `qa` chain.

## Conditional additions

### When opt-in `--with-hihaho-rules` (laravel-project)

No script additions — the rule packs auto-register via `phpstan/extension-installer` and Rector's set discovery.

### When opt-in `--with-security-advisories` (laravel-project)

No script additions — the `roave/security-advisories` package blocks installation of vulnerable deps automatically.

## Merge semantics

- New target (bootstrap): write the full scripts block as composed above.
- Existing target (upgrade): use `merge-keys` mode — insert only the keys we own that are missing. Don't reorder or remove existing scripts. Don't override existing scripts with the same name (prompt the user if there's a conflict).
