# Upgrade: laravel-project

Apply the audit findings to an existing Laravel application.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md` AND re-run audit: open `$REPO_INIT_HOME/phases/audit-laravel-project.md`.

## Safety rails

Same as `upgrade-laravel-package.md` §Honor the safety rails. Per-category never-touch is critical for laravel-project (auth middleware, policies, config/auth*.php, routes/auth.php, .env — never write); enforce via `$REPO_INIT_HOME/checklists/per-category-never-touch.md` + git-dirty rule before every write. Verify category-fit one more time via `$REPO_INIT_HOME/references/detection-rules.md`; dep expectations come from `$REPO_INIT_HOME/references/per-category-deps.md`.

## Allow-list Composer plugins (BEFORE any composer command in this phase)

Runs first — before the runtime-dep step, the type-perfect migration, and the dev-dep step, all of which invoke Composer. This phase targets an EXISTING repo whose `composer.json` may predate the current stub, and the `config.allow-plugins` merge-keys patch happens much further down. Composer loads plugins at command startup, so a plugin that is installed-but-not-allow-listed can abort a later command before the safeguard is ever reached — and requiring one that isn't allow-listed prompts interactively and hard-fails with `blocked-plugin` non-interactively.

```bash
composer config --no-plugins allow-plugins.phpstan/extension-installer true
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

For each MISSING file:

1. Read stub from `$REPO_INIT_HOME/stubs/<shared|laravel-project>/<path>`.
2. Substitute placeholders.
3. Write — prompt on conflict per `replace` mode.

`README.append.md` is handled specially: APPEND its content to the existing `README.md` (laravel-project ships a README from `laravel new`). Never overwrite the README.

## Apply MISSING runtime deps

Skipped — laravel-project doesn't have repo-init-mandated runtime deps (the user owns their application's `require` block).

## Migrate Pest 4 → 5 (ATOMIC)

Trigger: the target uses Pest and `pestphp/pest` can resolve below `5.0`. Skip the whole section for a PHPUnit target.

**Pest 3 targets take the 3 → 4 step first.** Raise `pestphp/pest` to `^4.0`, run `composer update`, then `vendor/bin/pest --init` to migrate the 3 → 4 syntax, and only then run the steps below. A direct 3 → 5 jump leaves Pest 3 syntax in the suite and the final test run fails.

**Runs BEFORE the `type-coverage` / `type-perfect` migration below** — Pest 5 raises the PHP floor to `^8.4`, and that floor decides which branch the type-dep step and the symplify step take. Doing it in the other order applies the PHP 8.3 branch and then invalidates it.

Why it matters: Pest 5 requires PHP `^8.4` and PHPUnit 13. So the PHP floor bump, the plugin bumps, and the PHP >= 8.4 dep set are one change — a partial move leaves `composer update` unresolvable.

1. Raise `require.php` to `^8.4` (or `^8.5`) in `composer.json`.
2. Raise `pestphp/pest` and every `pestphp/*` plugin to `^5.0`.
3. Replace `mrpunyapal/rector-pest` with `pestphp/pest-plugin-rector: ^5.0`, and add `pestphp/pest-plugin-phpstan: ^5.0` + `pestphp/pest-plugin-agent: ^5.0`.
4. If the target carries `stolt/lean-package-validator`, raise it to `^6.0.1` — 6.0.0 caps `sebastian/diff` at `^7` and cannot install next to PHPUnit 13. Composer backtracks to 6.0.1 by itself, so this is a clarity fix, not a blocker.
5. Apply the PHP >= 8.4 dep set in the same `composer.json` pass: remove `rector/type-perfect`, set `tomasvotruba/type-coverage: ^2.3`, and replace `symplify/phpstan-extensions: ^12.0` with `symplify/phpstan-rules: ^14.12`.
6. If the target carries `orchestra/testbench`, change the constraint to `^11.0`; for a Laravel package category also drop every Laravel 12 / testbench 10 cell from `run-tests.yml` — Pest 5 needs `symfony/process: ^8.1` and testbench 10 pins `^7.2`. Leave the runtime `illuminate/*` range alone.
7. Run one resolution: `composer update`.

Then fix the files the bump touches:

- `rector.php` — `use Pest\Rector\Set\PestSetList;` and the single set `PestSetList::CODING_STYLE` (replaces `PEST_CODE_QUALITY` / `PEST_CHAIN` / `PEST_LARAVEL`).
- `tests/Pest.php` — add `pest()->tia()->locally();` for the Tia engine. Never add `--tia` to a composer script or a CI step.
- `.github/workflows/run-tests.yml` — drop every PHP 8.3 matrix cell; the floor is `^8.4`.

