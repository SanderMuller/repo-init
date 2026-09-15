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

Baseline 11 minus `sync-ai`, minus the two auto-sync hooks unless the scaffold carries `sandermuller/project-boost-laravel`.

- **Unconditional (8)**: `phpstan`, `phpstan-simplified`, `phpstan-clear-cache`, `format`, `rector`, `test`, `test-coverage`, `qa`.
- **Scaffold-conditional (2)**: `post-install-cmd`, `post-update-cmd` → the dev-mode-guarded artisan call below. Detection is `sandermuller/project-boost-laravel` in `require-dev` — nothing else. A vanilla laravel-project carries `laravel/boost` alone and gets no boost entry in either array.

```json
"post-install-cmd": [
  "@php -r \"if (getenv('COMPOSER_DEV_MODE') !== '0') { passthru(escapeshellarg(PHP_BINARY) . ' artisan project-boost:sync'); }\""
],
"post-update-cmd": [
  "@php artisan vendor:publish --tag=laravel-assets --ansi --force",
  "@php -r \"if (getenv('COMPOSER_DEV_MODE') !== '0') { passthru(escapeshellarg(PHP_BINARY) . ' artisan project-boost:sync'); }\""
]
```

**This is an ENTRY in each array, never the whole key.** The Laravel skeleton ships its own `post-update-cmd` — `@php artisan vendor:publish --tag=laravel-assets --ansi --force` — shown above so the merged shape is unambiguous. Append the boost entry after whatever the target already has; when the wrapper is absent, remove the boost ENTRY and leave every other handler in place. Writing the key wholesale, or deleting it, drops Laravel's asset publishing. `post-install-cmd` is usually a new key (the skeleton ships none), but check before writing it — an app may have added one.

**The guard is mandatory — a bare `["@php artisan project-boost:sync"]` is MISMATCH.** The wrapper is a `require-dev` package, so `composer install --no-dev` — the normal production deploy — installs neither the package nor its command. The hook still fires (Composer runs lifecycle scripts under `--no-dev`), artisan exits 1 on the undefined command, and Composer aborts the install with `Script @php artisan project-boost:sync handling the post-install-cmd event returned with error code 1`. Verified against Composer 2.10.2. The upstream configuration guide shows the bare form; it does not cover `--no-dev`.

Why this shape:

- **Pure PHP, no shell conditional.** The branch is PHP, not `if [ "$COMPOSER_DEV_MODE" = "1" ]; then …`, which cannot run on Windows `cmd.exe` at all. NEEDS-CONFIRMATION: the one-liner itself is verified on macOS against Composer 2.10.2 only. Windows nests quotes differently — `cmd.exe` strips the outer double quotes and `escapeshellarg()` emits double quotes there rather than single — so confirm on Windows before treating this value as proven cross-platform. A class callback (see below) would remove the question entirely.
- **No `$` and no backtick in the one-liner.** Composer passes the script through a shell on POSIX; a `$var` would be interpolated before PHP ever saw it.
- **`escapeshellarg(PHP_BINARY)`** — the PHP binary path contains spaces on common setups (Herd, XAMPP), and an unquoted `PHP_BINARY` splits on them.
- **The sync's exit code is not propagated.** `passthru()` runs the command but the one-liner still exits 0, so a failing sync warns in the install output without failing the install. That matches `BoostAutoSync::run`, which writes a warning through Composer's IO rather than failing the event.

The better long-term fix belongs upstream: `sandermuller/project-boost-laravel` shipping a `Scripts\AutoSync::run` class callback with an `Event::isDevMode()` guard, the shape its three sibling wrappers already use. Revisit this row if that lands.

**Never `BoostAutoSync::run` in a laravel-project.** The wrapper pulls `sandermuller/boost-core` transitively, so the callback DOES autoload — and that is the trap. `BoostAutoSync::run` invokes the bare `vendor/bin/boost sync`, which bypasses the wrapper's injection pipeline: the `laravel/boost` bundled skill set never reaches the agent directories, and the sync still reports success against the smaller set. Flag it MISMATCH, not PRESENT. `BoostAutoSync::run` stays correct for a non-Laravel project consuming the engine directly — this rule is Laravel-application-specific. Source: the `project-boost-laravel` configuration guide, "Why not BoostAutoSync::run here?".

No `sync-ai` script — `laravel/boost` owns AI-asset sync for applications (`php artisan boost:update`); there is no `vendor/bin/boost` here.

### `skill-bundle` (6 keys)

`post-install-cmd`, `post-update-cmd`, `format`, `validate-gitattributes`, `qa`, `qa-check`. Baseline does NOT apply.

### Canonical-value lookups

- `post-install-cmd` / `post-update-cmd`: array containing the **family-specific** auto-sync callback. The value forks by which boost package the category depends on directly — see the table below. Any POSIX-shell conditional (`if [ "$COMPOSER_DEV_MODE" = "1" ]; then …`) is MISMATCH — Windows-broken; predates boost-core 0.6. A callback that names the wrong namespace for the category is also MISMATCH (e.g. a php-wrapper scaffold still naming `BoostCore\Scripts\BoostAutoSync::run` instead of its `PackageBoostPhp` façade).

  | Category | Direct boost dep | Canonical `post-install-cmd` / `post-update-cmd` value | Floor that ships the façade |
  |---|---|---|---|
  | `php-package`, `phpstan-extension`, `rector-extension`, `composer-plugin` | `sandermuller/package-boost-php` | `SanderMuller\PackageBoostPhp\Scripts\AutoSync::run` | `^1.0` |
  | `laravel-package` (+ `laravel-package-spatie`, `filament-plugin`, `nova-tool`) | `sandermuller/package-boost-laravel` | `SanderMuller\PackageBoostLaravel\Scripts\AutoSync::run` | `^1.0` |
  | `skill-bundle` | `sandermuller/boost-core` (direct `require`) | `SanderMuller\BoostCore\Scripts\BoostAutoSync::run` | `^1.6` (boost-core; canonical floor — `.config/boost.php` needs ≥ 0.18, scaffold pins the current `^1.6`) |
  | `laravel-project` (with `sandermuller/project-boost-laravel`) | `sandermuller/project-boost-laravel` (`require-dev`) | the dev-mode-guarded `@php -r` one-liner — see the `laravel-project` section | `^1.4` (scaffold pin — see note) |
  | `laravel-project` (vanilla `laravel/boost` only) | n/a | no boost entry in either array (other handlers untouched) | n/a |

  **The laravel-project floor is a scaffold pin, not a façade floor.** `project-boost:sync` ships in every release of the wrapper (`SyncCommand` is present from `0.1.0`), so no version gates the hook. Pin the current `^1.4`, the way `skill-bundle` pins the current boost-core. The failure mode also differs from the class callbacks: a missing artisan command exits non-zero and Composer reports it, where a non-autoloadable class callback is skipped with a warning. Loud, not silent.

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

No script additions.

`hihaho/phpstan-rules` does auto-register, via `phpstan/extension-installer`.

`hihaho/rector-rules` does NOT. Rector has no set discovery, and the package's
`extra.rector.includes` entry points at an empty `config/config.php` and needs
`rector/extension-installer`, which neither reference app installs. Its sets and
rules must be written into `rector.php` by hand — see
`references/rector-config.md`, "`--with-hihaho-rules` wiring".

## Merge semantics

- New target (bootstrap): write the full scripts block as composed above.
- Existing target (upgrade): use `merge-keys` mode — insert only the keys we own that are missing. Don't reorder or remove existing scripts. Don't override existing scripts with the same name (prompt the user if there's a conflict).
