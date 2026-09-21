# Version defaults

Per-knob defaults for bootstrap mode, plus the hard floors that audit enforces.

## PHP

Two floors, by what the repo is:

| Kind | Categories | Floor |
|---|---|---|
| Application | `laravel-project` | the newest stable PHP — **`^8.5`** today |
| Package / plugin | every other category | **`^8.4`** |

- **Accepted `--php=`**: `8.5` only for `laravel-project` — an application takes the newest stable PHP, so there is nothing to choose. A package category defaults to `8.4` and may opt up to `8.5` when its consumers allow it. `8.3` and below are rejected everywhere.
- **Hard floor**: `^8.4`.

An application runs on one interpreter the team controls, so it takes the newest
stable PHP and gets its language features immediately. A package runs on whatever
its consumers have, so it floors one minor lower and keeps a wider install base.

Both floors shift together, one minor apart. When PHP 8.6 goes stable,
`laravel-project` moves to `^8.6`, the package floor moves to `^8.5`, and
`--php=` accepts `8.5` and `8.6`.

The `^8.4` floor is what lets the canon carry NO abandoned packages. Both
`symplify/phpstan-extensions` and `rector/type-perfect` existed in earlier canon
only to serve a `^8.3` floor; their successors (`symplify/phpstan-rules ^14.12`,
`tomasvotruba/type-coverage ^2.3`) each require PHP `^8.4`. See
`shared-dev-deps.md` → "Symplify formatter dep" and "Type-perfect dep".

A repo below the floor is flagged NON-CANONICAL on its `require.php` constraint;
the upgrade phase offers the bump as a single `composer.json` edit, which also
drops the abandoned pair.

## Laravel (laravel-package only)

- **Default**: `^12.0||^13.0`
- **Other accepted**: `^13.0`

Rationale: Laravel 11 was the previous floor but was dropped in repo-init 0.3.0 because `laravel/pao` 1.0.5+ conflicts with `laravel/framework: <12.0.0`. New packages should support the two current Laravel majors unless there's a specific reason not to.

`laravel-project` doesn't use this knob — Laravel version is whatever `laravel new` installs (current `^13.0`).

With `--test-framework=pest`, `require-dev` takes `orchestra/testbench: ^11.0` and CI tests Laravel 13 only — Pest 5 and testbench 10 cannot install together (`symfony/process` ^8.1 against ^7.2). The `require` range still allows Laravel 12. See `pest-vs-phpunit.md` → "Pest 5 and orchestra/testbench".

## Pest

- **Floor**: `^5.0`
- **Requires**: PHP `^8.4` and PHPUnit 13 (Pest 5 builds on `phpunit/phpunit: ^13.3`)
- **Plugins** (all `^5.0`): `pestphp/pest-plugin-arch`, `pestphp/pest-plugin-rector`, `pestphp/pest-plugin-phpstan`, `pestphp/pest-plugin-agent`, plus `pestphp/pest-plugin-laravel` for Laravel categories
- **Bundled stub `tests/Pest.php`** uses Pest 5 idioms and turns on the Tia engine with `pest()->tia()->locally()`.
- **Runtime note**: PHPUnit 13 requires PHP `>= 8.4.1`. A `require.php: ^8.4` constraint still accepts 8.4.0, where the install fails. Use PHP 8.4.1 or later on developer machines and CI runners; `shivammathur/setup-php` with `php-version: '8.4'` gives the newest 8.4.x, so the stub matrix is fine.

`pestphp/pest-plugin-rector` is first-party and replaces `mrpunyapal/rector-pest`. Its one set is `Pest\Rector\Set\PestSetList::CODING_STYLE` — see `rector-config.md`.

`stolt/lean-package-validator` only allows PHPUnit 13 from **6.0.1** — it widened `sebastian/diff` to `^8||^9`, and 6.0.0 still caps it at `^7`. This is what unblocked Pest 5 for the validator-carrying categories. Composer still resolves a `^6.0` constraint correctly, `--prefer-lowest` included: 6.0.0 is unsatisfiable next to PHPUnit 13, so it backtracks to 6.0.1 (verified with `composer update --dry-run --prefer-lowest`). The `php-package` and `composer-plugin` stubs ship `^6.0.1` anyway, because that is the real floor. `skill-bundle` has no test runner, so it stays on `^6.0`. Audit: a `^6.0` constraint on a Pest repo is a LOW-severity tightening, not a breakage.

### Tia engine (test impact analysis)

Tia re-runs only the tests that your last change touched. Canonical setup:

- `tests/Pest.php` calls `pest()->tia()->locally()` — Tia is active on developer machines and off in CI.
- CI runs the full suite. Pest's own documentation says not to add `--tia` to the CI test command, so the stub `run-tests.yml` keeps `vendor/bin/pest --ci`.
- Tia needs a coverage driver (PCOV or Xdebug) for the first, recording run. Without a driver Pest prints a warning and runs the full suite.
- Tia needs a git repository with **at least one commit**. Verified against Pest 5: a repo with no commits aborts the run (`The feature "Tia mode" requires "git"`); a repo with one commit and no remote runs fine. So run the suite after the scaffold's initial commit, or pass `--no-tia`.
- `locally()` turns Tia off when the run carries `--ci` (that is the switch — not CI-environment detection). The stub `run-tests.yml` runs `vendor/bin/pest --ci`, so CI keeps the full suite.
- It stores the graph in `~/.pest/tia/<project-key>/`, outside the repo, so `.gitignore` needs no entry.

### Migrating an existing Pest codebase

- **Pest 4 → 5**: audit flags `pestphp/pest: ^4.0` as `NON-CANONICAL`. The upgrade phase raises `pestphp/pest` and every `pestphp/*` plugin to `^5.0`, bumps `require.php` to `^8.4`, drops `mrpunyapal/rector-pest` for `pestphp/pest-plugin-rector`, and applies the PHP ≥ 8.4 dep set (see `shared-dev-deps.md`). Pest 5 carries PHPUnit 13's breaking changes; a suite that uses deprecated PHPUnit APIs needs a manual pass.
- **Pest 3 → 5**: bump to `^4.0` and run `vendor/bin/pest --init` first, then take the 4 → 5 step above.

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
