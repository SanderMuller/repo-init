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

## Decide on `sandermuller/project-boost-laravel` (BEFORE any file or dep step)

When the app does not carry `sandermuller/project-boost-laravel`, ask the user now whether to add it. It takes over the agent-file fan-out from `laravel/boost`, rewrites `CLAUDE.md` to an `@AGENTS.md` import, and archives `boost.json` on the first sync. The answer gates the later steps that need the wrapper: `.config/boost.php` (Apply MISSING files), the wrapper and `sandermuller/boost-skills` (Apply MISSING dev deps), the auto-sync hooks (merge-keys patches), the `voice` tag, and the remote skills. Ask once, here — the boost config must exist before the first sync runs.

When the user accepts — or when the app already carries the wrapper but `CLAUDE.md` / `AGENTS.md` still hold a `<laravel-boost-guidelines>` block, so `project-boost:reconcile` has not run yet — remove any boost auto-sync ENTRY from `post-install-cmd` / `post-update-cmd` now, before the first Composer command of this phase: a `BoostAutoSync::run` callback, a shell conditional that calls `vendor/bin/boost sync`, or a `project-boost:sync` call. Leave the arrays' other handlers in place. Otherwise the `composer require` calls below fire that hook, and a sync runs before `project-boost:reconcile` can capture hand edits in the `laravel/boost`-seeded agent files. Do not add the guarded entry in the merge-keys step either — later steps still run Composer. "Sync AI assets" adds it after `project-boost:reconcile`.

## Apply MISSING files

For each MISSING file:

1. Read stub from `$REPO_INIT_HOME/stubs/<shared|laravel-project>/<path>`.
2. Substitute placeholders.
3. Write — prompt on conflict per `replace` mode.

A legacy root `boost.php` (wrapper apps only) moves first: `mkdir -p .config && git mv boost.php .config/boost.php` — never copy, two configs is a hard error. Then edit the moved file instead of copying the stub.

`.config/boost.php` comes from `stubs/laravel-project/.config/boost.php`, not the shared stub. Copy it only when the app carries `sandermuller/project-boost-laravel` or the user accepted it above, and never next to a root `boost.php`. Before the first sync, set three things in the config — the fresh copy, or an existing one (only the `__SKILL_TAGS__` item is copy-only):

- `__SKILL_TAGS__` — substitute per `$REPO_INIT_HOME/references/placeholder-rules.md`. Pre-select `php` in the picker, plus any `boost-skills` tag the user names.
- `withAgents()` — add every agent that `boost.json` lists. The first sync archives `boost.json` only when all the agents in it that boost-core supports are adopted.
- `withAllowedVendors()` — `laravel/boost` alone synced the skills of every installed package that ships `resources/boost/`; the wrapper syncs only the vendors listed here. Keep `sandermuller/boost-skills` and add each other such package (`ls -d vendor/*/*/resources/boost`) except `laravel/boost`, which the wrapper injects. `vendor/bin/boost scan` is the interactive picker for the same list. List the agent skill directories before the first sync and compare after it. A skill that disappeared means a missing vendor or a missing tag: the wrapper's tag filter drops, for example, `volt-development` (tagged `laravel livewire frontend`) unless all three tags are listed. Run `php artisan project-boost:where` and `vendor/bin/boost tags`, add the tags the installed stack needs, and sync again.

`.ai/rules/views.md` also needs its row in `.ai/rules/index.md` — same step as bootstrap §7. When the installed `laravel/boost` is below 2.5, prompt to update it, or the rule is inert. On a Pest repo, do not copy `tests/Unit/Blade/InlinePhpDirectiveTest.php`; write the Pest equivalent of the same scan instead.

`README.append.md` is handled specially: APPEND its content to the existing `README.md` (laravel-project ships a README from `laravel new`). Never overwrite the README.

## Apply MISSING runtime deps

The user owns their application's `require` block. The security canon is the one exception:

