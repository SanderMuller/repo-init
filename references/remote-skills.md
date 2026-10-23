# Canonical remote skills

Every repo repo-init scaffolds declares the same remote skill sources in its boost config (`.config/boost.php`). The sources are GitHub repos that publish agent skills outside Composer. boost-core fetches them on `boost sync` and fans them out like any vendor skill.

Traced against boost-core 1.13.0 (`src/Skills/Remote/RemoteSkillSource.php`, `src/Config/BoostConfigBuilder.php::withRemoteSkills()`) and the `project-boost-laravel` configuration guide ("Remote skills").

## The canonical set

| Skill | Source | Ref | Path in repo | Mode |
|---|---|---|---|---|
| `security-audit` | `cloudflare/security-audit-skill` | `c1c8a8c1471069fb0e188eeaff69b8e8db6564a8` | `skills/security-audit` | path |

The entry in the boost config:

```php
use SanderMuller\BoostCore\Skills\Remote\RemoteSkillSource;

// ...
    ->withRemoteSkills([
        RemoteSkillSource::githubPath('cloudflare/security-audit-skill', 'c1c8a8c1471069fb0e188eeaff69b8e8db6564a8', [
            'security-audit' => 'skills/security-audit',
        ]),
    ])
```

`stubs/shared/.config/boost.php` and `stubs/laravel-project/.config/boost.php` both carry this entry, and repo-init's own `.config/boost.php` uses it too. Keep the four copies (this table, the two stubs, and repo-init's config) identical.

## Which package delivers it

`withRemoteSkills()` is a boost-core builder method. Each category reaches it through its boost-family package:

| Category | Boost-family package | Sync command |
|---|---|---|
| `php-package`, `phpstan-extension`, `rector-extension`, `composer-plugin` | `sandermuller/package-boost-php` | `vendor/bin/boost sync` |
| `laravel-package` (+ `laravel-package-spatie`, `filament-plugin`, `nova-tool`) | `sandermuller/package-boost-laravel` | `vendor/bin/boost sync` |
| `skill-bundle` | `sandermuller/boost-core` (direct) | `vendor/bin/boost sync` |
| `laravel-project` | `sandermuller/project-boost-laravel` | `php artisan project-boost:sync` — never the bare `vendor/bin/boost sync`, see `$REPO_INIT_HOME/references/composer-scripts.md` |

## Why a pinned SHA

- The upstream repo publishes no tags and no releases. Bundle mode (`githubBundle()`) needs a release asset, so path mode is the only option.
- A moving ref (`main`, `latest`, a branch) re-resolves every 24 hours. An upstream push then changes what lands in every repo without a review. `boost doctor` flags a moving ref with a `⚠`.
- A 40-character SHA caches forever, so later syncs need no network.

To move the pin, a repo-init maintainer reads the upstream diff between the old SHA and the new one, then updates all four copies in one commit. Audit then reports the old SHA as drift in existing repos.

## Operational notes

- **First sync fetches.** The first `boost sync` after the entry lands downloads the repo tarball into the user cache. Anonymous GitHub access allows 60 requests per hour. Set `BOOST_GITHUB_TOKEN` (any token with `public_repo` scope) when that limit is a problem.
- **CI fetches too.** No scaffolded workflow calls `boost sync` directly, but each `composer install` / `composer update` in CI fires the `post-install-cmd` / `post-update-cmd` auto-sync hook with dev dependencies installed. The runner has no cache, so every job fetches the source again, without a token. A fetch failure there only prints a warning — the build does not fail.
- **Failure is not fatal.** A fetch failure warns and skips the source, unless `BOOST_REMOTE_STRICT=1` is set.
- **Prune on removal.** Removing the entry removes the skill from the agent directories on the next sync.
- **Opt-out.** A repo that does not want the skill keeps the entry and adds `->withExcludedSkills(['cloudflare/security-audit-skill:security-audit'])`. Audit treats that exclusion as a decision, not drift.

## Audit findings

Check the boost config (`.config/boost.php`, or a legacy root `boost.php`):

- **Entry missing** (MEDIUM, DRIFT): no `withRemoteSkills([...])` call, or the call has no `cloudflare/security-audit-skill` source. Fix = add the entry above.
- **Moving ref** (MEDIUM, NON-CANONICAL): the source uses `main`, `latest`, or another branch name. Fix = replace the ref with the SHA above.
- **Other SHA** (LOW, DRIFT): the source pins a SHA that is not the one above. Report the two SHAs. Prompt before changing the pin — the repo can have a reason to hold an older or newer one.
- **Excluded** (INFO): `withExcludedSkills([...])` lists `cloudflare/security-audit-skill:security-audit`. Report it. Never remove the exclusion.

## Upgrade step

**Skip if:** the boost config has a `cloudflare/security-audit-skill` source with the canonical SHA and the `skills/security-audit` path.

1. Add `use SanderMuller\BoostCore\Skills\Remote\RemoteSkillSource;` to the imports when it is absent.
2. When a `cloudflare/security-audit-skill` source already exists, edit it in place: for a moving ref, replace the ref with the canonical SHA; for a different SHA, follow the "Other SHA" row above; fix a wrong path. Never add a second entry for the source — `withRemoteSkills()` rejects a duplicate source, version and mode, and the sync then fails.
3. When the source is absent, add the entry to the existing `withRemoteSkills([...])` array. When there is no such call, add one before `->withDisabledEmitters(...)` (or at the end of the chain). Use one `withRemoteSkills()` call only: each call replaces the list of the call before it.
4. Do not sync from this step. The calling phase runs its own sync later — for `laravel-project` that first sync is `project-boost:reconcile`, which must run before any plain sync. After that sync, unless the skill is excluded, confirm that `.claude/skills/security-audit/SKILL.md` exists and that `vendor/bin/boost where` lists `remote · cloudflare/security-audit-skill`.

Keep the config file one straight `return BoostConfig::configure()->...;` expression. `boost install` and `boost remote` edit it through the AST and refuse other shapes.
