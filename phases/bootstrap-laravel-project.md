# Bootstrap: laravel-project

Greenfield setup of a full Laravel application. Wraps `laravel new` from the Laravel installer, then layers our additions (hihaho rule packs, our pint/phpstan/rector configs, GitHub workflows, .ai/ skeleton).

**Idempotent.** Each mutating step has a `Skip if:` precondition. Re-running this phase against an already-bootstrapped target is a no-op. See SPEC.md RQ41.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`. Stop if anything is red. Verify category-fit per `$REPO_INIT_HOME/references/detection-rules.md`. Placeholder transforms used in this phase come from `$REPO_INIT_HOME/references/placeholder-rules.md`.

Verify the Laravel installer is available:

```bash
which laravel
```

If not installed, ask the user:

> The Laravel installer isn't on your PATH. Install with `composer global require laravel/installer`, then re-invoke.

## Inputs to collect

- `vendor` (e.g. `hihaho`, custom) — required.
- `name` (kebab-case) — optional per target-dir rule.
- `description` — required.
- `php` — default `8.3`. Accepted: `8.3`, `8.4`, `8.5`. Reject `8.2`.
- `author-name` / `author-email` — defaults from git config.
- `with-hihaho-rules` — default `y` for vendor=hihaho, `N` otherwise.
- `with-security-advisories` — default `N`.
- `--boost` flag — `laravel new --boost` installs `laravel/boost` (MCP wiring, AGENTS.md / CLAUDE.md scaffolding, `boost.json`). Default ON. Use `--no-boost` only if the user explicitly opts out (then `composer require laravel/boost` runs as a separate step). The installer also auto-detects agent context via env for JSON output — no flag needed for that.

## Steps

### 1. Apply target-dir rule

- If user passed positional `name`: `laravel new <name>` creates `./<name>/` and the Laravel skeleton inside.
- Otherwise: target IS cwd. `laravel new .` runs in cwd. Verify cwd is empty modulo `.git/` first; if not, stop and ask for a `name`.

### 2. Run the Laravel installer

**Skip if:** `composer.json` exists in target cwd AND has `laravel/framework` in `require` (Laravel skeleton already in place — could be from a prior run or external setup).

Preferred:

```bash
laravel new <name> --boost --git --no-interaction
```

The `--boost` flag installs `laravel/boost`, which wires up MCP, `boost.json`, and AGENTS.md / CLAUDE.md scaffolding — reduces overlap with our subsequent steps. Add `--pest` to switch the test framework at install time, or omit for PHPUnit. Pass `--database=<driver>` if the user named one in inputs (otherwise the installer prompts).

If the user explicitly opted out of Boost:

```bash
laravel new <name> --no-boost --git --no-interaction
```

`laravel/boost` then comes in via §5's `composer require` instead, so the boost MCP/AGENTS scaffolding still lands — just outside the installer flow.

### 3. cd into the new dir

```bash
cd <name>     # skip if `laravel new .` was used
```

### 4. Inspect what `laravel new` already installed

Read the freshly-generated `composer.json`. The agent skips re-installing anything already present (per RQ29 — read freshly-generated composer.json to detect what the installer already brought in).

Likely already present (when `--boost` was used):

- `laravel/boost`
- `laravel/mcp` (pulled transitively by boost)
- `laravel/pint`

### 5. Install our additional dev deps

**Skip if:** every dep in the list below is already in `composer.json` `require-dev` (per `composer show --installed <dep>` AND not in `--no-dev` filter). For partial overlap, install only the missing deps.

Build the list from `$REPO_INIT_HOME/references/per-category-deps.md#laravel-project`:

**MANDATORY:**

