# Post-bootstrap verification

Run after every bootstrap phase. If anything is red, stop and report to the user before printing the "next steps" prompt.

## Category note — `skill-bundle`

`skill-bundle` ships pure-markdown skills and no PHP source, so several checks below — written for code-bearing categories — do NOT apply and would false-fail. For a `skill-bundle` target, **skip**:

- **File presence**: `.mcp.json`, `phpstan-baseline.neon`, `phpstan.neon.dist`, `rector.php`, `phpunit.xml` / `tests/Pest.php`, `run-tests.yml`, and the `phpstan.yml` / `rector-check.yml` workflows are NOT expected (only `pint-check.yml` + `zizmor.yml` + `update-changelog.yml` ship).
- **Tooling smoke tests**: only `vendor/bin/pint --test` applies — there is no phpstan / rector / pest.
- **Larastan vs phpstan**: neither is installed — skip the section entirely.

Still applies to `skill-bundle`: Composer integrity (it is a library — lockfile gitignored), the lean meta files (`README.md`, `LICENSE`, `CHANGELOG.md`, `SECURITY.md`, `.editorconfig`, `.gitattributes`, `.gitignore`, `pint.json`, `.github/dependabot.yml`), placeholder substitution, the `resources/boost/skills/` tree, AI tooling sync, and Git state.

## Composer integrity

- [ ] `composer validate` returns 0.
- [ ] `composer install` ran cleanly (vendor/ populated, composer.lock generated).
- [ ] `composer.lock` exists. For `php-package`, `phpstan-extension`, `rector-extension`, `laravel-package`, `composer-plugin`, `skill-bundle` — composer.lock should NOT be committed (the .gitignore excludes it). Verify:

  ```bash
  git check-ignore composer.lock && echo "OK: gitignored" || echo "FAIL: lockfile not ignored"
  ```

  For `laravel-project`: composer.lock IS committed (Laravel convention). Skip this check.

## File presence

- [ ] All shared stubs present: `.editorconfig`, `.gitattributes`, `.gitignore`, `.config/boost.php` (all categories except `laravel-project`, which uses `laravel/boost`), `.mcp.json`, `pint.json`, `phpstan-baseline.neon`, `phpunit.xml` OR `tests/Pest.php` (per test-framework).
  - Boost config layout: a greenfield bootstrap produces `.config/boost.php` (canonical). If the target already had a **legacy root `boost.php`**, bootstrap deliberately left it in place (it does not copy a second config — two configs is a hard error). That is NOT a bootstrap failure — it's drift: do NOT add `.config/boost.php` alongside it. Route the user to `upgrade-<category>.md` to MIGRATE (move, not copy). Never both present.
- [ ] Baseline OSS meta files present: `README.md`, `LICENSE`, `CHANGELOG.md`, `SECURITY.md`. Missing any of these is a stop condition. README content follows the `readme` skill from `sandermuller/package-boost`; `CHANGELOG.md` uses Keep a Changelog format with an `## [Unreleased]` section seeded but otherwise empty.
- [ ] `.github/dependabot.yml`, `.github/zizmor.yml` (rule config), and all 5 shared workflows (`phpstan.yml`, `pint-check.yml`, `rector-check.yml`, `zizmor.yml`, `update-changelog.yml`) present.
- [ ] Category-specific `.github/workflows/run-tests.yml` present.
- [ ] `composer.json` present with substituted placeholders (no `__VENDOR__` / `__PACKAGE__` strings left).
- [ ] `phpstan.neon.dist` + `rector.php` present.

## Placeholder substitution

Grep for unsubstituted placeholders:

```bash
grep -r '__VENDOR__\|__PACKAGE__\|__NAMESPACE__\|__AUTHOR_\|__PHP_VERSION\|__LARAVEL_VERSIONS__\|__DESCRIPTION__\|__SKILL_TAGS__' . --include='*.json' --include='*.php' --include='*.md' --include='*.neon' --include='*.yml' 2>/dev/null
```

- [ ] No hits. If hits, the agent missed a substitution; revisit step 3 of the bootstrap phase.

## Tooling smoke tests

- [ ] `vendor/bin/pint --test` runs (may report formatting drift on the stubs — that's fine for first run, just confirms pint is callable).
- [ ] `vendor/bin/phpstan analyse --no-progress --memory-limit=2G` runs (may have errors on empty src/; that's fine, we just confirm phpstan is callable).
- [ ] `vendor/bin/rector process --dry-run` runs (may report 0 changes on empty src/; confirms rector is callable).
- [ ] For `test-framework=pest`: `vendor/bin/pest --version` returns a Pest 5 version, and `composer.json` `require.php` is `^8.4` or higher.
- [ ] For `test-framework=pest`: `tests/Pest.php` contains `pest()->tia()->locally();`, and no composer script or CI step passes `--tia`.
- [ ] For `test-framework=pest`: run the suite AFTER the initial commit. Tia needs a git repository with at least one commit; in a repo with none, `vendor/bin/pest` aborts with `The feature "Tia mode" requires "git"` (verified against Pest 5). Use `vendor/bin/pest --no-tia` if the suite must run before the first commit.
- [ ] For `test-framework=pest`: `require-dev` has `pestphp/pest-plugin-rector`, `pestphp/pest-plugin-phpstan`, and `pestphp/pest-plugin-agent` — and NO `mrpunyapal/rector-pest`.
- [ ] For `test-framework=pest`: `rector.php` imports `Pest\Rector\Set\PestSetList` and uses `PestSetList::CODING_STYLE`.
- [ ] For `test-framework=phpunit`: `vendor/bin/phpunit --version` returns a PHPUnit 11+ version.

## AI tooling sync

- [ ] `vendor/bin/testbench package-boost:sync` ran cleanly (post-autoload-dump hook fires automatically OR run manually if scaffolder used `--no-scripts`).
- [ ] Sync output present in repo root: `.claude/`, `.agents/`, `.cursor/`, `.junie/`, `.kiro/` directories AND meta files `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`. (`.ai/` and `.codex/` are NOT generated by current `package-boost:sync` — don't expect them.) Missing the listed five + three → sync didn't run.
- [ ] If repo-init is project-local (escape hatch, rare): `.claude/skills/repo-init/SKILL.md` exists in cwd. Otherwise verify `~/.claude/skills/sandermuller__repo-init/SKILL.md` exists (global).

## Larastan vs phpstan exclusivity

```bash
composer show --installed | grep -E '^(larastan/larastan|phpstan/phpstan) '
```

- [ ] Laravel categories: only `larastan/larastan` listed (NOT bare `phpstan/phpstan`).
- [ ] Framework-agnostic categories: only `phpstan/phpstan` listed (NOT `larastan/larastan`).
- [ ] If both are listed: violation of `references/phpstan-config.md` §exclusivity. Remove the wrong one: `composer remove --dev <wrong-one>`.

## Git state

- [ ] `git status` reports a working tree of fresh untracked files (expected — they're not yet committed).
- [ ] No errors during the bootstrap that left files in inconsistent state.
- [ ] (Optional) Suggest the user run `git add . && git commit -m 'Initial commit: scaffolded via sandermuller/repo-init'`.

## Stop conditions

Stop and report to the user if ANY of:

- `composer install` failed.
- `composer require --dev` partially succeeded (some packages installed, others rejected).
- Placeholder substitution left literal `__FOO__` strings in any file.
- Both `larastan` and bare `phpstan/phpstan` are installed.
- A never-touch path (per `checklists/per-category-never-touch.md`) was written to.

In any of these cases, do NOT print the "Bootstrap done" message — present the failure to the user with the offending file/dep list.