- `zae/strict-transport-security` — `composer require zae/strict-transport-security`. Skip when a reverse proxy already sets `Strict-Transport-Security`; say so rather than installing a second source for the same header.
- `spatie/security-advisories-health-check` — only when the app carries `spatie/laravel-health`. Register `SecurityAdvisoriesCheck::new()` in the health-check list in the same pass; the package is a no-op unregistered.

## Migrate Pest 4 → 5 (ATOMIC)

Trigger: the target uses Pest and `pestphp/pest` can resolve below `5.0`. Skip the whole section for a PHPUnit target.

**Pest 3 targets take the 3 → 4 step first.** Raise `pestphp/pest` to `^4.0`, run `composer update`, then `vendor/bin/pest --init` to migrate the 3 → 4 syntax, and only then run the steps below. A direct 3 → 5 jump leaves Pest 3 syntax in the suite and the final test run fails.

**Runs BEFORE the `type-coverage` / `type-perfect` migration below** — Pest 5 needs a PHP `^8.4` floor, which that migration's successors need too. Doing it in the other order applies the PHP 8.3 branch and then invalidates it.

Why it matters: Pest 5 requires PHP `^8.4` and PHPUnit 13. So the PHP floor bump, the plugin bumps, and the PHP >= 8.4 dep set are one change — a partial move leaves `composer update` unresolvable.

1. Raise `require.php` to `^8.5` in `composer.json` — `laravel-project` floors at the newest stable PHP, not the package floor (see `$REPO_INIT_HOME/references/version-defaults.md` "PHP").
2. Raise `pestphp/pest` and every `pestphp/*` plugin to `^5.0`.
3. Replace `mrpunyapal/rector-pest` with `pestphp/pest-plugin-rector: ^5.0`, and add `pestphp/pest-plugin-phpstan: ^5.0` + `pestphp/pest-plugin-agent: ^5.0`.
4. If the target carries `stolt/lean-package-validator`, raise it to `^6.0.1` — 6.0.0 caps `sebastian/diff` at `^7` and cannot install next to PHPUnit 13. Composer backtracks to 6.0.1 by itself, so this is a clarity fix, not a blocker.
5. Apply the PHP >= 8.4 dep set in the same `composer.json` pass: remove `rector/type-perfect`, set `tomasvotruba/type-coverage: ^2.3`, and replace `symplify/phpstan-extensions: ^12.0` with `symplify/phpstan-rules: ^14.17`. In the same pass, add the `parameters.symplify` block from the stub `phpstan.neon.dist` (all eight sets `false`); 14.17 turns every set on without it. See `$REPO_INIT_HOME/references/phpstan-config.md` "Symplify rules".
6. If the target carries `orchestra/testbench`, change the constraint to `^11.0`; for a Laravel package category also drop every Laravel 12 / testbench 10 cell from `run-tests.yml` — Pest 5 needs `symfony/process: ^8.1` and testbench 10 pins `^7.2`. Leave the runtime `illuminate/*` range alone.
7. Run one resolution: `composer update`.

Then fix the files the bump touches:

- `rector.php` — `use Pest\Rector\Set\PestSetList;` and the single set `PestSetList::CODING_STYLE` (replaces `PEST_CODE_QUALITY` / `PEST_CHAIN` / `PEST_LARAVEL`).
- `rector.php` — drop `instanceOf:`, `if:` and `earlyReturn:` from `withPreparedSets()` (Rector 2.6 deprecates all three; `codeQuality: true` covers them). Add `->withComposerBased(...)` after that block ONLY with a flag the repo qualifies for: `phpunit: true` on a PHPUnit repo, `laravel: true` on `laravel-project`. A Pest package qualifies for neither and gets no call. On `laravel-project`, also add `LaravelSetList::LARAVEL_COLLECTION` to the Laravel set list.
- `tests/Pest.php` — add `pest()->tia()->locally();` for the Tia engine. Never add `--tia` to a composer script or a CI step.
- `.github/workflows/run-tests.yml` — drop every matrix cell below the repo's floor.

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

Leave `phpstan.neon.dist`'s `parameters.type_perfect:` block alone — `tomasvotruba/type-coverage: ^2.3` registers those params.

