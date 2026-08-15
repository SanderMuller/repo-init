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
- **Flat skill source files (`resources/boost/skills/<name>.md`)**: convert each flagged flat skill to the canonical directory form — `mkdir -p resources/boost/skills/<name> && git mv resources/boost/skills/<name>.md resources/boost/skills/<name>/SKILL.md` (the `mkdir -p` is required — `git mv` does NOT create the destination directory and fails without it; frontmatter + body preserved; `boost where` still discovers it by name). Convert all flagged flat skills; leave `resources/boost/guidelines/*.md` flat (DIR is skills-only). Re-run `vendor/bin/boost sync` after.
- **`composer.lock` committed**: prompt `git rm --cached composer.lock`.
- **PHP floor `^8.2`**: prompt bump to `^8.3`.
- **`.gitattributes` missing `.ai/ export-ignore`**: insert `.ai/ export-ignore` after `.agents/ export-ignore` inside the `# >>> package-boost (managed) >>>` block.
- **Missing `validate-gitattributes` script**: insert it (via the composer.json scripts merge above).
- **`.lpv` warnings on `vendor/bin/lean-package-validator validate`**: for each flagged artifact, add the **bare path** (no `export-ignore` suffix) to `.lpv` AND the `<path> export-ignore` line to the `.gitattributes` managed block. `.lpv` is a glob-pattern file, not `.gitattributes` syntax — see `references/gitattributes-managed-block.md` (`.lpv` file format).
- **`minimum-stability` / `prefer-stable`**: add `"minimum-stability": "stable"` + `"prefer-stable": true` to `composer.json` if absent or if `prefer-stable` isn't `true`. If `minimum-stability` is looser than `stable`, **default to tightening it to `stable`** — keep `dev` only when the author confirms the package is actively co-developed against unreleased sibling packages (being on `0.x`, or having downstream / production dependents, is a reason to tighten, NOT to keep `dev`; see `references/version-defaults.md`). Never loosen a passing `stable` baseline.

## Migrate boost config to `.config/` (canonical layout)

**Skip if:** `.config/boost.php` exists AND no root `boost.php` exists (already on the canonical layout).

boost-core ≥ 0.17's canonical config location is `.config/boost.php`; audit flags a legacy root `boost.php` as drift. To migrate:

1. **MOVE the file** — `mkdir -p .config && git mv boost.php .config/boost.php`. **Never copy** — leaving both `boost.php` and `.config/boost.php` is a hard error (`AmbiguousBoostConfigException`); every `boost` command then throws.
2. **Ensure boost-core ≥ 0.18** (the `.config/boost/` manifest layout): bump `sandermuller/boost-core` in `require` to `^1.6` (repo-init's canonical floor; skill-bundle depends on boost-core directly — `.config` needs ≥ 0.18, scaffold pins the current `^1.6`) and run `composer update sandermuller/boost-core`.
3. Run `vendor/bin/boost sync` — it auto-migrates the gitignored sync manifest `.boost/ → .config/boost/`, rewrites the managed `.gitignore` block to ignore `.config/boost/`, and refreshes the managed `.gitattributes` block. Migration is bidirectional + automatic; `vendor/bin/boost sync --check` reports the one-time stale-manifest cleanup as advisory only (never drift).
4. **`.gitattributes`:** ensure `.config/ export-ignore` is in the `# >>> package-boost (managed) >>>` block (preserved as a foreign line by the writer); remove any stale `boost.php export-ignore` line. Also update `.lpv`: replace the `boost.php` glob with `.config/`.
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
