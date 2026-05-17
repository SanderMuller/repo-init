# sandermuller/repo-init

AI playbook + stub library for bootstrapping the canonical Sander/hihaho dev setup. Pure markdown + stub files. No PHP code. Install via Composer, run through an AI agent, remove when done.

## Quick start

```bash
composer require --dev sandermuller/repo-init
```

Then ask Claude (or any agent with the propagated `.claude/skills/repo-init/SKILL.md`):

> Set up this repo as a Laravel package.
> Audit this repo against the canonical setup.
> Upgrade tooling here to current baseline.

The agent reads the matching phase file from `vendor/sandermuller/repo-init/phases/` and runs it end-to-end.

When you're done:

```bash
composer remove --dev sandermuller/repo-init
```

The synced skill stays in `.claude/skills/` for future use.

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

## Spec

Full design in [SPEC.md](SPEC.md).

## License

MIT
