# Bootstrap: composer-plugin

Greenfield setup of a framework-agnostic Composer plugin. Hooks Composer's lifecycle (events, commands, capabilities) via the Composer Plugin API. No Laravel runtime dep; no Orchestra Testbench.

**Idempotent.** Each mutating step has a `Skip if:` precondition. Re-running this phase against an already-bootstrapped target is a no-op. See SPEC.md RQ41.

## Pre-flight

Run `$REPO_INIT_HOME/checklists/preflight.md`. Verify category-fit per `$REPO_INIT_HOME/references/detection-rules.md`. Placeholder transforms come from `$REPO_INIT_HOME/references/placeholder-rules.md`.

## Inputs to collect

- `vendor` — required.
- `name` (kebab-case) — optional per target-dir rule.
- `description` — required.
- `php` — default `8.3`. Accepted: `8.3`, `8.4`, `8.5`. Reject `8.2`.
- `test-framework` — default `pest` for `sandermuller`, `phpunit` for `hihaho`.
- `author-name` / `author-email` — defaults from git config.
- `plugin-shape` — `command-provider` | `event-subscriber` | `both` | `none`. Default: ask. Drives the `src/Plugin.php` skeleton.

Confirm derived `__NAMESPACE__` with the user once.

## Steps

### 1. Apply target-dir rule

- Positional `name` → `mkdir <name> && cd <name>`.
- No `name` → target IS cwd, must be empty modulo `.git/`.

### 2. Copy shared stubs

**Skip per-file if:** the file exists at target path AND no literal `__VENDOR__`/`__PACKAGE__`/etc. placeholders remain.

For each file under `$REPO_INIT_HOME/stubs/shared/`, copy to cwd. Substitute placeholders. Skip `tests/Pest.php` if `test-framework=phpunit`. **Skip `.mcp.json`** — the shared stub ships a Laravel/testbench MCP server config (`vendor/bin/testbench boost:mcp`) which has no equivalent for framework-agnostic Composer plugins.

### 3. Copy composer-plugin stubs (shape-agnostic)

**Skip per-file if:** the SUBSTITUTED target filename already exists.

For each file under `$REPO_INIT_HOME/stubs/composer-plugin/` (excluding `src/Plugin.*.php` variants — those are resolved in step 4):

- `composer.json` — substitute placeholders. Note: `type: composer-plugin`, `require: composer-plugin-api: ^2.6`, `require-dev: composer/composer: ^2.6`, `extra.class: __NAMESPACE_ESCAPED__\\Plugin`, `config.allow-plugins` includes self-allow entry.
- `.github/workflows/run-tests.yml` — copy (framework-agnostic, 3-cell PHP-only matrix, no Laravel axis; defaults to Pest — the test-framework swap in step 5 retargets it to `vendor/bin/phpunit` if PHPUnit was chosen).
- `.lpv` — copy (lean-package-validator glob-pattern file; bare globs, no `export-ignore` suffix — see `references/gitattributes-managed-block.md`).

### 4. Copy `src/Plugin.php` variant per `plugin-shape`

**Skip if:** target `src/Plugin.php` already exists AND declares the interfaces matching `plugin-shape`.

Deterministic file selection from `$REPO_INIT_HOME/stubs/composer-plugin/src/Plugin.{plugin-shape}.php`:

| `plugin-shape` | Stub source | Also copy |
|---|---|---|
| `none` | `Plugin.none.php` | — |
| `command-provider` | `Plugin.command-provider.php` | `CommandProvider.php` |
| `event-subscriber` | `Plugin.event-subscriber.php` | — |
| `both` | `Plugin.both.php` | `CommandProvider.php` |

Rename `Plugin.{shape}.php` → `src/Plugin.php` at write time. For shapes that include `CommandProvider.php`, also copy `$REPO_INIT_HOME/stubs/composer-plugin/src/CommandProvider.php` → `src/CommandProvider.php`. Both get the standard `__NAMESPACE_ESCAPED__` substitution.