Verify before moving on:

```bash
composer show --direct | grep -E 'pestphp|type-coverage|type-perfect'
vendor/bin/pest --ci
```

Pest 5 carries PHPUnit 13's breaking changes. A suite that uses removed or deprecated PHPUnit APIs needs a hand pass — report what failed instead of downgrading Pest.

Steps 1 and 5 make the type-perfect section below take its PHP >= 8.4 branch. If the user refuses the PHP floor bump, stop the Pest migration here, keep Pest 4, and record it as a deliberate exception.

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

Per-category mandatory `require-dev` for `laravel-project`:

- `larastan/larastan`
- `laravel/boost`
- `laravel/pail`
- `laravel/tinker` (Laravel may ship this already)
- `driftingly/rector-laravel`

Plus shared dev deps from `$REPO_INIT_HOME/references/shared-dev-deps.md` minus what Laravel installer typically already ships (read freshly-generated composer.json to confirm): `laravel/pao`, `laravel/pint` (already), `phpstan/extension-installer`, `phpstan/phpstan-strict-rules`, `phpstan/phpstan-deprecation-rules`, `phpstan/phpstan-phpunit`, `rector/rector`, `rector/type-perfect` (`^2.1` — PHP 8.3 floor ONLY; DROP on a PHP >= 8.4 floor), `spaze/phpstan-disallowed-calls`, `symplify/phpstan-rules` (`^14.11`, PHP >= 8.4 floor; PHP 8.3 floor keeps `symplify/phpstan-extensions: ^12.0` — see shared-dev-deps.md "Symplify formatter dep"), `tomasvotruba/cognitive-complexity`, `tomasvotruba/type-coverage` (`>=2.2.0 <2.2.2` on a PHP 8.3 floor — the `<2.2.2` cap is mandatory; `^2.3` on a PHP >= 8.4 floor, where it replaces `rector/type-perfect` — see shared-dev-deps.md "Type-perfect dep"), `nunomaduro/collision` (Laravel ships), `orchestra/testbench` (typically NOT in laravel-project — skip). `laravel-project` does NOT take `sandermuller/package-boost-php` — `laravel/boost` (above) is its boost-family tool.

Plus confirmed opt-ins:

- `--with-hihaho-rules`: `hihaho/phpstan-rules`, `hihaho/rector-rules`, `symplify/phpstan-rules`
- `--with-security-advisories`: `roave/security-advisories: dev-latest`

Then the single batched `composer require --dev <list>` call.

**Test framework note**: if the user has both `pestphp/pest` and `phpunit/phpunit` from prior installs, ask which to keep. Don't auto-resolve — wrong choice rewrites test scaffolding.

Common: laravel-project usually has `phpunit/phpunit` from `laravel new`. If user opted into Pest in audit, add Pest deps and instruct them to run `vendor/bin/pest --init` separately to migrate tests.

On failure, consult `references/composer-failure-modes.md`.

## Apply OUTDATED files per merge mode

Same logic as upgrade-laravel-package.md — apply each file's mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md`. With laravel-project paths.

**Special handling for `.editorconfig`**: Laravel installer ships its own; ours overrides for strict utf-8/lf/4-space. If user has accepted Laravel's defaults for years, ask before clobbering — they may have intentional team-wide conventions you don't want to override.

**`.gitattributes`**: managed-block merge. The package-boost block may not exist yet on older projects — bootstrap creates it. Upgrade may need to create it on first run; then insert our entries inside.

**`phpunit.xml` vs `phpunit.xml`**: Laravel ships `phpunit.xml` (no `.dist`). Ours says use `.dist`. NON-CANONICAL fix handles the rename — see below.

## Apply composer.json merge-keys patches

Per `references/composer-scripts.md`:

