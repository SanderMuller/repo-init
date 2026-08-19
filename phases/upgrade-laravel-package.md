# Upgrade: laravel-package

Apply the audit findings. Re-runs the audit fresh as the first step so the upgrade operates on a current, in-conversation finding list (no persisted state to drift).

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md` AND re-run the audit phase: open `$REPO_INIT_HOME/phases/audit-laravel-package.md`, walk it end-to-end, hold the findings in conversation.

## Honor the safety rails (every write step)

For every file write in the steps below:

- Check `$REPO_INIT_HOME/checklists/per-category-never-touch.md` — never write to a never-touch path.
- Check git-dirty rule: run `git status --porcelain`. Skip paths with prefixes `M`, `M`, `MM`, `A`, `??` (modified, staged, or untracked). Override requires explicit user opt-in per file.
- Verify category-fit once more via `$REPO_INIT_HOME/references/detection-rules.md`; dep expectations come from `$REPO_INIT_HOME/references/per-category-deps.md`.

If a write is blocked, surface to user with the gap finding and the rule that blocked it.

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

For each MISSING file from the audit:

1. Read the stub from `$REPO_INIT_HOME/stubs/<shared|laravel-package|laravel-package-spatie>/<path>`.
2. Substitute placeholders using the inputs collected from the user (or re-read from the existing `composer.json`: vendor + name come from `name` field; namespace from `autoload.psr-4`; php from `require.php`; etc.).
3. Write to target path. If overwriting an existing file (shouldn't happen for MISSING, but defensive), prompt: write / skip / backup-and-write (`<path>.bak.<timestamp>`) / abort.

## Apply MISSING runtime deps

Per-category mandatory `require` for `laravel-package`:

- `illuminate/contracts: __LARAVEL_VERSIONS__`
- `illuminate/support: __LARAVEL_VERSIONS__`
- (sub-flag `hihaho-package-tools-flavoured`) `spatie/laravel-package-tools`

Single batched `composer require <list>` for everything missing.

On failure, consult `$REPO_INIT_HOME/references/composer-failure-modes.md`.

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

Per-category mandatory `require-dev` for `laravel-package`:

- `larastan/larastan` (NEVER also `phpstan/phpstan` per §5.3 exclusivity)
- `laravel/boost` — required for `testbench.yaml` to boot (lists `Laravel\Boost\BoostServiceProvider`). Missing → `boost sync` / `testbench` fatals with `Class "Laravel\Boost\BoostServiceProvider" not found`. Added in repo-init 0.2.5.
- `driftingly/rector-laravel`
- `sandermuller/package-boost-laravel` — the Laravel-flavoured boost umbrella (pulls `sandermuller/boost-core` + `sandermuller/package-boost-php` transitively). Replaced the bare `package-boost-php` for Laravel-category packages in repo-init 0.5.0.

Plus shared dev deps from `$REPO_INIT_HOME/references/shared-dev-deps.md` (universal — `laravel/pao`, `laravel/pint`, `phpstan/extension-installer`, `phpstan/phpstan-strict-rules`, `phpstan/phpstan-deprecation-rules`, `phpstan/phpstan-phpunit`, `rector/rector`, `rector/type-perfect` (`^2.1` — PHP 8.3 floor ONLY; DROP on a PHP >= 8.4 floor), `spaze/phpstan-disallowed-calls`, `symplify/phpstan-rules` (`^14.11`, PHP >= 8.4 floor; PHP 8.3 floor keeps `symplify/phpstan-extensions: ^12.0` — see shared-dev-deps.md "Symplify formatter dep"), `tomasvotruba/cognitive-complexity`, `tomasvotruba/type-coverage` (`>=2.2.0 <2.2.2` on a PHP 8.3 floor — the `<2.2.2` cap is mandatory; `^2.3` on a PHP >= 8.4 floor, where it replaces `rector/type-perfect` — see shared-dev-deps.md "Type-perfect dep"), `nunomaduro/collision`, `orchestra/testbench`, `sandermuller/boost-skills`).

Test-framework split (Pest by default for sander vendor):

- `pest`: `pestphp/pest: ^5.0`, `pestphp/pest-plugin-arch: ^5.0`, `pestphp/pest-plugin-laravel: ^5.0`, `pestphp/pest-plugin-rector: ^5.0`, `pestphp/pest-plugin-phpstan: ^5.0`, `pestphp/pest-plugin-agent: ^5.0` — see the Pest 4 → 5 migration step above
- `phpunit`: `phpunit/phpunit`

Single batched `composer require --dev <list>` call.

Respect `larastan` vs `phpstan/phpstan` exclusivity (§5.3): never `composer require` both in the same call. If one is already installed, install only the other:

- Laravel-aware → install `larastan/larastan`, NOT bare `phpstan/phpstan`.
- (laravel-package is always Laravel-aware → larastan only.)

On failure, consult `references/composer-failure-modes.md`.

## Apply OUTDATED files per merge mode

For each OUTDATED file, apply the mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md`:

