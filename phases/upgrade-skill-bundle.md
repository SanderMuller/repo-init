# Upgrade: skill-bundle

Apply audit findings to an existing `skill-bundle` package.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md` AND re-run audit: open `$REPO_INIT_HOME/phases/audit-skill-bundle.md`, walk it end-to-end, hold the findings in conversation.

## Safety rails

Honour `$REPO_INIT_HOME/checklists/per-category-never-touch.md` (no Laravel-specific never-touch — `.env*` and `.git/` apply universally) and the git-dirty rule before every write. Verify category-fit one more time via `$REPO_INIT_HOME/references/detection-rules.md`; dep expectations come from `$REPO_INIT_HOME/references/per-category-deps.md`.

## Apply MISSING files

For each MISSING file:

1. Read the stub from `$REPO_INIT_HOME/stubs/<shared|skill-bundle>/<path>`.
2. Substitute placeholders.
3. Write — prompt on conflict per `replace` mode.

If `resources/boost/skills/` is missing, create it and prompt the user to author at least one `<skill-name>/SKILL.md`.

## Apply MISSING runtime deps

Single `composer require <list>`:

- `sandermuller/boost-core` — MANDATORY in `require` (runtime). If the audit found it in `require-dev`, move it: `composer remove --dev sandermuller/boost-core && composer require sandermuller/boost-core`.

On failure, consult `$REPO_INIT_HOME/references/composer-failure-modes.md`.

## Apply MISSING dev deps

Single batched `composer require --dev <list>`. Category-mandatory: `laravel/pint`, `sandermuller/boost-skills`, `stolt/lean-package-validator`. A skill-bundle ships no PHP source — it carries no test runner, and the PHPStan / Rector shared dev-dep packs are NOT installed; `sandermuller/boost-skills` is the one shared library it still takes (hand-listed because `skill-bundle` opts out of the shared dev-dep block).

On failure, consult `$REPO_INIT_HOME/references/composer-failure-modes.md`.

## Apply OUTDATED files per merge mode

For each OUTDATED file, apply its mode from `$REPO_INIT_HOME/references/upgrade-merge-modes.md` — same logic as `upgrade-php-package.md`, with `skill-bundle` / `shared` stub paths.

## Apply composer.json merge-keys patches

Per `$REPO_INIT_HOME/references/composer-scripts.md`:

- **`scripts`**: insert missing `format`, `validate-gitattributes`, `qa`. Insert `post-install-cmd` AND `post-update-cmd` as `SanderMuller\BoostCore\Scripts\BoostAutoSync::run` — if an old POSIX-shell `post-install-cmd` is present, replace it (it is Windows-broken); if a stale `::runWithSummary` is wired, replace with `::run` (`runWithSummary` is for user-invoked scripts; auto-firing hooks should be silent-on-no-op, which 0.6.0's `run()` is).
- **`config.allow-plugins`**: with boost-core 0.6.0 (`type: library`), no `sandermuller/boost-core` allow-plugins entry is required. If a stale `sandermuller/boost-core: true` entry is present from a pre-0.6.0 scaffold, remove it. For `skill-bundle`, `config.allow-plugins` is typically empty post-0.6.0.
- **`config.sort-packages`**: `true`.

## Apply NON-CANONICAL fixes (each prompted)

- **`sandermuller/boost-core` in `require-dev`**: move it to `require` (see MISSING runtime deps above) — consumers need it transitively.
- **`config.allow-plugins` lists `sandermuller/boost-core`** (stale, post boost-core 0.6.0): remove the entry — boost-core 0.6.0 is `type: library`, the entry is harmless but unnecessary.
- **Outdated POSIX-shell `post-install-cmd`** or **stale `::runWithSummary`**: replace with `::run` per the merge-keys patch above.
- **`src/` directory with PHP source**: prompt "is this actually a `php-package`?" If the user confirms it ships real PHP, re-route to `audit-php-package.md`.
- **`composer.lock` committed**: prompt `git rm --cached composer.lock`.
- **PHP floor `^8.2`**: prompt bump to `^8.3`.
- **`.gitattributes` missing `.ai/ export-ignore`**: insert `.ai/ export-ignore` after `.agents/ export-ignore` inside the `# >>> package-boost (managed) >>>` block.
- **Missing `validate-gitattributes` script**: insert it (via the composer.json scripts merge above).
- **`.lpv` warnings on `vendor/bin/lean-package-validator validate`**: add each missing export-ignore line to `.lpv` AND to the `.gitattributes` managed block.

## Run boost-core sync

```bash
vendor/bin/boost sync
```

Refreshes the agent dirs from `resources/boost/skills/` and `.ai/`. `vendor/bin/boost` is boost-core's standalone bin — present because `boost-core` is a direct `require`.

## Verification

Open `$REPO_INIT_HOME/checklists/post-upgrade-verification.md` and apply its "Category note — `skill-bundle`" section: skip the PHPStan / Rector / Tests smoke tests and the larastan-vs-phpstan check (a skill-bundle has none of those tools); the `skill-bundle` entry under "Per-category extras" is the relevant one. Plus:

```bash
composer validate-gitattributes
```

## What's next

- Keep working: next phase or re-audit.
- Done: stop.

## Common issues

- **`validate-gitattributes` fails with "command not found"**: `vendor/bin/lean-package-validator` needs `composer install` after the dep was added. Run it.
