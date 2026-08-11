# Upgrade: rector-extension

Apply audit findings to an existing rector-extension package.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md` AND re-run audit: open `$REPO_INIT_HOME/phases/audit-rector-extension.md`.

## Safety rails

Same as `upgrade-laravel-package.md` §Honor the safety rails. Honour the never-touch list at `$REPO_INIT_HOME/checklists/per-category-never-touch.md` and the git-dirty rule before every write. Verify category-fit one more time via `$REPO_INIT_HOME/references/detection-rules.md` before mutating; dep expectations come from `$REPO_INIT_HOME/references/per-category-deps.md`.

## Allow-list Composer plugins (BEFORE any composer command in this phase)

Runs first — before the runtime-dep step, the type-perfect migration, and the dev-dep step, all of which invoke Composer. This phase targets an EXISTING repo whose `composer.json` may predate the current stub, and the `config.allow-plugins` merge-keys patch happens much further down. Composer loads plugins at command startup, so a plugin that is installed-but-not-allow-listed can abort a later command before the safeguard is ever reached — and requiring one that isn't allow-listed prompts interactively and hard-fails with `blocked-plugin` non-interactively.

```bash
composer config --no-plugins allow-plugins.phpstan/extension-installer true
composer config --no-plugins allow-plugins.rector/extension-installer true
# pest only:
composer config --no-plugins allow-plugins.pestphp/pest-plugin true
```

`--no-plugins` is what makes this safe to run first: it keeps the config write itself from being blocked by the very plugin state it is fixing.

Per key, read the current `config.allow-plugins` value first:

- **`true`** — already satisfied, skip.
- **absent** — write it (command above).
- **`false`** — an *explicit denial*, not a satisfied entry: Composer keeps the plugin disabled and suppresses the prompt, so `phpstan/extension-installer` never registers the PHPStan extensions (and `rector/extension-installer` never auto-discovers Rector extensions). Do NOT silently flip it — surface the explicit `false` to the user and ask before changing it.

The merge-keys step later is then a no-op for these keys. See `$REPO_INIT_HOME/references/composer-failure-modes.md` → "Allow-plugins prompt / blocked plugin".

## Apply MISSING files

Stubs from `$REPO_INIT_HOME/stubs/<shared|rector-extension>/<path>`.

`config/config.php` is treated specially:

- If absent: copy `$REPO_INIT_HOME/stubs/rector-extension/config/config.php` (skeleton with empty `withRules([])`).
- If present: `notify-only` — user owns it once rules are registered. Don't overwrite.

## Apply MISSING runtime deps

Single `composer require <list>` (NOT `--dev`):

- `rector/rector: ^2` (mandatory)
- `symplify/rule-doc-generator-contracts` (mandatory)
- `driftingly/rector-laravel` (only if Laravel-aware opt-in confirmed)

## Migrate the `type-coverage` / `type-perfect` pair (ATOMIC)

**Runs BEFORE "Apply MISSING dev deps" below** — that step bumps `tomasvotruba/type-coverage` to its canonical constraint, which on a PHP >= 8.4 floor is `^2.3`; doing that while `rector/type-perfect` is still in `require-dev` *creates* the broken pair this section exists to prevent.

Trigger: `rector/type-perfect` is in the target's `require-dev`, on ANY floor and regardless of the current `tomasvotruba/type-coverage` constraint. Do NOT gate this on the audit's duplicate-registration finding — that finding only fires for a constraint already able to resolve `>= 2.3`, and an older target sitting on e.g. `^2.1` is equally broken the moment the dep step raises it. Normative table: `$REPO_INIT_HOME/references/shared-dev-deps.md` → "Type-perfect dep".

Why it matters: `tomasvotruba/type-coverage` 2.3.0 absorbed `rector/type-perfect` — it autoloads `Rector\TypePerfect\` from its own `packages/type-perfect/src` and lists that package's `extension.neon` in `extra.phpstan.includes`. With both installed, `phpstan/extension-installer` includes that config twice and PHPStan aborts at boot on a duplicate `Rector\TypePerfect\Reflection\MethodNodeAnalyser` service. Neither package declares a Composer `conflict`, so nothing stops the pair from installing. Composer resolves against the **runtime** PHP, not `require.php` — so an uncapped constraint keeps the repo green on a PHP 8.3 CI cell and dead on the 8.4 one.

Branch on the target's `require.php` floor:

**PHP >= 8.4 floor** — drop the abandoned package in a SINGLE resolution:

```bash
composer remove --dev rector/type-perfect --no-update
composer require --dev tomasvotruba/type-coverage:^2.3
```

`--no-update` makes the first command a pure `composer.json` edit — nothing is installed or removed until the `require` runs, so `vendor/` never holds both packages at once. Equivalently: hand-edit both `require-dev` lines, then one `composer update rector/type-perfect tomasvotruba/type-coverage`. **Never** run a plain `composer remove --dev rector/type-perfect` first: that resolves immediately, and with `tomasvotruba/type-coverage` still `< 2.3` it leaves `parameters.type_perfect:` in `phpstan.neon.dist` unregistered — PHPStan then fails boot the other way (`Unexpected item 'parameters › type_perfect'`).

**PHP 8.3 floor** — keep both, cap the constraint (`>=2.2.0 <2.2.2` — 2.2.2 already requires PHP ^8.4):

```bash
composer require --dev "tomasvotruba/type-coverage:>=2.2.0 <2.2.2"
```

`rector/type-perfect: ^2.1` stays. Raise the standing ADVISORY: bumping `require.php` to `^8.4` drops two abandoned packages (`rector/type-perfect` and `symplify/phpstan-extensions`) and lifts this cap.

Either way, leave `phpstan.neon.dist`'s `parameters.type_perfect:` block alone — exactly one of the two packages registers those params on every accepted floor.

Verify before moving on:

```bash
composer show --direct | grep -E 'type-coverage|type-perfect'
vendor/bin/phpstan analyse --memory-limit=2G
```

Expect exactly one line on a PHP >= 8.4 floor (`tomasvotruba/type-coverage` at `2.3.x`) and two on a PHP 8.3 floor (`tomasvotruba/type-coverage` at `2.2.x` + `rector/type-perfect`). PHPStan must reach analysis — a boot-time duplicate-service error is the failure this step exists to remove.

## Apply MISSING dev deps

Single `composer require --dev <list>`. Shared list MINUS `rector/rector` (per §5.1.1 — it's in `require`). Plus `nikic/php-parser` and `sandermuller/package-boost-php` (the framework-agnostic boost umbrella; pulls `sandermuller/boost-core` transitively).

Test-framework: `pestphp/pest` (+ arch + rector-pest) for pest, OR `phpunit/phpunit` for phpunit.

On failure, consult `references/composer-failure-modes.md`.

## Apply OUTDATED files per merge mode

Same logic as upgrade-laravel-package.md — apply each file's mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md`. Scripts patch per `$REPO_INIT_HOME/references/composer-scripts.md`.