- **`replace`**: show unified diff, prompt: `[w]rite` / `[s]kip` / `[d]iff` (full) / `[b]ackup-and-write` / `[a]bort`. Default `[s]kip` if user has uncommitted changes to that file (per git-dirty rule).
- **`managed-block`** (`.gitattributes`): patch only inside the `# >>> package-boost (managed) >>>` block. Never touch lines outside. If our entries inside have drifted, surface diff + prompt.
- **`append-only`** (`.gitignore`): append missing lines per `$REPO_INIT_HOME/stubs/shared/.gitignore` not present in target. Dedupe — never insert a duplicate. Never remove or reorder existing.
- **`merge-keys`** (`composer.json`): see next section.
- **`notify-only`** (`phpstan.neon.dist`, `rector.php`, `pint.json`, `phpstan-baseline.neon`): never auto-overwrite. Show drift summary to user; ask if they want to manually align (link to the stub for reference). Take no action.

## Apply composer.json merge-keys patches

For each composer.json key documented in `$REPO_INIT_HOME/references/composer-scripts.md` and `$REPO_INIT_HOME/references/upgrade-merge-modes.md`, insert missing entries (surgical JSON patch, never whole-file rewrite). For the keys below, insert only what's missing — don't touch existing entries.

- **`scripts`**: **Read `$REPO_INIT_HOME/references/composer-scripts.md` IN FULL before patching.** Do NOT infer the canonical block from memory — audit reports have caught Windows-broken `post-install-cmd` + missing `post-update-cmd` slipping through because the agent auto-completed from training data. For each documented key (baseline 11 + workbench 5 for laravel-package): verify present in target with canonical value. Three cases:
  - **MISSING**: insert.
  - **PRESENT with canonical value**: leave.
  - **MISMATCH** (present with different value): prompt — show both sides, offer replace / skip. Do NOT silently leave drift in place.

  The MISMATCH case is load-bearing. Common drift: `post-install-cmd` is a POSIX-shell conditional referencing `vendor/bin/boost sync` (or older `vendor/bin/testbench package-boost:sync`) — Windows-broken, predates boost-core 0.6's PHP callback. Canonical form is the array `["SanderMuller\\PackageBoostLaravel\\Scripts\\AutoSync::run"]`. Same drift class: `post-update-cmd` is often missing entirely from the same scaffold (the old conditional only wired `post-install-cmd`). Treat both as HIGH severity. **Floor coupling (ATOMIC):** whenever this step WRITES a `PackageBoostLaravel` façade callback into `post-install-cmd`/`post-update-cmd` — whether INSERTING a missing hook (the MISSING case) OR swapping an old `BoostCore\\Scripts\\BoostAutoSync::run` value (the MISMATCH case) — it MUST, in the same patch, ensure `sandermuller/package-boost-laravel` in `require-dev` is at `^1.0` (bump if lower: `composer require --dev "sandermuller/package-boost-laravel:^1.0"`). The façade class first ships in 0.10.0; writing the façade callback while the floor allows a pre-0.10 version leaves the autosync hook referencing a non-autoloadable class — Composer skip-warns (`class_exists()` guard in its `EventDispatcher`) and the hook silently no-ops on the next `composer install`/`update`, so autosync stays dead until the floor is fixed. This bites the partial-drift case especially: a scaffold that has only `post-install-cmd` (and is below the floor) gets `post-update-cmd` inserted as the façade callback — non-autoloadable until the floor moves with it. Never write the façade callback without ensuring the floor in the same patch — see the ATOMIC RULE in `composer-scripts.md`.