A repo below the `^8.4` floor cannot take this migration: both successors require PHP `^8.4`. Bump `require.php` in the same pass — see `$REPO_INIT_HOME/references/version-defaults.md` "PHP".

Verify before moving on:

```bash
composer show --direct | grep -E 'type-coverage|type-perfect'
vendor/bin/phpstan analyse --memory-limit=2G
```

Expect exactly one line: `tomasvotruba/type-coverage` at `2.3.x`, and no `rector/type-perfect`. PHPStan must reach analysis — a boot-time duplicate-service error is the failure this step exists to remove.

## Apply MISSING dev deps

Per-category mandatory `require-dev` for `laravel-project`:

- `larastan/larastan`
- `laravel/boost`
- `laravel/pail`
- `laravel/tinker` (Laravel may ship this already)
- `driftingly/rector-laravel`
- `sandermuller/project-boost-laravel` (`^1.5`) — only when the user accepted it at the top of this phase, or the app already carries it at a constraint that can resolve below 1.5.0: raise that constraint, because the sync steps below rely on 1.5's reconcile behaviour. When the user declined, skip it, `sandermuller/boost-skills`, the auto-sync hooks, and the voice and remote-skills steps below.
- `sandermuller/boost-skills` (`^2.27.0`) — with the wrapper only; without boost-core nothing syncs it. Run `composer require --dev "sandermuller/boost-skills:^2.27.0"` only when the declared constraint can resolve below 2.27.0 or the package is absent.

Plus shared dev deps from `$REPO_INIT_HOME/references/shared-dev-deps.md` minus what Laravel installer typically already ships (read freshly-generated composer.json to confirm): `laravel/pao`, `laravel/pint` (already), `phpstan/extension-installer`, `phpstan/phpstan-strict-rules`, `phpstan/phpstan-deprecation-rules`, `phpstan/phpstan-phpunit`, `rector/rector`, `spaze/phpstan-disallowed-calls`, `symplify/phpstan-rules` (`^14.17` — see shared-dev-deps.md "Symplify formatter dep"), `tomasvotruba/cognitive-complexity`, `tomasvotruba/type-coverage` (`^2.3` — it bundles the abandoned `rector/type-perfect`, which must NOT be installed alongside it; see shared-dev-deps.md "Type-perfect dep"), `nunomaduro/collision` (Laravel ships), `orchestra/testbench` (typically NOT in laravel-project — skip). `laravel-project` does NOT take `sandermuller/package-boost-php` — `sandermuller/project-boost-laravel` (above) is its boost-family member.

Plus confirmed opt-ins:

- `--with-hihaho-rules`: `hihaho/phpstan-rules`, `hihaho/rector-rules`, `symplify/phpstan-rules`

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

  laravel-project does NOT get a `sync-ai` script — AI-asset sync is `php artisan project-boost:sync`, which the two hooks below run. A `sync-ai` that calls the bare `vendor/bin/boost sync` bypasses the wrapper.

  **`post-install-cmd` / `post-update-cmd` are scaffold-conditional**: the canonical value — the dev-mode-guarded `@php -r` one-liner, copied verbatim from `references/composer-scripts.md` — applies when `sandermuller/project-boost-laravel` is in `require-dev`. Detect on the wrapper, NOT on `sandermuller/boost-core` — the wrapper pulls boost-core transitively, so boost-core's presence proves nothing. If the wrapper is absent, skip these two keys entirely. Three MISMATCH shapes, all HIGH severity, all prompted before patching: a POSIX-shell value (Windows-broken, and there is no `vendor/bin/boost` here); `["SanderMuller\\BoostCore\\Scripts\\BoostAutoSync::run"]` (autoloads and reports success, but bypasses the wrapper's injection pipeline and syncs a smaller skill set); and an UNGUARDED `["@php artisan project-boost:sync"]` (fires under `composer install --no-dev`, where the dev-only command does not exist, and aborts the install). With the wrapper present, replace any of the three with the guarded one-liner; without it, REMOVE the boost ENTRY — never the key. The Laravel skeleton ships its own `post-update-cmd` (`@php artisan vendor:publish --tag=laravel-assets --ansi --force`); deleting the key drops Laravel's asset publishing. Append the boost entry after the handlers already there. Exception: when the "Decide" step removed the boost entry, skip it here — "Sync AI assets" adds it after `project-boost:reconcile`.
