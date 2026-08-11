# Version defaults

Per-knob defaults for bootstrap mode, plus the hard floors that audit enforces.

## PHP

- **Default**: `^8.3`
- **Accepted**: `8.3`, `8.4`, `8.5`
- **Hard floor**: `^8.3` (rejected: `^8.2` and below)

Rationale: matches `laravel/pao`'s `^8.3` floor (our strictest shared dep). Existing `^8.2` repos audited by repo-init are flagged as `NON-CANONICAL` on the `require.php` constraint; the upgrade phase offers to bump the floor as a single composer.json edit.

Note: a `^8.3` floor keeps the repo on **two** abandoned packages:

- `symplify/phpstan-extensions` — its successor `symplify/phpstan-rules: ^14.12` requires PHP ^8.4. See `shared-dev-deps.md` → "Symplify formatter dep".
- `rector/type-perfect` — its successor `tomasvotruba/type-coverage: ^2.3` requires PHP ^8.4. The 8.3 floor also has to cap `tomasvotruba/type-coverage` at `>=2.2.0 <2.2.2`, because 2.3 and type-perfect can't coexist. See `shared-dev-deps.md` → "Type-perfect dep".

Bumping the floor to `^8.4` is the way to drop both abandoned packages (and the type-coverage cap).

## Laravel (laravel-package only)

- **Default**: `^12.0||^13.0`
- **Other accepted**: `^13.0`

Rationale: Laravel 11 was the previous floor but was dropped in repo-init 0.3.0 because `laravel/pao` 1.0.5+ conflicts with `laravel/framework: <12.0.0`. New packages should support the two current Laravel majors unless there's a specific reason not to.

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

`composer.json` includes both — `stable` is the default and the expected value at every release. A looser `minimum-stability` (`dev` + `prefer-stable: true`) is a **justified exception, not a default**: legitimate only while a package is actively co-developed against UNRELEASED sibling packages, and only when the author deliberately opts in. Being on `0.x` does not by itself justify `dev`; a package with downstream / production dependents should lean `stable`, because `prefer-stable` narrows but does not remove the risk of resolving unreleased code into a tagged release. The audit's default recommendation is to tighten to `stable` unless the author confirms an active co-development reason to keep `dev`.

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