## Apply composer.json merge-keys patches

- **`scripts`**: **Read `$REPO_INIT_HOME/references/composer-scripts.md` IN FULL before patching.** Do NOT infer the canonical block from memory — a real laravel-package upgrade (2026-05-25) shipped a Windows-broken `post-install-cmd` and no `post-update-cmd` because the agent auto-completed from training data. For each documented key (11 baseline for rector-extension; canonical `qa` is `["@rector", "@format", "@phpstan-simplified", "@test"]` — rule tests are part of full QA): verify present with canonical value. Three cases — **MISSING** (insert), **PRESENT** (leave), **MISMATCH** (prompt — show both sides, offer replace / skip). Common drift: POSIX-shell `post-install-cmd` referencing `vendor/bin/boost sync` is Windows-broken (canonical: `["SanderMuller\\PackageBoostPhp\\Scripts\\AutoSync::run"]`); `post-update-cmd` often missing entirely. Both HIGH severity. **Floor coupling (ATOMIC):** whenever this step WRITES a `PackageBoostPhp` façade callback into `post-install-cmd`/`post-update-cmd` — whether INSERTING a missing hook (the MISSING case) OR swapping an old `BoostCore\\Scripts\\BoostAutoSync::run` value (the MISMATCH case) — it MUST, in the same patch, ensure `sandermuller/package-boost-php` in `require-dev` is at `^1.0` (repo-init's canonical floor; bump if lower: `composer require --dev "sandermuller/package-boost-php:^1.0"`). The façade class first ships in 0.16.0; writing the façade callback while the floor allows a pre-0.16 version leaves the autosync hook referencing a non-autoloadable class — Composer skip-warns (`class_exists()` guard in its `EventDispatcher`) and the hook silently no-ops on the next `composer install`/`update`, so autosync stays dead until the floor is fixed. This bites the partial-drift case especially: a scaffold that has only `post-install-cmd` (and is below the floor) gets `post-update-cmd` inserted as the façade callback — non-autoloadable until the floor moves with it. Never write the façade callback without ensuring the floor in the same patch — see the ATOMIC RULE in `composer-scripts.md`.
- **`extra.rector.includes`**: ensure `["config/config.php"]` is set. If existing array, ensure the path is in it. Don't replace; add.
- **`config.allow-plugins`**: `pestphp/pest-plugin: true` (if pest), `phpstan/extension-installer: true`, **`rector/extension-installer: true`** (critical for rector-extension — without it, the extension's `config/config.php` isn't auto-loaded by consumer rector configs). Remove stale entries — ORDER MATTERS for `package-boost-php`:
  - `sandermuller/boost-core: true` — safe to remove unconditionally (`type: library` from 0.6.0).
  - `sandermuller/package-boost-php: true` — safe to remove ONLY when the installed `sandermuller/package-boost-php` is `≥ 0.9.0`. Verify with `composer show sandermuller/package-boost-php`. If `< 0.9.0`: FIRST bump the constraint in `require-dev` to `^0.9.0` and run `composer update sandermuller/package-boost-php`. Removing the entry while package-boost-php is still `< 0.9.0` blocks `composer install` with a `blocked-plugin` error.

  Both are Composer-ignored once library-typed (harmless but obsolete).
- **`config.sort-packages`**: `true`.
- Don't touch `extra.laravel.providers` (rector-extension isn't a Laravel SP).

