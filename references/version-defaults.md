# Version defaults

Per-knob defaults for bootstrap mode, plus the hard floors that audit enforces.

## PHP

- **Default**: `^8.3`
- **Accepted**: `8.3`, `8.4`, `8.5`
- **Hard floor**: `^8.3` (rejected: `^8.2` and below)

Rationale: matches `laravel/pao`'s `^8.3` floor (our strictest shared dep). Existing `^8.2` repos audited by repo-init are flagged as `NON-CANONICAL` on the `require.php` constraint; the upgrade phase offers to bump the floor as a single composer.json edit.

## Laravel (laravel-package only)

- **Default**: `^11.0||^12.0||^13.0`
- **Other accepted**: `^12.0||^13.0`, `^13.0`

Rationale: matches the range across canonical sander L-packages (queue-insights, fluent-validation, stopwatch). New packages should support all three Laravel majors unless there's a specific reason not to.

`laravel-project` doesn't use this knob — Laravel version is whatever `laravel new` installs (current `^13.0`).

## Pest

- **Floor**: `^4.0` (resolved via RQ17)
- **Bundled stub `tests/Pest.php`** uses Pest 4 idioms.

If the user is upgrading a Pest 3 codebase, the audit flags `pestphp/pest: ^3.0` as `NON-CANONICAL` and the upgrade phase offers to bump the constraint plus run `vendor/bin/pest --init` to migrate any 3→4 syntax. Pest 3 maintenance support is short; bumping is the recommended path.

## PHPUnit

When `test-framework=phpunit`:

- **Floor**: `^11.0||^12.0` for most categories.
- `phpstan-extension` uses `^11.0||^12.0` (canonical for phpstan extension tests).

## Test-framework default per vendor

- vendor `sandermuller` → `pest`
- vendor `hihaho` → `phpunit`
- `phpstan-extension` → always `phpunit` (canonical for phpstan rule testing)

See `pest-vs-phpunit.md` for full rationale.

## Stable / dev minimum

- `minimum-stability: stable`
- `prefer-stable: true`

`composer.json` includes both. Exception: very-early-stage packages may opt into `dev` with `minimum-stability: dev` + `prefer-stable: true`. Phase file asks if the user wants this for v0.x packages.

## Composer plugin allowlist

Stub `composer.json` declares the allowlist explicitly:

```json
{
  "config": {
    "allow-plugins": {
      "pestphp/pest-plugin": true,
      "phpstan/extension-installer": true
    },
    "sort-packages": true
  }
}
```

`rector-extension` adds `"rector/extension-installer": true`.

`phpunit/phpunit` doesn't ship a Composer plugin, so no entry for that.
