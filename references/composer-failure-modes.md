# Composer failure modes

Common failures from `composer install` and `composer require` (called from bootstrap step 8 and from upgrade dep-application). Agent consults this reference when a composer command exits non-zero.

## Version conflict

**Symptom**: `Your requirements could not be resolved to an installable set of packages.`

Composer lists the conflict. Common causes:

1. Existing `composer.json` pins an incompatible version of a transitive dep.
2. New deps require a PHP version higher than the current `require.php` constraint.
3. Two new deps require conflicting versions of a shared transitive (e.g. `phpstan/phpstan: ^1` from package A vs `^2` from package B).

**Resolution playbook**:

- Read the conflict block carefully — Composer says which package wants which version.
- If the constraint is on PHP: ask the user to bump `require.php` (see `version-defaults.md` — we floor at `^8.3`).
- If the constraint is on a known dep: ask the user to bump it. Run `composer require <pkg>:^X` separately.
- If two new deps mutually conflict (rare): one of them is wrong for this category. Re-check `per-category-deps.md` — likely a Laravel-aware opt-in fired incorrectly.
- Never use `--ignore-platform-reqs` to mask. Surfaces real problems later.

## Package not found

**Symptom**: `Could not find package <name> with version <constraint>.`

Causes:

1. Typo in package name.
2. Package was renamed/abandoned (Composer redirects when known).
3. Package is on a custom Composer repo (e.g. Satis) that's not in `repositories`.

**Resolution playbook**:

- Verify spelling against `references/per-category-deps.md` (canonical names).
- If on a custom repo: confirm with user, add `repositories` entry, retry.
- If abandoned: check `https://packagist.org/packages/<name>` for the replacement notice.

## PHP version not satisfied

**Symptom**: `Your PHP version (X.Y.Z) does not satisfy that requirement.`

**Resolution playbook**:

- Confirm the user's runtime PHP version: `php -v`.
- repo-init floors at `^8.3` — repos on `^8.2` should bump.
- If the user can't bump (legacy constraint), stop and escalate. Don't `--ignore-platform-reqs`.

## Lockfile conflict

**Symptom**: `composer.lock` and `composer.json` out of sync; warnings like `Lock file operations: X installs, Y updates, Z removals` when not expected.

Causes:

1. Manual edit to `composer.json` without `composer update`.
2. `composer require` on a stale lockfile.
3. Branch merge that mixed two lockfile states.

**Resolution playbook**:

- Run `composer validate --check-lock`. If failing, run `composer update --lock` (regenerates lockfile from existing `composer.json`).
- If the user has uncommitted changes to `composer.lock` from a different workflow, stop and ask before regenerating.

## Allow-plugins prompt

**Symptom**: `composer install` interactively prompts whether to allow a plugin (`Do you trust pestphp/pest-plugin to execute code?`).

**Resolution playbook**:

- Bootstrap stubs declare the allowlist in `composer.json` `config.allow-plugins` (see `version-defaults.md`), so this shouldn't fire after the first install.
- If it does fire (existing target with stale `composer.json`), the upgrade phase's `composer.json` merge-keys step will add the missing entries on the next run.

## Memory exhaustion

**Symptom**: `PHP Fatal error: Allowed memory size exhausted`.

**Resolution playbook**:

- Run with `COMPOSER_MEMORY_LIMIT=-1`: `COMPOSER_MEMORY_LIMIT=-1 composer require --dev ...`.
- Or per-php.ini: `php -d memory_limit=-1 /usr/local/bin/composer require ...`.

## Network / packagist down

**Symptom**: `Could not connect to packagist.org`, timeouts.

**Resolution playbook**:

- Pre-flight should have caught this (see `checklists/preflight.md`). If it slipped through: ask the user to retry after a minute.
- For longer outages, fall back to `--prefer-source` if mirrors are reachable. Document the workaround in the audit notes for the user.

## Plugin failed during install

**Symptom**: `pestphp/pest-plugin` or `phpstan/extension-installer` errors during install.

**Resolution playbook**:

- Common cause: stale `vendor/` from a prior failed run. `rm -rf vendor composer.lock && composer install` (only with user confirmation — destructive).
- Verify `config.allow-plugins` includes the plugin.

## Always: surface the full Composer output

If none of the playbooks above match, stop and present the full Composer output to the user. Don't paper over with retries.