## Apply NON-CANONICAL fixes (each prompted)

- **`rector/rector` in `require-dev` instead of `require`**: move it. `composer remove --dev rector/rector` then `composer require rector/rector:^2`.
- **`rector/rector` in BOTH require and require-dev**: Composer rejects; remove from require-dev.
- **Missing `rector/extension-installer` in `config.allow-plugins`**: insert (via merge-keys above). Without it, the extension is silently broken for consumers.
- **`extra.rector.includes` points to a nonexistent file**: surface to user — either create the file or fix the path.
- **`composer.lock` committed**: prompt to remove from git tracking.
- **PHP floor `^8.2`**: prompt bump.
- **PHPUnit cache findings** (if `test-framework=phpunit`): apply `$REPO_INIT_HOME/references/phpunit-config.md` Upgrade-actions section — set `cacheDirectory=".cache/phpunit"`, `rm -rf .phpunit.cache`, `git rm -r --cached .phpunit.cache` if previously committed.
- **CI path filter drift — `phpstan.yml` missing `composer.json` / `composer.lock`**: insert both lines under the `push.paths` and `pull_request.paths` blocks in `.github/workflows/phpstan.yml`.
- **`.gitattributes` missing `.ai/ export-ignore`**: insert `.ai/ export-ignore` line after `.agents/ export-ignore` inside the `# >>> package-boost (managed) >>>` block.
- **`minimum-stability` / `prefer-stable`**: add `"minimum-stability": "stable"` + `"prefer-stable": true` to `composer.json` if absent or if `prefer-stable` isn't `true`. If `minimum-stability` is looser than `stable`, **default to tightening it to `stable`** — keep `dev` only when the author confirms the package is actively co-developed against unreleased sibling packages (being on `0.x`, or having downstream / production dependents, is a reason to tighten, NOT to keep `dev`; see `references/version-defaults.md`). Never loosen a passing `stable` baseline.

## Migrate boost config to `.config/` (canonical layout)

