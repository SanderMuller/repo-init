# Bootstrap: skill-bundle

Greenfield setup of a **skill-bundle** — a distributable Composer package whose product is AI agent skills (it ships `resources/boost/skills/`, carries `sandermuller/boost-core` in runtime `require`, and has no `src/` PHP code).

**Idempotent.** Each mutating step has a `Skip if:` precondition. Re-running this phase against an already-bootstrapped target is a no-op. See SPEC.md RQ41.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`. Stop if anything is red. Verify category-fit per `$REPO_INIT_HOME/references/detection-rules.md`. Placeholder transforms come from `$REPO_INIT_HOME/references/placeholder-rules.md`.

## Inputs to collect

- `vendor` — required.
- `name` (kebab-case) — optional per target-dir rule.
- `description` — required.
- `php` — default `8.3`. Accepted: `8.3`, `8.4`, `8.5`. Reject `8.2`.
- `author-name` / `author-email` — defaults from git config.

## Steps

### 1. Apply target-dir rule

`mkdir <name> && cd <name>` if `name` was provided; otherwise verify cwd is empty modulo `.git/`.

### 2. Copy the stub `composer.json`

**Skip if:** `composer.json` already exists in cwd.

Copy `$REPO_INIT_HOME/stubs/skill-bundle/composer.json`, substitute placeholders per `$REPO_INIT_HOME/references/placeholder-rules.md`. No `composer init` prelude needed. The stub already declares `sandermuller/boost-core` in `require` and allow-lists it in `config.allow-plugins` — do not strip either.

The stub's dependency set is the canonical skill-bundle list — see `$REPO_INIT_HOME/references/per-category-deps.md#skill-bundle` (`sandermuller/boost-core` in `require`; `laravel/pint`, `stolt/lean-package-validator` in `require-dev`). The shared dev-dep list does NOT apply — a skill-bundle ships no PHP source and carries no test runner.

### 3. Install dependencies

**Skip if:** `vendor/` exists AND `composer validate` passes.

```bash
composer install
```

On failure, consult `$REPO_INIT_HOME/references/composer-failure-modes.md`.

### 4. Scaffold the skills tree

**Skip if:** `resources/boost/skills/` already exists with at least one `SKILL.md`.

```bash
mkdir -p resources/boost/skills
```

A skill-bundle ships its skills under `resources/boost/skills/<skill-name>/SKILL.md` — that is the path boost-core's `VendorScanner` discovers at consumer install time. Each skill is a directory with a `SKILL.md` carrying `name:` + `description:` frontmatter. Create at least one skill directory; the user fills in the content.

### 5. Overlay shared meta + tooling stubs

**Skip per-file if:** the file already exists at the target path AND its contents match `$REPO_INIT_HOME/stubs/shared/<file>` after placeholder substitution.

Copy from `$REPO_INIT_HOME/stubs/shared/`: `.editorconfig`, `.gitignore`, `_gitattributes` (rename to `.gitattributes`), `boost.php`, `pint.json`, `README.md`, `LICENSE`, `CHANGELOG.md`, `SECURITY.md`, and `.github/workflows/{pint-check,update-changelog}.yml` + `.github/dependabot.yml`. (`boost.php` is the boost-core agent config — a skill-bundle carries `boost-core`, so it is copied.)

**Skip** the PHP-toolchain stubs — `phpstan.neon.dist`, `phpstan-baseline.neon`, `rector.php`, `.mcp.json`, `run-tests.yml`, `phpstan.yml`, `rector-check.yml`: a skill-bundle ships no `src/` PHP, so static analysis / rector / testbench-MCP have nothing to act on.

### 6. Add the `.lpv` lean-package-validator config

**Skip if:** `.lpv` already exists.

Copy `$REPO_INIT_HOME/stubs/skill-bundle/.lpv`. Then validate:

```bash
vendor/bin/lean-package-validator validate
```

If it warns about a missing export-ignore line for a dir we ship, add it to `.lpv` and to the `.gitattributes` managed block (see `$REPO_INIT_HOME/references/gitattributes-managed-block.md`).

### 7. Run post-bootstrap verification

Open `$REPO_INIT_HOME/checklists/post-bootstrap-verification.md` and apply its "Category note — `skill-bundle`" section: a skill-bundle ships no PHP, so the PHP-toolchain checks (phpstan / rector / `.mcp.json` / `run-tests.yml` / test runner / larastan-vs-phpstan) do NOT apply and are skipped — verification reduces to Composer integrity, the lean meta files, placeholder substitution, the `resources/boost/skills/` tree, AI sync, and Git state.

## After the phase: what's next

```
✓ Bootstrap done for {vendor}/{name} (skill-bundle).

Next:
- Author your skills under resources/boost/skills/<skill-name>/SKILL.md.
- Run `composer qa` to confirm the baseline passes.
- Set up the GitHub remote: `gh repo create {vendor}/{name} --public --source=. --remote=origin --push`.

Want to run an audit next (`phases/audit-skill-bundle.md`), or are you done?
```

There is nothing to remove from the target — repo-init was never installed there.

## Idempotency invariants (RQ41 contract)

Re-running this phase against a target where all steps' post-conditions are already met must be a no-op: no `composer install`, no stub overwrites, no skills-tree clobber. Steps 1 and 7 are read-only and always run. Steps 2-6 have explicit `Skip if:` / `Skip per-file if:` preconditions.

## Common issues

- **Stale `sandermuller/boost-core: true` in `config.allow-plugins`**: from boost-core 0.6.0, the package is `type: library` — no allow-plugins entry needed. The stub `composer.json` ships with `config.allow-plugins` empty. If the user added the entry manually (or migrated from a pre-0.6.0 scaffold), remove it; Composer ignores it, harmless but obsolete.
- **No `src/` — PHPStan/Rector workflows missing**: intentional. A skill-bundle has no PHP source; the PHP-toolchain stubs are skipped per step 5.
