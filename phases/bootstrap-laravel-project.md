# Bootstrap: laravel-project

Greenfield setup of a full Laravel application. Wraps `laravel new` from the Laravel installer, then layers our additions (hihaho rule packs, our pint/phpstan/rector configs, GitHub workflows, .ai/ skeleton).

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
- `--ai` flag support — verify the installed Laravel installer version supports `--ai` (Laravel installer ≥ X.Y). If not, fall back to plain `laravel new` and warn the user that some AI scaffolding is skipped (they can run `composer require laravel/boost` manually after).

## Steps

### 1. Apply target-dir rule

- If user passed positional `name`: `laravel new <name>` creates `./<name>/` and the Laravel skeleton inside.
- Otherwise: target IS cwd. `laravel new .` runs in cwd. Verify cwd is empty modulo `.git/` first; if not, stop and ask for a `name`.

### 2. Run the Laravel installer

Preferred (when `--ai` flag is supported):

```bash
laravel new <name> --ai
```

The `--ai` flag wires up MCP (laravel/mcp), the boost.json template, AGENTS.md / CLAUDE.md scaffolding, and other AI-tooling defaults. This reduces overlap with our subsequent steps.

Fallback (when `--ai` not supported):

```bash
laravel new <name>
```

Then proceed with the additions — they'll do the AI scaffolding manually.

### 3. cd into the new dir

```bash
cd <name>     # skip if `laravel new .` was used
```

### 4. Inspect what `laravel new --ai` already installed

Read the freshly-generated `composer.json`. The agent skips re-installing anything already present (per RQ29 — read freshly-generated composer.json to detect what --ai already installed).

Likely already present (when `--ai` was used):

- `laravel/boost`
- `laravel/mcp`
- maybe `laravel/pint`

### 5. Install our additional dev deps

Build the list from `$REPO_INIT_HOME/references/per-category-deps.md#laravel-project`:

**MANDATORY:**

- `larastan/larastan`
- `laravel/pail`
- `laravel/tinker` (Laravel may already include this — check)
- `driftingly/rector-laravel`
- All shared deps from `$REPO_INIT_HOME/references/shared-dev-deps.md` minus anything Laravel installer already pulled. Read the freshly-generated `composer.json` to determine what's already there. Common already-installed by `laravel new`: `laravel/pint`, `nunomaduro/collision`, `phpunit/phpunit` (when test-framework=phpunit). Anything else from the shared list needs explicit `composer require --dev`: `laravel/pao`, `phpstan/extension-installer`, `phpstan/phpstan-strict-rules`, `phpstan/phpstan-deprecation-rules`, `phpstan/phpstan-phpunit`, `rector/rector`, `rector/type-perfect`, `spaze/phpstan-disallowed-calls`, `symplify/phpstan-extensions`, `tomasvotruba/cognitive-complexity`, `tomasvotruba/type-coverage`, `sandermuller/package-boost`.

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

For each file in `$REPO_INIT_HOME/stubs/shared/`:

- If the file doesn't exist in cwd: copy it, substitute placeholders.
- If the file exists (Laravel installer wrote it): show diff, prompt: `w` write / `s` skip / `b` backup-and-write / `a` abort.

Likely conflicts:

- `.editorconfig` — Laravel ships its own. Ours overrides for strict utf-8 + lf + 4-space.
- `.gitattributes` — Laravel's is minimal; ours adds the package-boost managed block. **Use `managed-block` merge mode** (per `$REPO_INIT_HOME/references/upgrade-merge-modes.md`) — don't replace; insert our entries inside (or alongside) Laravel's content.
- `phpunit.xml.dist` — already present from Laravel. **Skip ours** (Laravel's is more app-appropriate).
- `tests/Pest.php` — skip unless user opted into Pest in step 5.
- `.github/workflows/` — Laravel may have its own (`tests.yml`, etc.); ours adds `phpstan.yml`, `pint-check.yml`, `rector-check.yml`, `update-changelog.yml`. Different filenames → no conflict; just add.
- `.mcp.json` — if `--ai` flag was used, this exists. Otherwise copy ours.

### 7. Overlay laravel-project-specific stubs

For each file in `$REPO_INIT_HOME/stubs/laravel-project/`:

- `boost.json` — if `--ai` flag was used, this exists. Otherwise copy ours.
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

For laravel-project, package-boost is invoked via artisan (not testbench):

```bash
php artisan package-boost:sync
```

This propagates `.ai/skills/` and `.ai/guidelines/` from anywhere they're declared (shared package-boost defaults, plus any deps that ship them) into `.claude/skills/`, `.cursor/skills/`, `.github/skills/`, etc.

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

## Common issues

- **`laravel new --ai` flag not recognized**: installer version too old. `composer global update laravel/installer`, then retry. Fallback path is documented above.
- **`hihaho/phpstan-rules` not found on Packagist**: it's a private/internal package; user needs auth.json or to be on the hihaho composer auth. Document this in the failure mode, then escalate.
- **PHPUnit + Pest both installed by accident**: pick one. Remove the other with `composer remove --dev <the wrong one>`. Pest is the harder one to remove (also touches `tests/Pest.php`).
- **`composer dev` fails**: this depends on the `dev` script in composer.json (concurrent server + queue + pail + vite). If Vite isn't set up, edit the script or run pieces individually.