**Skip if:** `.config/boost.php` exists AND no root `boost.php` exists (already on the canonical layout).

boost-core ≥ 0.17's canonical config location is `.config/boost.php`; audit flags a legacy root `boost.php` as drift. To migrate:

1. **MOVE the file** — `mkdir -p .config && git mv boost.php .config/boost.php`. **Never copy** — leaving both `boost.php` and `.config/boost.php` is a hard error (`AmbiguousBoostConfigException`); every `boost` command then throws.
2. **Ensure boost-core ≥ 0.18** (the `.config/boost/` manifest layout): the `sandermuller/package-boost-php` umbrella (≥ 0.16.2) pulls boost-core ≥ 0.18 transitively — run `composer update sandermuller/package-boost-php`. No direct boost-core require to bump.
3. Run `vendor/bin/boost sync` — it auto-migrates the gitignored sync manifest `.boost/ → .config/boost/`, rewrites the managed `.gitignore` block to ignore `.config/boost/`, and refreshes the managed `.gitattributes` block. Migration is bidirectional + automatic; `vendor/bin/boost sync --check` reports the one-time stale-manifest cleanup as advisory only (never drift).
4. **`.gitattributes`:** ensure `.config/ export-ignore` is in the `# >>> package-boost (managed) >>>` block (preserved as a foreign line by the writer); remove any stale `boost.php export-ignore` line. If the package ships a `.lpv`, replace any `boost.php` glob with `.config/`.
5. **Both-present guard:** if a prior bad copy left BOTH `boost.php` and `.config/boost.php`, do NOT run `boost sync` until resolved — delete the root `boost.php`, keep `.config/boost.php`.

## Migrate the boost config API (`withTags` array form)

**Skip if:** the boost config's `withTags(...)` / `withAgents(...)` calls already pass a single array argument (`->withTags([...])`).

boost-core 0.20 changed every `BoostConfig` builder method to take a single `array` — `withTags()` was the last variadic one. A pre-0.20 call like `->withTags(Tag::Php, Tag::Github)` throws the moment `boost.php` / `.config/boost.php` is loaded (a raw `TypeError` on boost-core 0.20–0.22; a catchable `InvalidBoostConfigException` carrying a migration hint on ≥ 0.23), so `composer install`/`update` autosync and every `boost` command fail until it is fixed. `boost sync` cannot auto-migrate it — loading the config executes the call first. Fix by hand — wrap the arguments in brackets:

```php
// before (pre-0.20 variadic — breaks under boost-core >= 0.20)
->withTags(Tag::Php, Tag::Github)
// after
->withTags([Tag::Php, Tag::Github])
```

Independent of the `.config/` location move above — this applies even to a repo already on the `.config/` layout. It is the one hand-edit the boost `1.x` floor bump requires, because that bump crosses the 0.20 break.

## Run package-boost sync

```bash
vendor/bin/boost sync
```

`vendor/bin/boost` is boost-core's standalone bin (pulled transitively via `sandermuller/package-boost-php`); the framework-agnostic categories carry no `orchestra/testbench`, so the old `vendor/bin/testbench package-boost:sync` form does not apply. The `post-install-cmd` / `post-update-cmd` autosync hook runs the same sync automatically on `composer install`/`update`.

## Verification

Open `$REPO_INIT_HOME/checklists/post-upgrade-verification.md`. Plus:

```bash
vendor/bin/rector --version
vendor/bin/rector process --dry-run    # should run without errors; rules may report 0 changes on empty src/
```

## What's next

- Keep working: next phase or re-audit.
- Done: stop.

## Common issues

- **`vendor/bin/rector process --dry-run` reports "no rules registered"**: extension self-discovery failed. Check `extra.rector.includes` AND `config.allow-plugins.rector/extension-installer: true`. Both must be set.
- **Rule classes in `src/Rector/` not auto-loaded by consumer rector configs**: ensure they're registered in `config/config.php` `withRules([...])`. Just placing them in `src/Rector/` doesn't auto-register them.
- **`composer require` rejects `rector/rector` as already in require**: per design. Don't include it in `composer require --dev`.