- `larastan/larastan`
- `laravel/pail`
- `laravel/tinker` (Laravel may already include this — check)
- `driftingly/rector-laravel`
- All shared deps from `$REPO_INIT_HOME/references/shared-dev-deps.md` minus anything Laravel installer already pulled. Read the freshly-generated `composer.json` to determine what's already there. Common already-installed by `laravel new`: `laravel/pint`, `nunomaduro/collision`, `phpunit/phpunit` (when test-framework=phpunit). Anything else from the shared list needs explicit `composer require --dev`: `laravel/pao`, `phpstan/extension-installer`, `phpstan/phpstan-strict-rules`, `phpstan/phpstan-deprecation-rules`, `phpstan/phpstan-phpunit`, `rector/rector`, `rector/type-perfect`, `spaze/phpstan-disallowed-calls`, `symplify/phpstan-extensions`, `tomasvotruba/cognitive-complexity`, `tomasvotruba/type-coverage`, `sandermuller/package-boost-php`.

**OPTIONAL (only when opted in):**

- `with-hihaho-rules` (default `y` for vendor=hihaho): `hihaho/phpstan-rules`, `hihaho/rector-rules`, `symplify/phpstan-rules`.
- `with-security-advisories` (default `N`): `roave/security-advisories: dev-latest`.

**Test framework** (default `phpunit` for laravel-project — Laravel ships PHPUnit by default; switching to Pest is a user opt-in):

- For PHPUnit: nothing extra (Laravel includes `phpunit/phpunit`).
- For Pest: also add `pestphp/pest`, `pestphp/pest-plugin-arch`, `pestphp/pest-plugin-laravel`, `mrpunyapal/rector-pest`. Note: switching from PHPUnit to Pest changes how `php artisan test` resolves; the user must `vendor/bin/pest --init` separately to migrate.

Single batched call:

```bash
composer require --dev <pkg1> <pkg2> <pkg3> ...
```

Skip packages already in `composer.json`. On failure, consult `$REPO_INIT_HOME/references/composer-failure-modes.md`.

### 6. Overlay our shared stubs (with prompts for conflicts)

**Skip per-file if:** the equivalent file already exists at the target path AND its contents match `$REPO_INIT_HOME/stubs/shared/<file>` after placeholder substitution (no literal `__VENDOR__` etc. remaining).

For each file in `$REPO_INIT_HOME/stubs/shared/`:

- If the file doesn't exist in cwd: copy it, substitute placeholders.
- If the file exists (Laravel installer wrote it): show diff, prompt: `w` write / `s` skip / `b` backup-and-write / `a` abort.

Likely conflicts:

