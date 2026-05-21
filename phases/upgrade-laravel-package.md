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

- **`scripts`**: insert each script from `references/composer-scripts.md` (always-present block + workbench block always added for laravel-package) not present in target. Don't override scripts with the same name; prompt the user on conflict.
- **`extra.laravel.providers`**: insert `__NAMESPACE__\\__PACKAGE_STUDLY__ServiceProvider` if missing. If existing array contains a different provider, ask user whether to add or replace.
- **`config.allow-plugins`**: insert `pestphp/pest-plugin: true` (when test-framework=pest) and `phpstan/extension-installer: true` (always) if missing. Also insert `sandermuller/boost-core: true` and `sandermuller/package-boost-php: true` (MANDATORY — both are `type: composer-plugin` pulled in via `package-boost-laravel`; without them the first non-interactive `composer install` is blocked).
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

## Run package-boost sync to refresh AI assets

```bash
vendor/bin/testbench package-boost:sync
```

Ensures `.claude/skills/`, `.cursor/skills/`, etc. reflect the latest `.ai/skills/` content (relevant if the user added or updated skills as part of this upgrade).

## Verification

Open `$REPO_INIT_HOME/checklists/post-upgrade-verification.md` and confirm every item.

## What's next

- User wants to keep working: open the next phase file or re-audit.
- User is done: stop. Repo-init lives globally — nothing to remove from this target.

## Common issues

- **`composer require` rejects a dep that's transitively pulled**: example, you can't directly require `phpstan/phpstan` when `larastan/larastan` is in `require-dev`. Skip the direct require; the audit shouldn't have flagged it (re-check audit logic).
- **`extra.laravel.providers` patch wants to add a different provider than already exists**: this likely means the package was renamed or the namespace shifted. Ask the user; don't auto-overwrite.
- **`composer update --lock` after PHP floor bump fails**: a transitive dep needs PHP >= 8.3 too. Surface the conflict; user may need to bump or remove the offending dep.
