# Audit: laravel-project

Read-only check of an existing `laravel-project` repo against the canonical baseline.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`.

Verify detection per `$REPO_INIT_HOME/references/detection-rules.md`: target has `type: project` AND `laravel/framework` in `require`.

## Opt-in confirmation

Ask the user (with auto-inferred defaults):

- **`--with-hihaho-rules`?** Default `y` if vendor is `hihaho` OR `hihaho/phpstan-rules` already in `require-dev`. Otherwise default `N`. If `y`: audit also flags `hihaho/phpstan-rules`, `hihaho/rector-rules`, `symplify/phpstan-rules` as MISSING when absent.
- **`--with-security-advisories`?** Default `y` if `roave/security-advisories` already in `require-dev`. Otherwise default `N`. If `y`: flag `roave/security-advisories: dev-latest` as MISSING when absent.
- **`test-framework`** — detect from existing deps (presence of `pestphp/pest` vs `phpunit/phpunit`). Don't push to migrate; record the current state.

## MISSING files

**Shared (Laravel installer may have written some — confirm presence regardless of source):**

- [ ] `.editorconfig`
- [ ] `.gitattributes` (with package-boost managed block — see `$REPO_INIT_HOME/references/gitattributes-managed-block.md`)
- [ ] `.gitignore`
- [ ] `.mcp.json` (`laravel/boost` writes this on install; or our stub)
- [ ] `pint.json`
- [ ] `phpstan.neon.dist`
- [ ] `phpstan-baseline.neon`
- [ ] `rector.php`
- [ ] `phpunit.xml` (Laravel ships `phpunit.xml` historically; either is acceptable for laravel-project — flag as NON-CANONICAL only if `phpunit.xml` exists without `.dist`)
- [ ] `.github/workflows/phpstan.yml`
- [ ] `.github/workflows/pint-check.yml`
- [ ] `.github/workflows/rector-check.yml`
- [ ] `.github/workflows/update-changelog.yml`
- [ ] `.github/dependabot.yml`
- [ ] `.github/workflows/run-tests.yml` — for laravel-project this may be Laravel's own `tests.yml` instead; tolerate either name, just confirm CI runs the suite.

**Category-specific (laravel-project):**

- [ ] `boost.json` (`laravel/boost` writes this on install; ours overlays if absent)
- [ ] `CLAUDE.md` and `AGENTS.md` (package-boost generated)
- [ ] `composer.json` with `type: project`

## MISSING runtime deps (must be in `require`)

For laravel-project, runtime deps are the user's Laravel app deps (Filament, Horizon, Pennant, etc.). We don't enforce any specific runtime dep — the `laravel new` baseline + the user's additions is what it is. **Skip this section** for laravel-project (no expected runtime deps from repo-init's side).

## MISSING dev deps (must be in `require-dev`)

**Follow `$REPO_INIT_HOME/references/shared-dev-deps.md#audit-verification-protocol-mandatory`.** Every bullet below gets an explicit PRESENT/MISSING verdict. Skimming is the failure mode.

From `$REPO_INIT_HOME/references/per-category-deps.md#laravel-project` MANDATORY:

- [ ] `larastan/larastan`
- [ ] `laravel/boost`
- [ ] `laravel/pail`
- [ ] `laravel/tinker` (Laravel may ship this already)
- [ ] `driftingly/rector-laravel`

Plus shared (`$REPO_INIT_HOME/references/shared-dev-deps.md`) minus what Laravel already includes:

- [ ] `laravel/pao`
- [ ] `laravel/pint` (Laravel ships)
- [ ] `phpstan/extension-installer`
- [ ] `phpstan/phpstan-strict-rules`
- [ ] `phpstan/phpstan-deprecation-rules`
- [ ] `phpstan/phpstan-phpunit`
- [ ] `rector/rector`
- [ ] `rector/type-perfect`
- [ ] `spaze/phpstan-disallowed-calls`
- [ ] `symplify/phpstan-extensions`
- [ ] `tomasvotruba/cognitive-complexity`
- [ ] `tomasvotruba/type-coverage`
- [ ] `nunomaduro/collision` (Laravel ships)
- [ ] `orchestra/testbench` — typically NOT in laravel-project (it's a package-dev tool). Skip flagging.

`laravel-project` carries `laravel/boost` (above) as its boost-family package — NOT `sandermuller/package-boost-php`. `laravel/boost` handles AI guideline + skill sync for Laravel applications; the `sandermuller/package-boost-*` umbrellas are for distributable packages, not apps.

OPTIONAL (only when opt-in confirmed):

- [ ] `--with-hihaho-rules`: `hihaho/phpstan-rules`, `hihaho/rector-rules`, `symplify/phpstan-rules`.
- [ ] `--with-security-advisories`: `roave/security-advisories: dev-latest`.

Test-framework:

- For `phpunit` (default for laravel-project): `phpunit/phpunit` (Laravel ships).
- For `pest`: `pestphp/pest`, `pestphp/pest-plugin-arch`, `pestphp/pest-plugin-laravel`, `mrpunyapal/rector-pest`.

## OUTDATED files (per merge mode)

Same logic as `audit-laravel-package.md` §OUTDATED — apply each file's mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md`. With laravel-project paths:

- `replace`: workflows, dependabot.yml, .editorconfig, .mcp.json (if ours), boost.json (if ours).
- `managed-block`: `.gitattributes`.
- `append-only`: `.gitignore` — for laravel-project we expect the project-only extras (`/public/build`, `/public/hot`, `/public/storage`, `/storage/pail`, `_ide_helper*`). Flag MISSING-line per absent line.
- `merge-keys` (`composer.json`): walk `scripts` (including `dev`, `qa`, `setup` — laravel-project specific), `config.allow-plugins`, `config.sort-packages`. Don't flag `extra.laravel.providers` (that's a package thing, not a project thing).
- `notify-only`: `phpstan.neon.dist`, `rector.php`, `phpstan-baseline.neon`, `pint.json`. Mention drift but don't push.

## NON-CANONICAL findings

- [ ] `phpunit.xml` (without `.dist`) — Laravel ships it as `.xml` historically; some hihaho projects renamed to `.dist`. Mild NON-CANONICAL. Suggest rename only if `.dist` not already present.
- [ ] **PHPUnit cache rules** (if `test-framework=phpunit`): apply `$REPO_INIT_HOME/references/phpunit-config.md` Audit-rule section — flag `.phpunit.cache/` at root, missing/wrong `cacheDirectory` attribute in `phpunit.xml`, committed `.phpunit.cache`.
- [ ] **CI path filter drift — `phpstan.yml`** (MEDIUM severity): grep `.github/workflows/phpstan.yml` `paths:` blocks under `push` and `pull_request`; both MUST include `composer.json` AND `composer.lock`. Flag NON-CANONICAL if either missing.
- [ ] **`.gitattributes` managed block missing `.ai/ export-ignore`** (MEDIUM severity): per `$REPO_INIT_HOME/references/gitattributes-managed-block.md`, `.ai/` is the boost SOURCE/authoring dir and MUST be in the managed block. Without it, `boost sync`-populated dev skills leak into the published Composer archive. Flag NON-CANONICAL.
- [ ] `phpstan/phpstan` in `require-dev` alongside `larastan/larastan`: §5.3 exclusivity violation. NON-CANONICAL.
- [ ] PHP floor `^8.2` (or below) in `require.php`. NON-CANONICAL.
- [ ] `composer.lock` NOT committed: for laravel-project the lockfile IS committed (Laravel convention — apps pin deps). If missing, suggest committing.
- [ ] Two managed blocks in `.gitattributes`.

## EXTRA findings

Informational. Common laravel-project extras (all legit, don't push for removal):

- Filament, Horizon, Pennant, Sentry, Nova — application deps.
- `barryvdh/laravel-debugbar`, `barryvdh/laravel-ide-helper`, `beyondcode/laravel-dump-server` — debug helpers.
- `brianium/paratest`, `mattiasgeniar/phpunit-query-count-assertions`, `worksome/request-factories` — test infrastructure.

## Report

Same format as `audit-laravel-package.md` §Report. Conversation-scoped.

## What's next

- User wants to apply fixes: open `$REPO_INIT_HOME/phases/upgrade-laravel-project.md`.
- User wants to defer or is done: stop.
