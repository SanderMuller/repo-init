# Composer scripts

Exact scripts block per category. Phase files write these into the target's `composer.json` `scripts` key. Upgrade phases patch in missing entries via the `merge-keys` mode (`upgrade-merge-modes.md`).

## Audit verification protocol (MANDATORY)

**The agent MUST check each script key line-by-line, not skim.** Real upgrades have shipped Windows-broken `post-install-cmd` and entirely missing `post-update-cmd` because the agent inferred the canonical block from training data instead of diffing against this doc. Mirrors the protocol in `shared-dev-deps.md#audit-verification-protocol-mandatory`.

Required protocol for the `## MISSING composer.json scripts` section of every code-bearing audit phase:

1. **Read the target's `composer.json` `scripts` block once.** Extract every key → value pair into a map.
2. **For each key in the canonical set for the detected category** (see per-category checklists below): explicitly state one of three verdicts —
   - **PRESENT** (key exists, value matches canonical)
   - **MISSING** (key absent)
   - **MISMATCH** (key exists, value differs from canonical) — quote both sides
3. **Print a verification line** in the audit report listing every MISSING / MISMATCH entry. If none, print "all N canonical script keys present and matching".
4. **Do NOT trust visual scanning.** If the canonical set has 12 keys and you only mentioned 6, you skipped half. 1 key = 1 explicit verdict.

