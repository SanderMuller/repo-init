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

## Apply MISSING dev deps

Per-category mandatory `require-dev` for `laravel-package`:

- `larastan/larastan` (NEVER also `phpstan/phpstan` per §5.3 exclusivity)
- `laravel/boost` — required for `testbench.yaml` to boot (lists `Laravel\Boost\BoostServiceProvider`). Missing → `boost sync` / `testbench` fatals with `Class "Laravel\Boost\BoostServiceProvider" not found`. Added in repo-init 0.2.5.
- `driftingly/rector-laravel`
- `sandermuller/package-boost-laravel` — the Laravel-flavoured boost umbrella (pulls `sandermuller/boost-core` + `sandermuller/package-boost-php` transitively). Replaced the bare `package-boost-php` for Laravel-category packages in repo-init 0.5.0.

Plus shared dev deps from `$REPO_INIT_HOME/references/shared-dev-deps.md` (universal — `laravel/pao`, `laravel/pint`, `phpstan/extension-installer`, `phpstan/phpstan-strict-rules`, `phpstan/phpstan-deprecation-rules`, `phpstan/phpstan-phpunit`, `rector/rector`, `rector/type-perfect`, `spaze/phpstan-disallowed-calls`, `symplify/phpstan-extensions`, `tomasvotruba/cognitive-complexity`, `tomasvotruba/type-coverage`, `nunomaduro/collision`, `orchestra/testbench`, `sandermuller/boost-skills`).

Test-framework split (Pest by default for sander vendor):

- `pest`: `pestphp/pest`, `pestphp/pest-plugin-arch`, `pestphp/pest-plugin-laravel`, `mrpunyapal/rector-pest`
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

  The MISMATCH case is load-bearing. Common drift: `post-install-cmd` is a POSIX-shell conditional referencing `vendor/bin/boost sync` (or older `vendor/bin/testbench package-boost:sync`) — Windows-broken, predates boost-core 0.6's PHP callback. Canonical form is the array `["SanderMuller\\PackageBoostLaravel\\Scripts\\AutoSync::run"]`. Same drift class: `post-update-cmd` is often missing entirely from the same scaffold (the old conditional only wired `post-install-cmd`). Treat both as HIGH severity. **Floor coupling (ATOMIC):** whenever this step WRITES a `PackageBoostLaravel` façade callback into `post-install-cmd`/`post-update-cmd` — whether INSERTING a missing hook (the MISSING case) OR swapping an old `BoostCore\\Scripts\\BoostAutoSync::run` value (the MISMATCH case) — it MUST, in the same patch, ensure `sandermuller/package-boost-laravel` in `require-dev` is at `^0.10.0` (bump if lower: `composer require --dev "sandermuller/package-boost-laravel:^0.10.0"`). The façade class first ships in 0.10.0; writing the façade callback while the floor allows a pre-0.10 version leaves the autosync hook referencing a non-autoloadable class — Composer skip-warns (`class_exists()` guard in its `EventDispatcher`) and the hook silently no-ops on the next `composer install`/`update`, so autosync stays dead until the floor is fixed. This bites the partial-drift case especially: a scaffold that has only `post-install-cmd` (and is below the floor) gets `post-update-cmd` inserted as the façade callback — non-autoloadable until the floor moves with it. Never write the façade callback without ensuring the floor in the same patch — see the ATOMIC RULE in `composer-scripts.md`.
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
- **`minimum-stability` / `prefer-stable` deviation**: add `"minimum-stability": "stable"` + `"prefer-stable": true` to `composer.json` if absent or if `prefer-stable` isn't `true`. If `minimum-stability` is looser than `stable`, **prompt before tightening** — a deliberate early-stage `dev` + `prefer-stable: true` setup is valid (see `references/version-defaults.md`); never loosen a passing `stable` baseline.

## Migrate boost config to `.config/` (canonical layout)

**Skip if:** `.config/boost.php` exists AND no root `boost.php` exists (already on the canonical layout).

boost-core ≥ 0.17's canonical config location is `.config/boost.php`; audit flags a legacy root `boost.php` as drift. To migrate:

1. **MOVE the file** — `mkdir -p .config && git mv boost.php .config/boost.php`. **Never copy** — leaving both `boost.php` and `.config/boost.php` is a hard error (`AmbiguousBoostConfigException`); every `boost` command then throws.
2. **Ensure boost-core ≥ 0.18** (the `.config/boost/` manifest layout): the `sandermuller/package-boost-laravel` umbrella pulls boost-core ≥ 0.18 transitively (via package-boost-php ≥ 0.16.2) — run `composer update sandermuller/package-boost-laravel`. No direct boost-core require to bump.
3. Run `vendor/bin/boost sync` — it auto-migrates the gitignored sync manifest `.boost/ → .config/boost/`, rewrites the managed `.gitignore` block to ignore `.config/boost/`, and refreshes the managed `.gitattributes` block. Migration is bidirectional + automatic; `vendor/bin/boost sync --check` reports the one-time stale-manifest cleanup as advisory only (never drift).
4. **`.gitattributes`:** ensure `.config/ export-ignore` is in the `# >>> package-boost (managed) >>>` block (preserved as a foreign line by the writer); remove any stale `boost.php export-ignore` line. If the package ships a `.lpv`, replace any `boost.php` glob with `.config/`.
5. **Both-present guard:** if a prior bad copy left BOTH `boost.php` and `.config/boost.php`, do NOT run `boost sync` until resolved — delete the root `boost.php`, keep `.config/boost.php`.

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