- **`scripts.dev`**: if absent, suggest adding the multi-process dev script (concurrent server + queue + pail + vite). This is laravel-project canonical. Show example, ask before inserting.
- **`config.allow-plugins`**: insert `phpstan/extension-installer: true`, `pestphp/pest-plugin: true` (if pest), `php-http/discovery: true` (Laravel default).
- **`config.sort-packages`**: set to `true`.

Don't touch `extra.laravel.providers` for laravel-project — Laravel uses `extra.laravel.dont-discover` etc.; user owns the `extra.laravel.*` block.

## Apply NON-CANONICAL fixes (each prompted)

- **Licence is not proprietary**: prompt "set `composer.json` `license` to `proprietary`?" and, when a `LICENSE` file holds an open-source licence, "delete `LICENSE`?" Ask for each; the user can decline either. If `README.md` links to `LICENSE` or says this project is open source, prompt to update that text in the same pass, so the README does not contradict `composer.json`. The stock Laravel README line about the framework's own MIT licence is not a claim about the project.
- **`php artisan boost:update` in a composer script** (with the wrapper only): prompt, then remove that entry. Leave the array's other handlers in place.
- **`phpunit.xml` (no .dist)**: prompt "rename to `phpunit.xml`?" Only if `.dist` doesn't already exist.
- **PHPUnit cache findings** (if `test-framework=phpunit`): apply `$REPO_INIT_HOME/references/phpunit-config.md` Upgrade-actions section — set `cacheDirectory=".cache/phpunit"`, `rm -rf .phpunit.cache`, `git rm -r --cached .phpunit.cache` if previously committed.
- **CI path filter drift — `phpstan.yml` missing `composer.json` / `composer.lock`**: insert both lines under the `push.paths` and `pull_request.paths` blocks in `.github/workflows/phpstan.yml`.
- **`.gitattributes` missing `.ai/ export-ignore`**: insert `.ai/ export-ignore` line after `.agents/ export-ignore` inside the `# >>> package-boost (managed) >>>` block.
- **PHP floor below the category floor**: prompt "bump `require.php` to `^8.4` (`^8.5` for `laravel-project`)?" The bump is ATOMIC with the type-perfect / symplify migration above — both successors need PHP `^8.4`.
- **Both larastan + bare phpstan**: prompt to remove `phpstan/phpstan`.
- **`composer.lock` NOT committed** (rare — Laravel convention is to commit it for apps): prompt to add to git.
- **Two managed blocks in `.gitattributes`**: same as upgrade-laravel-package.md.
- **Inline `@php(...)` directive in Blade**: prompt, then rewrite each hit as a `@php ... @endphp` block — one statement per line, each ending in `;`. Apply MISSING files copies `InlinePhpDirectiveTest` earlier in this phase, and the suite stays red until every hit is rewritten — do both in the same pass. Then run `php artisan test --filter=InlinePhpDirective`.
- **`minimum-stability` / `prefer-stable`**: add `"minimum-stability": "stable"` + `"prefer-stable": true` to `composer.json` if absent or if `prefer-stable` isn't `true` (the Laravel skeleton ships both; see `references/version-defaults.md`). If `minimum-stability` is looser than `stable`, **default to tightening it to `stable`** — a deployed app rarely has a standing reason for a looser floor. Never loosen a passing `stable` baseline.

### Security canon fixes

Each is prompted. See `$REPO_INIT_HOME/references/laravel-security-canon.md`.