The MISMATCH verdict is the load-bearing one. The common drift class is a `post-install-cmd` whose value is a POSIX-shell conditional referencing `vendor/bin/boost sync` (Windows-broken, predates boost-core 0.6's PHP callback). Audit and upgrade phases MUST treat MISMATCH the same severity as MISSING, prompting before overwrite.

## Per-category audit checklists

Each list is the exact expected key set after merging baseline + category-specific blocks. Use the matching list for the detected category as input to the protocol above.

**This reference is the source of truth.** The per-key checklists embedded in each audit phase file (`phases/audit-<category>.md` → `## MISSING composer.json scripts`) mirror these lists verbatim — intentionally, so the protocol can enforce a per-key verdict without indirection. If a canonical value changes, update this file FIRST, then propagate to all phase files that mirror it.

### `laravel-package` (16 keys)

Baseline 11: `phpstan`, `phpstan-simplified`, `phpstan-clear-cache`, `format`, `rector`, `test`, `test-coverage`, `sync-ai`, `qa`, `post-install-cmd`, `post-update-cmd`. Plus workbench block 5: `post-autoload-dump`, `clear`, `prepare`, `build`, `serve`.

### `php-package` (12 keys)

Baseline 11 + `validate-gitattributes`. The `qa` chain appends `@validate-gitattributes` (no new key — `qa` is already in the baseline).

### `phpstan-extension` (11 keys)

Baseline 11.

### `rector-extension` (11 keys)

Baseline 11. `qa` value differs from baseline: `["@rector", "@format", "@phpstan-simplified", "@test"]` (appends `@test` — rule tests are part of full QA).

### `composer-plugin` (11 keys)

Baseline 11 minus `sync-ai` (the stub omits it deliberately; `post-install-cmd` / `post-update-cmd` already trigger boost sync via the PHP callback), plus `validate-gitattributes`. The `qa` chain appends `@validate-gitattributes`.

### `laravel-project` (8 unconditional + 2 scaffold-conditional)

Baseline 11 minus `sync-ai`, minus the two BoostAutoSync hooks unless scaffold pulls `sandermuller/boost-core`.

- **Unconditional (8)**: `phpstan`, `phpstan-simplified`, `phpstan-clear-cache`, `format`, `rector`, `test`, `test-coverage`, `qa`.
- **Scaffold-conditional (2)**: `post-install-cmd`, `post-update-cmd` → `BoostAutoSync::run`. The callback lives in `sandermuller/boost-core`. A vanilla laravel-project carries `laravel/boost`, NOT boost-core — these two scripts are then NOT applicable (the callback won't autoload). Include only when boost-core is in the dependency tree.

No `sync-ai` script — `laravel/boost` owns AI-asset sync for applications (`php artisan boost:update`); there is no `vendor/bin/boost` here.

### `skill-bundle` (6 keys)

`post-install-cmd`, `post-update-cmd`, `format`, `validate-gitattributes`, `qa`, `qa-check`. Baseline does NOT apply.

### Canonical-value lookups

- `post-install-cmd` / `post-update-cmd`: array containing the **family-specific** auto-sync callback. The value forks by which boost package the category depends on directly — see the table below. Any POSIX-shell conditional (`if [ "$COMPOSER_DEV_MODE" = "1" ]; then …`) is MISMATCH — Windows-broken; predates boost-core 0.6. A callback that names the wrong namespace for the category is also MISMATCH (e.g. a php-wrapper scaffold still naming `BoostCore\Scripts\BoostAutoSync::run` instead of its `PackageBoostPhp` façade).

  | Category | Direct boost dep | Canonical `post-install-cmd` / `post-update-cmd` value | Floor that ships the façade |
  |---|---|---|---|
  | `php-package`, `phpstan-extension`, `rector-extension`, `composer-plugin` | `sandermuller/package-boost-php` | `SanderMuller\PackageBoostPhp\Scripts\AutoSync::run` | `^1.0` |
  | `laravel-package` (+ `laravel-package-spatie`, `filament-plugin`, `nova-tool`) | `sandermuller/package-boost-laravel` | `SanderMuller\PackageBoostLaravel\Scripts\AutoSync::run` | `^1.0` |
  | `skill-bundle` | `sandermuller/boost-core` (direct `require`) | `SanderMuller\BoostCore\Scripts\BoostAutoSync::run` | `^1.1` (boost-core; canonical floor — `.config/boost.php` needs ≥ 0.18, scaffold pins the current `^1.1`) |
  | `laravel-project` | n/a (artisan command) | scaffold-conditional — see the `laravel-project` section above | n/a |

  **Why the fork:** the wrapper categories pull `boost-core` only *transitively* through their wrapper. Naming `BoostCore\Scripts\BoostAutoSync::run` there is a transitive-class reference — declaring a symbol the `composer.json` doesn't directly depend on. Each wrapper ships a namespace façade (`PackageBoostPhp\Scripts\AutoSync` / `PackageBoostLaravel\Scripts\AutoSync`) that delegates to `BoostAutoSync`, so the scaffold names only a class from its own direct dependency. `skill-bundle` requires `boost-core` *directly*, so `BoostAutoSync::run` is already a direct-dep class there — it keeps the boost-core callback, and the façade rule does not apply.

  > **ATOMIC RULE — the callback and its floor move together.** The façade class only exists from the "Floor that ships the façade" version. Whenever a phase WRITES one of these callbacks — a bootstrap mint, an upgrade INSERTING a missing `post-install-cmd`/`post-update-cmd` hook, OR an upgrade replacing an old `BoostAutoSync::run` MISMATCH — the same change MUST ensure the `require-dev` floor for that category's wrapper is at least the floor shown above. The MISSING-insert case is easy to miss: a partially-drifted scaffold with only one of the two hooks gets the other inserted as the façade callback, and if its floor is still pre-façade that inserted callback is non-autoloadable. A façade callback paired with a pre-façade floor is **worse than the drift it replaces**: a fresh `composer install`/`update` whose lock resolves the older wrapper hits a post-install/post-update hook referencing a class that isn't autoloadable. Composer does NOT hard-fail here — its `EventDispatcher` runs a `class_exists()` guard, emits a `<warning>` ("Class … is not autoloadable, can not call … script"), and skips the hook. So the failure is silent: the autosync hook **no-ops**, and AI-asset sync is dead until the floor is fixed — strictly worse than the working-but-cosmetically-transitive callback it replaced. On the upgrade path: if the wrapper is PRESENT below the façade floor, bump the constraint AND swap the callback in one patch; never swap the callback alone.
- `qa` (baseline): `["@rector", "@format", "@phpstan-simplified"]`. `php-package` / `composer-plugin` append `@validate-gitattributes`. `rector-extension` appends `@test` instead.
- All other values: see the JSON blocks below.

## Baseline scripts (code-bearing categories)

This block is the baseline for the five **code-bearing** categories (`php-package`, `laravel-package`, `phpstan-extension`, `rector-extension`, `composer-plugin`). Two categories deviate: `laravel-project` drops `sync-ai` (see its section below); `skill-bundle` ships a lean subset (see "`skill-bundle` scripts" below).

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
    "sync-ai": "vendor/bin/boost sync",
    "qa": ["@rector", "@format", "@phpstan-simplified"],
    "post-install-cmd": [
      "SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"
    ],
    "post-update-cmd": [
      "SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"
    ]
  }
}
```

The baseline above shows the **php-wrapper** callback (`SanderMuller\PackageBoostPhp\Scripts\AutoSync::run`), canonical for four of the five code-bearing categories: `php-package`, `phpstan-extension`, `rector-extension`, `composer-plugin`. **`laravel-package` substitutes** the laravel-wrapper façade — see "Substitutions → `laravel-package`" below. Both are namespace façades that delegate to boost-core's `BoostAutoSync`, so the scaffold references a class from its own direct dependency (`package-boost-php` / `package-boost-laravel`) rather than the transitive `boost-core`. Neither is a POSIX-shell conditional (Windows-broken) nor the testbench artisan command (the framework-agnostic `package-boost-php` registers none). The façade is autoloadable because the category's direct boost dependency provides it; see the per-family table under "Canonical-value lookups".

## Substitutions

### `test-framework=phpunit`

- `"test": "vendor/bin/phpunit"`
- `"test-coverage": "vendor/bin/phpunit --coverage-html=coverage"`

### `laravel-package`

- **`post-install-cmd` / `post-update-cmd` callback.** Substitute the laravel-wrapper façade for the php-wrapper default shown in the baseline block: both arrays become `["SanderMuller\\PackageBoostLaravel\\Scripts\\AutoSync::run"]`. Same delegate-to-`BoostAutoSync` façade, but from `sandermuller/package-boost-laravel` (the category's direct dep) instead of `package-boost-php`. Applies equally to the `laravel-package-spatie`, `filament-plugin`, and `nova-tool` variants, which route through the laravel-package audit/upgrade phases.

### `laravel-project`

- **No `sync-ai` script.** `laravel-project` carries `laravel/boost` (Laravel's own AI tooling), not `sandermuller/boost-core` — there is no `vendor/bin/boost`. AI-asset sync for an application is `php artisan boost:install` / `boost:update` (see `bootstrap-laravel-project.md` / `upgrade-laravel-project.md`). Drop `sync-ai` from the baseline block for this category.

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

## `skill-bundle` scripts (replaces the baseline)

`skill-bundle` ships pure-markdown skills and no PHP source, so it does NOT take the baseline block. Its complete `scripts` set — no `phpstan` / `rector` / `test` / `test-coverage` / `sync-ai` (no PHP toolchain, no test runner):

```json
{
  "scripts": {
    "post-install-cmd": ["SanderMuller\\BoostCore\\Scripts\\BoostAutoSync::run"],
    "post-update-cmd": ["SanderMuller\\BoostCore\\Scripts\\BoostAutoSync::run"],
    "format": "vendor/bin/pint",
    "validate-gitattributes": "vendor/bin/lean-package-validator validate",
    "qa": ["@format", "@validate-gitattributes"],
    "qa-check": ["vendor/bin/pint --test", "@validate-gitattributes"]
  }
}
```

## Conditional additions

### When opt-in `--with-hihaho-rules` (laravel-project)

No script additions — the rule packs auto-register via `phpstan/extension-installer` and Rector's set discovery.

### When opt-in `--with-security-advisories` (laravel-project)

No script additions — the `roave/security-advisories` package blocks installation of vulnerable deps automatically.

## Merge semantics

- New target (bootstrap): write the full scripts block as composed above.
- Existing target (upgrade): use `merge-keys` mode — insert only the keys we own that are missing. Don't reorder or remove existing scripts. Don't override existing scripts with the same name (prompt the user if there's a conflict).