- **`extra.laravel.providers`**: insert `__NAMESPACE__\\__PACKAGE_STUDLY__ServiceProvider` if missing. If existing array contains a different provider, ask user whether to add or replace.
- **`config.allow-plugins`**: insert `pestphp/pest-plugin: true` (when test-framework=pest) and `phpstan/extension-installer: true` (always) if missing. Remove stale entries — ORDER MATTERS for `package-boost-php`:
  - `sandermuller/boost-core: true` — safe to remove unconditionally (boost-core ≥ 0.6.0 is `type: library`).
  - `sandermuller/package-boost-laravel: true` — safe to remove unconditionally (always was `type: library`, never a plugin).
  - `sandermuller/package-boost-php: true` — safe to remove ONLY when the installed `sandermuller/package-boost-php` (pulled transitively via `package-boost-laravel`) is `≥ 0.9.0`. Verify with `composer show sandermuller/package-boost-php`. If `< 0.9.0`: FIRST bump `sandermuller/package-boost-laravel` in `require-dev` to a version that pulls `package-boost-php ^0.9` transitively (`^0.7.3`) and run `composer update sandermuller/package-boost-laravel --with-all-dependencies`. Removing the allow-plugins entry while package-boost-php is still `< 0.9.0` blocks `composer install` with a `blocked-plugin` error.

  All three are Composer-ignored once the corresponding package is library-typed (harmless but obsolete).
- **`config.sort-packages`**: set to `true` if absent.
- **`autoload-dev.psr-4`**: ensure `__NAMESPACE_ESCAPED__\\\\Tests\\\\: tests/` is present. If not, add. Don't override existing entries.
- **`autoload-dev.psr-4`** (workbench): ensure `Workbench\\\\App\\\\: workbench/app/` is present.

## Apply NON-CANONICAL fixes (each prompted)

For each NON-CANONICAL finding:

- **`composer.lock` committed**: prompt "remove composer.lock from git tracking? `git rm --cached composer.lock` + ensure `composer.lock` line is in `.gitignore`." User can decline.
- **`phpunit.xml` (without `.dist`)**: prompt "rename `phpunit.xml` → `phpunit.xml`?" Only do this if `phpunit.xml` doesn't already exist (don't clobber).
- **PHPUnit cache findings** (if `test-framework=phpunit`): apply `$REPO_INIT_HOME/references/phpunit-config.md` Upgrade-actions section — set `cacheDirectory=".cache/phpunit"`, `rm -rf .phpunit.cache`, `git rm -r --cached .phpunit.cache` if previously committed.
- **CI path filter drift — `phpstan.yml` missing `composer.json` / `composer.lock`**: insert both lines under the `push.paths` and `pull_request.paths` blocks in `.github/workflows/phpstan.yml`.
- **CI path filter drift — `run-tests.yml` missing `testbench.yaml` / `workbench/**`**: insert both lines under the `push.paths` and `pull_request.paths` blocks in `.github/workflows/run-tests.yml`. Same indentation as surrounding entries.
- **`.gitattributes` missing `.ai/ export-ignore`**: insert `.ai/ export-ignore` line after `.agents/ export-ignore` inside the `# >>> package-boost (managed) >>>` block.
- **PHP floor `^8.2`**: prompt "bump `require.php` from `^8.2` to `^8.3`?" Single-line composer.json edit. Warn that this may require Composer to re-resolve deps; suggest `composer update --lock` after.
- **Two managed blocks in `.gitattributes`**: prompt "merge the `# >>> repo-init (managed) >>>` block into the `# >>> package-boost (managed) >>>` block per the contract in `references/gitattributes-managed-block.md`?" Move repo-init's entries into package-boost's block (dedupe), then remove the standalone repo-init block.
- **Both `phpstan/phpstan` and `larastan/larastan` in `require-dev`**: prompt "remove `phpstan/phpstan` (transitively provided by larastan)?" `composer remove --dev phpstan/phpstan`.
- **`minimum-stability` / `prefer-stable`**: add `"minimum-stability": "stable"` + `"prefer-stable": true` to `composer.json` if absent or if `prefer-stable` isn't `true`. If `minimum-stability` is looser than `stable`, **default to tightening it to `stable`** — keep `dev` only when the author confirms the package is actively co-developed against unreleased sibling packages (being on `0.x`, or having downstream / production dependents, is a reason to tighten, NOT to keep `dev`; see `references/version-defaults.md`). Never loosen a passing `stable` baseline.