- `.editorconfig` — Laravel ships its own. Ours overrides for strict utf-8 + lf + 4-space.
- `.gitattributes` — Laravel's is minimal; ours adds the package-boost managed block. **Use `managed-block` merge mode** (per `$REPO_INIT_HOME/references/upgrade-merge-modes.md`) — don't replace; insert our entries inside (or alongside) Laravel's content.
- `phpunit.xml` — already present from Laravel. **Skip ours** (Laravel's is more app-appropriate).
- `tests/Pest.php` — skip unless user opted into Pest in step 5.
- `.github/workflows/` — Laravel may have its own (`tests.yml`, etc.); ours adds `phpstan.yml`, `pint-check.yml`, `rector-check.yml`, `update-changelog.yml`. Different filenames → no conflict; just add.
- `.mcp.json` — `laravel/boost` writes this on install. If absent (user opted out of Boost), copy ours.

### 7. Overlay laravel-project-specific stubs

**Skip per-file if:** the file already exists at target path AND contents match the stub after placeholder substitution. For `README.append.md` specifically: skip if the README already contains the appended content (grep for a sentinel phrase like "Code-quality tooling" section heading).

For each file in `$REPO_INIT_HOME/stubs/laravel-project/`:

- `boost.json` — `laravel/boost` writes this on install. If absent (user opted out of Boost), copy ours.
- `phpstan.neon.dist` — copy. Project uses paths `[app, routes, config, database, tests]` (NOT `src tests` — see RQ7).
- `rector.php` — copy. Project uses `withPaths([app, routes, config, database, tests])`. When `with-hihaho-rules`, also adds `Hihaho\RectorRules\Sets::ALL`.
- `README.append.md` — append its content to the existing `README.md` (Laravel ships a README); never overwrite.

Substitute placeholders.

### 8. Extend `.gitignore` with project-only extras

Add lines (`append-only` mode — never reorder/remove existing):

```
/public/build
/public/hot
/public/storage
/storage/pail
_ide_helper.php
_ide_helper_models.php
.phpstorm.meta.php
```

Dedupe — don't add a line that's already there.

### 9. Sync AI assets

**Skip if:** `.claude/skills/repo-init/SKILL.md` exists in target cwd AND content matches `vendor/sandermuller/repo-init/resources/boost/skills/repo-init/SKILL.md` (project-local sync already done). If syncing from global instead, no project-local copy is expected.

Sync via boost-core's standalone bin (pulled transitively through `sandermuller/package-boost-php`; framework-agnostic, no artisan command):

```bash
vendor/bin/boost sync
```

This propagates `.ai/skills/` and `.ai/guidelines/` from anywhere they're declared (shared package-boost-php defaults, plus any deps that ship them) into `.claude/skills/`, `.cursor/skills/`, `.github/skills/`, etc.

`laravel new --boost` writes `boost.json` for the `laravel/boost` package (MCP wiring). That's separate from boost-core's auto-sync trigger, which looks for `boost.php` — not generated by this bootstrap. If you want boost-core to auto-sync on every subsequent `composer install/update`, run `composer boost:install --no-interaction` once to generate `boost.php`. Otherwise re-run `vendor/bin/boost sync` manually after edits to `.ai/`.

If repo-init is also installed in this project locally (escape hatch, rare), its skill propagates here too.

### 10. Run post-bootstrap verification

Open `$REPO_INIT_HOME/checklists/post-bootstrap-verification.md`.

Additionally for laravel-project:

```bash
php artisan --version          # confirm Laravel installed cleanly
php artisan test               # smoke-test the default test suite
composer phpstan-simplified    # PHPStan baseline pass
```

### 11. Print next steps

```
✓ Bootstrap done for {vendor}/{name} (laravel-project).

Next:
- Edit .env (copy .env.example if .env doesn't exist): set APP_NAME, APP_URL, DB_*, MAIL_*.
- Run `php artisan migrate` to set up the database.
- Run `composer dev` to start the dev server (or `php artisan serve` for just the web app).
- Set up the GitHub remote — ask the user whether `--public` or `--private` first (Laravel apps are commonly private but not always): `gh repo create {vendor}/{name} --public|--private --source=. --remote=origin --push`.
- Run `composer qa` to confirm baseline passes.
{when --with-hihaho-rules: - Hihaho rules are active; check phpstan.neon.dist for the include.}

Want to run an audit next (`phases/audit-laravel-project.md`), or are you done with repo-init for now?
```

## What's next

- User wants to keep working: open `$REPO_INIT_HOME/phases/audit-laravel-project.md`.
- User is done: nothing to remove (repo-init lives globally, not in this target).

## Idempotency invariants (RQ41 contract)

Re-running this phase against a target where all steps' post-conditions are already met must be a no-op: no `laravel new`, no `composer require`, no stub overwrites, no `package-boost:sync`. Steps 1, 3, 4, 10, 11 are read-only and always run. Steps 2, 5-9 have explicit `Skip if:` preconditions.

Tested in CI via `check-bootstrap-idempotency.sh`.

## Common issues

- **`laravel new --boost` flag not recognized**: installer version too old (pre-5.x). `composer global update laravel/installer`, then retry. As a last resort, omit `--boost` and let §5 install `laravel/boost` via `composer require` after the skeleton lands.
- **`hihaho/phpstan-rules` not found on Packagist**: it's a private/internal package; user needs auth.json or to be on the hihaho composer auth. Document this in the failure mode, then escalate.
- **PHPUnit + Pest both installed by accident**: pick one. Remove the other with `composer remove --dev <the wrong one>`. Pest is the harder one to remove (also touches `tests/Pest.php`).
- **`composer dev` fails**: this depends on the `dev` script in composer.json (concurrent server + queue + pail + vite). If Vite isn't set up, edit the script or run pieces individually.