For `event-subscriber` and `both` shapes: `getSubscribedEvents()` ships empty with a commented-out POST_AUTOLOAD_DUMP example. Handler methods live as private methods on the Plugin class itself (mirroring `sandermuller/boost-core`'s `BoostCorePlugin` pattern). User wires the first event hook + handler method manually.

For `command-provider` and `both` shapes: `CommandProvider::getCommands()` ships empty. User adds the first command class + registers it in the array.

### 5. Compose test-framework variant

**Skip if:** target's `composer.json` `scripts.test` matches expected command AND `.github/workflows/run-tests.yml` last step matches.

Stubs default to **Pest**. If user picked PHPUnit, follow the same swap pattern as `bootstrap-php-package.md` step 4.

### 6. Run `composer install`

**Skip if:** `vendor/` exists AND `composer validate --check-lock --no-check-publish --no-check-version` returns 0.

```bash
composer install
```

`composer/composer` (in require-dev) is heavy (~5 MB + transitive deps). Expected. On failure consult `$REPO_INIT_HOME/references/composer-failure-modes.md`.

### 7. Run `composer require --dev` for the per-category dep list

**Skip if:** every dep in the list is in `composer.json` `require-dev`.

From `$REPO_INIT_HOME/references/per-category-deps.md#composer-plugin`:

**MANDATORY require-dev:**

- `composer/composer: ^2.6`

**MANDATORY require:**

- `composer-plugin-api: ^2.6` (already in stub)

**Plus shared deps** (`$REPO_INIT_HOME/references/shared-dev-deps.md`) — MINUS the per-category exclusions:

- DROP `orchestra/testbench` (plugins don't fit testbench).

`composer-plugin` keeps `sandermuller/package-boost-php` (it's a framework-agnostic Composer package — the boost umbrella applies; the stub `composer.json` already carries it). The pre-0.5.0 exclusion that dropped it was removed.

Single batched call.

### 8. Verify plugin loads

**Skip if:** `vendor/composer/installed.json` contains the plugin AND its class autoloads.

```bash
composer dump-autoload
php -r "require 'vendor/autoload.php'; new __NAMESPACE_ESCAPED__\\Plugin();"
```

Exit 0 = class autoloads cleanly. Failure modes: bad PSR-4 mapping in `composer.json`, missing `extra.class`, missing parent interface import.

### 9. Sync AI assets (project-local, optional)

**Skip if:** target's `.ai/skills/` dir exists OR user opted out.

Default for composer-plugin is NO project-local AI assets. If the plugin ships consumer-facing skills (e.g., `sandermuller/boost-core` ships skill-authoring guidance), opt in:

```bash
mkdir -p .ai/skills .ai/guidelines resources/boost/skills
```

Note: package-shipped skills live in `resources/boost/skills/`, NOT `.ai/skills/`. `.ai/` is repo-local dev convention; `resources/boost/skills/` is what boost-core's VendorScanner picks up at consumer install time.

### 10. Validate gitattributes

Read-only check. Always run.

```bash
composer validate-gitattributes
```

Missing export-ignore → add to `.lpv` + the package-boost managed block in `.gitattributes` (see `$REPO_INIT_HOME/references/gitattributes-managed-block.md`).

### 11. Run post-bootstrap verification

Open `$REPO_INIT_HOME/checklists/post-bootstrap-verification.md`.

### 12. Print next steps

```
✓ Bootstrap done for {vendor}/{name} (composer-plugin, shape: {plugin-shape}).

Next:
- Implement your plugin logic in src/Plugin.php.
- If command-provider: define your first command in src/Commands/ and register it in src/CommandProvider.php.
- If event-subscriber: wire your first event hook in Plugin::getSubscribedEvents() + the handler method.
- Test plugin activation: install in a target project via `composer require {vendor}/{name}`; verify allow-plugins prompt appears + plugin loads without error.
- Set up the GitHub remote: `gh repo create {vendor}/{name} --public --source=. --remote=origin --push`.
- Run `composer qa` to confirm baseline passes.

Want to run an audit next (`phases/audit-composer-plugin.md`), or are you done?
```

## What's next

- Keep working: open `$REPO_INIT_HOME/phases/audit-composer-plugin.md`.
- Done: stop.

## Idempotency invariants (RQ41 contract)

Re-running this phase against a target where all steps' post-conditions are met must be a no-op. Steps 1, 8, 10, 11, 12 are read-only and always run; steps 2-7, 9 have explicit `Skip if:` preconditions.

## Common issues

- **`extra.class` typo**: Composer rejects the plugin at install time with "Class X is not autoloadable". Verify `extra.class` matches the actual FQCN in `src/Plugin.php`.
- **Missing `Capable` interface for command-provider shape**: `getCapabilities()` won't be called. Plugin loads silently but commands don't register. Verify `implements Capable`.
- **`composer/composer` in `require` instead of `require-dev`**: pulls Composer at runtime into consumers — ~5 MB bloat. Always require-dev only.
- **Plugin not allow-listed**: end users get "blocked by your allow-plugins config" error on install. Document in README that consumers must `composer config allow-plugins.{vendor}/{name} true`.
- **Symfony Console / Composer BaseCommand mismatch**: plugin commands must extend `Composer\Command\BaseCommand` (Composer's CommandProvider path validates this). If commands ship for BOTH a standalone bin AND the plugin path, a shared `CommandRegistry` keeps the two surfaces in sync.