- **`scripts`**: **Read `$REPO_INIT_HOME/references/composer-scripts.md` IN FULL before patching.** Do NOT infer the canonical block from memory — a real laravel-package upgrade (2026-05-25) shipped a Windows-broken `post-install-cmd` and no `post-update-cmd` because the agent auto-completed from training data. For each documented key (10 for laravel-project: baseline 11 minus `sync-ai`; `test` / `test-coverage` may already be present from `laravel new`, don't override): verify present with canonical value. Three cases — **MISSING** (insert), **PRESENT** (leave), **MISMATCH** (prompt — show both sides, offer replace / skip).

  laravel-project does NOT get a `sync-ai` script — `laravel/boost` owns AI-asset sync for applications (`php artisan boost:update`); there is no `vendor/bin/boost` here.

  **`post-install-cmd` / `post-update-cmd` are scaffold-conditional**: the canonical `["SanderMuller\\BoostCore\\Scripts\\BoostAutoSync::run"]` value requires `sandermuller/boost-core` to be in the dependency tree. A vanilla laravel-project does NOT pull boost-core — it uses `laravel/boost`. Check first; if boost-core absent, skip these two keys entirely. If a POSIX-shell `post-install-cmd` is present in a laravel-project without boost-core, the value should be REMOVED (Windows-broken AND the binary doesn't exist) — prompt the user. HIGH severity drift either way.
- **`scripts.dev`**: if absent, suggest adding the multi-process dev script (concurrent server + queue + pail + vite). This is laravel-project canonical. Show example, ask before inserting.
- **`config.allow-plugins`**: insert `phpstan/extension-installer: true`, `pestphp/pest-plugin: true` (if pest), `php-http/discovery: true` (Laravel default).
- **`config.sort-packages`**: set to `true`.

Don't touch `extra.laravel.providers` for laravel-project — Laravel uses `extra.laravel.dont-discover` etc.; user owns the `extra.laravel.*` block.

## Apply NON-CANONICAL fixes (each prompted)

- **`phpunit.xml` (no .dist)**: prompt "rename to `phpunit.xml`?" Only if `.dist` doesn't already exist.
- **PHPUnit cache findings** (if `test-framework=phpunit`): apply `$REPO_INIT_HOME/references/phpunit-config.md` Upgrade-actions section — set `cacheDirectory=".cache/phpunit"`, `rm -rf .phpunit.cache`, `git rm -r --cached .phpunit.cache` if previously committed.
- **CI path filter drift — `phpstan.yml` missing `composer.json` / `composer.lock`**: insert both lines under the `push.paths` and `pull_request.paths` blocks in `.github/workflows/phpstan.yml`.
- **`.gitattributes` missing `.ai/ export-ignore`**: insert `.ai/ export-ignore` line after `.agents/ export-ignore` inside the `# >>> package-boost (managed) >>>` block.
- **PHP floor `^8.2`**: prompt to bump.
- **Both larastan + bare phpstan**: prompt to remove `phpstan/phpstan`.
- **`composer.lock` NOT committed** (rare — Laravel convention is to commit it for apps): prompt to add to git.
- **Two managed blocks in `.gitattributes`**: same as upgrade-laravel-package.md.
- **`minimum-stability` / `prefer-stable`**: add `"minimum-stability": "stable"` + `"prefer-stable": true` to `composer.json` if absent or if `prefer-stable` isn't `true` (the Laravel skeleton ships both; see `references/version-defaults.md`). If `minimum-stability` is looser than `stable`, **default to tightening it to `stable`** — a deployed app rarely has a standing reason for a looser floor. Never loosen a passing `stable` baseline.

## Apply `.gitignore` append-only

Add laravel-project-specific lines if missing:

```
/public/build
/public/hot
/public/storage
/storage/pail
_ide_helper.php
_ide_helper_models.php
.phpstorm.meta.php
```

Dedupe — never add a duplicate.

## Run laravel/boost sync

`laravel-project` uses `laravel/boost` (not `sandermuller/boost-core`) for AI-asset sync. Laravel Boost v2 installs and updates skills from the packages detected in `composer.json`:

```bash
php artisan boost:update
```

If `laravel/boost` isn't installed yet, run `php artisan boost:install` first (or `composer require laravel/boost` then `php artisan boost:install`).

## Verification

Open `$REPO_INIT_HOME/checklists/post-upgrade-verification.md`.

Plus laravel-project-specific:

```bash
php artisan --version
php artisan test --compact
composer phpstan-simplified
```

## What's next

- Keep working: next phase or re-audit.
- Done: stop.

## Common issues

- **`composer dev` script conflicts with existing dev runner**: user may have their own `dev` workflow (Sail, Herd, custom). Ask before inserting our concurrent runner.
- **Laravel installer ships file we want to keep, audit flagged it as OUTDATED**: tell the user — drift from our stub may be intentional Laravel updates. `notify-only` mode catches most of these. If it's a `replace`-mode file, defer to the user.
- **`hihaho/phpstan-rules` not installable** (private repo or auth-required): if user opted in but install fails, surface the auth.json / Packagist credentials guidance; don't strip the opt-in.