## Migrate boost config to `.config/` (canonical layout)

**Skip if:** `.config/boost.php` exists AND no root `boost.php` exists (already on the canonical layout).

boost-core ≥ 0.17's canonical config location is `.config/boost.php`; audit flags a legacy root `boost.php` as drift. To migrate:

1. **MOVE the file** — `mkdir -p .config && git mv boost.php .config/boost.php`. **Never copy** — leaving both `boost.php` and `.config/boost.php` is a hard error (`AmbiguousBoostConfigException`); every `boost` command then throws.
2. **Ensure boost-core ≥ 0.18** (the `.config/boost/` manifest layout): the `sandermuller/package-boost-laravel` umbrella pulls boost-core ≥ 0.18 transitively (via package-boost-php ≥ 0.16.2) — run `composer update sandermuller/package-boost-laravel`. No direct boost-core require to bump.
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

## Ensure the `voice` tag is set

**Skip if:** the boost config has a `withTags([...])` call that already contains `'voice'` AND `sandermuller/boost-skills` in `require-dev` is at `^2.27.0` or higher.

The canonical setup keeps the `voice` tag on in every repo that carries `sandermuller/boost-skills`. The tag ships that package's writing-voice guideline (`resources/boost/guidelines/voice.md`, mapped to `voice` in its `resources/boost/guidelines/.boost-tags.yaml`); without the tag the guideline never reaches `AGENTS.md` / `CLAUDE.md`. It is structural, not a user knob — never prompt to drop it.

```php
// before
->withTags([Tag::Php, Tag::Github])
// after
->withTags(['voice', Tag::Php, Tag::Github])
```

1. Add `'voice'` to the `withTags([...])` array — put it first, keep the other tags as they are (see the example above). If the config has NO `withTags(...)` call (a `boost install` run with nothing selected removes it), add `->withTags(['voice'])` to the builder chain.
2. **Floor coupling (ATOMIC):** in the same change, ensure `sandermuller/boost-skills` in `require-dev` cannot resolve below 2.27.0. Run `composer require --dev "sandermuller/boost-skills:^2.27.0"` ONLY when the declared constraint allows an older version; leave a constraint whose floor is already 2.27.0 or later (`^2.27.0`, `^3.0`, …) exactly as it is — rewriting it would downgrade the package. The tag is a silent no-op on a resolved version that does not ship the guideline, so the tag and the floor move together.
3. Run `vendor/bin/boost sync` and confirm the voice guideline lands in `AGENTS.md` / `CLAUDE.md`.

## Run boost-core sync to refresh AI assets

```bash
vendor/bin/boost sync
```

Ensures `.claude/skills/`, `.cursor/skills/`, etc. reflect the latest `.ai/skills/` content (relevant if the user added or updated skills as part of this upgrade). boost-core 0.6.0 removed the plugin path; the standalone `vendor/bin/boost` bin is the canonical sync entry point.

## Verification

Open `$REPO_INIT_HOME/checklists/post-upgrade-verification.md` and confirm every item.

## What's next

- User wants to keep working: open the next phase file or re-audit.
- User is done: stop. Repo-init lives globally — nothing to remove from this target.

## Common issues

- **`composer require` rejects a dep that's transitively pulled**: example, you can't directly require `phpstan/phpstan` when `larastan/larastan` is in `require-dev`. Skip the direct require; the audit shouldn't have flagged it (re-check audit logic).
- **`extra.laravel.providers` patch wants to add a different provider than already exists**: this likely means the package was renamed or the namespace shifted. Ask the user; don't auto-overwrite.
- **`composer update --lock` after PHP floor bump fails**: a transitive dep needs PHP >= 8.3 too. Surface the conflict; user may need to bump or remove the offending dep.
