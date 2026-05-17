# sandermuller/repo-init

AI playbook + stub library for bootstrapping the canonical Sander/hihaho dev setup. Pure markdown + stub files. No PHP code. **Install globally once, use everywhere.**

## Install (one-time per machine)

```bash
composer global require sandermuller/repo-init
```

The post-install hook propagates the skill into `~/.claude/skills/repo-init/` (and `~/.cursor/skills/`, etc.) so it auto-activates in any project. From then on, just ask Claude (or any agent that reads the synced skill):

> Set up this repo as a Laravel package.
> Audit this repo against the canonical setup.
> Upgrade tooling here to current baseline.

## Update

```bash
composer global update sandermuller/repo-init
```

Skill re-syncs automatically via `post-update-cmd`.

## What it sets up

- `pint.json`, `phpstan.neon.dist`, `phpstan-baseline.neon`, `rector.php` — code-quality tooling
- `.editorconfig`, `.gitattributes` (incl. package-boost managed block), `.gitignore`
- `.mcp.json` — laravel-boost MCP wiring
- `.github/workflows/{phpstan,pint-check,rector-check,run-tests,update-changelog}.yml` + `dependabot.yml`
- `tests/Pest.php` or `phpunit.xml.dist` (vendor-driven default)
- Per-category extras (testbench.yaml, workbench/, ServiceProvider, etc.)

## Repo categories

1. `laravel-project` — full Laravel app
2. `laravel-package` — sander-style or hihaho-style (spatie/laravel-package-tools)
3. `php-package` — framework-agnostic
4. `phpstan-extension` — phpstan rules package
5. `rector-extension` — rector rules package

## Project-local install (escape hatch)

If you want to pin a specific repo-init version per project:

```bash
composer require --dev sandermuller/repo-init
vendor/bin/testbench package-boost:sync
```

The project-local install takes precedence over the global one when both are present. Remove with `composer remove --dev sandermuller/repo-init`.

## Uninstall (rare)

```bash
composer global remove sandermuller/repo-init
```

Optional skill cleanup:

```bash
rm -rf ~/.claude/skills/repo-init ~/.cursor/skills/repo-init ~/.agents/skills/repo-init
```

## Spec

Full design in [SPEC.md](SPEC.md).

## License

MIT