- **`config/session.php` flags on `env()`**: rewrite `encrypt`, `secure`, `http_only`, `partitioned` to the literal `true`. Keep the framework comment blocks. Warn the user that `secure => true` drops the session cookie on plain `http://` — local sites must serve HTTPS. Do not offer an `env()` escape hatch.
- **`same_site`**: `'strict'` → prompt for `'lax'`. `'none'` → leave it, but verify `secure => true` in the same pass and fix that first.
- **Session cookie name**: prompt only when the flags change in the same pass, and say plainly that the rename logs every session out. Never rename silently.
- **Dead `.env.example` keys**: remove `SESSION_ENCRYPT` and `SESSION_SECURE_COOKIE`. Both are real framework knobs, which is why a line left behind against a hard-coded config value is misleading rather than harmless.
- **`config/hsts.php`**: copy the stub. When the app does not already send a preload directive, ask before setting `preload => true` — confirm every subdomain serves HTTPS first, because preload-list removal takes months.
- **Middleware registered on `web` only**: move `SecurityHeaders` and `StrictTransportSecurity` from `->web(append: [...])` into `$middleware->append([...])`.
- **`mazedlx/feature-policy`**: prompt to remove the package, drop `config/feature-policy.php` and the `AddFeaturePolicyHeaders` registration, and set `Permissions-Policy` in `SecurityHeaders` instead.
- **CORS wildcard with credentials**: do NOT auto-fix. Report it and ask the user for the origin list — guessing it breaks the app's clients.
- **`config/app.php` `debug`**: rewrite to `(bool) env('APP_DEBUG', false)`. Leave hihaho's assign-then-override shape alone; it is equivalent.
- **bcrypt rounds**: only when a published `config/hashing.php` sets fewer than 12. Offer to delete the published file instead — the framework default is already 12.

After any of these, run the integrity test — it is the check that the stack still
sends what the canon says it sends:

```bash
php artisan test --filter=ApplicationIntegrity
```

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

## Ensure the `voice` and `laravel` tags are set

**Skip if:** the app does not carry `sandermuller/project-boost-laravel`, OR the boost config's `withTags([...])` already contains `'voice'` and `'laravel'` (or `Tag::Laravel`), lists `sandermuller/boost-skills` in `withAllowedVendors()`, and `sandermuller/boost-skills` is at `^2.27.0` or higher.

The tag ships `sandermuller/boost-skills`' writing-voice guideline into `AGENTS.md`. It is structural, not a user knob — never prompt to drop it.

1. Add `'voice'` to the `withTags([...])` array — put it first — and `'laravel'` when neither `'laravel'` nor `Tag::Laravel` is there: the wrapper filters its injected `laravel/boost` skills by tag, so without it `laravel-best-practices` never ships. If the config has NO `withTags(...)` call, add `->withTags(['voice', 'laravel'])`.
2. Add `'sandermuller/boost-skills'` to `withAllowedVendors([...])` when absent.
3. The `^2.27.0` floor comes from the dev-dep step above. The tag and the floor move together.

## Ensure the canonical remote skills

**Skip if:** the app does not carry `sandermuller/project-boost-laravel`.

Apply the upgrade step in `$REPO_INIT_HOME/references/remote-skills.md` to the boost config.

## Sync AI assets

With `sandermuller/project-boost-laravel`:

```bash
php artisan project-boost:reconcile   # only while CLAUDE.md / AGENTS.md still hold a <laravel-boost-guidelines> block
php artisan project-boost:sync        # otherwise, and every later sync
```

When this run removed the boost entry (see the "Decide" step), add the guarded boost entry to `post-install-cmd` / `post-update-cmd` now, after `project-boost:reconcile` — copied verbatim from `$REPO_INIT_HOME/references/composer-scripts.md`.

`project-boost:reconcile` backs the seeded files up to `.boost-reconcile/` and captures any hand-authored text outside `laravel/boost`'s marker into `.ai/guidelines/`. Show the user what it captured before deleting `.boost-reconcile/`. Then confirm `.claude/skills/security-audit/SKILL.md` exists and `AGENTS.md` carries the voice guideline. Never run `php artisan boost:update` or the bare `vendor/bin/boost sync` here — see the `project-boost-laravel` configuration guide, "Things to avoid".

Without the wrapper (the user declined it), `laravel/boost` keeps the sync: `php artisan boost:update`, or `php artisan boost:install` when it is not installed yet.

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
