# sandermuller/repo-init

[![Latest Version on Packagist](https://img.shields.io/packagist/v/sandermuller/repo-init.svg?style=flat-square)](https://packagist.org/packages/sandermuller/repo-init)
[![GitHub Tests Action Status](https://img.shields.io/github/actions/workflow/status/sandermuller/repo-init/integrity.yml?branch=main&label=tests&style=flat-square)](https://github.com/sandermuller/repo-init/actions/workflows/integrity.yml)
[![Total Downloads](https://img.shields.io/packagist/dt/sandermuller/repo-init.svg?style=flat-square)](https://packagist.org/packages/sandermuller/repo-init)
[![License](https://img.shields.io/packagist/l/sandermuller/repo-init.svg?style=flat-square)](LICENSE)

AI playbook + stub library for bootstrapping the canonical Sander / hihaho dev setup. Pure markdown + stub files. **No PHP code in the package itself.** Install globally once, use everywhere — same UX as `composer global require laravel/installer`.

## What it does

Walks an AI agent (Claude Code, Cursor, GitHub Copilot, …) through **bootstrap**, **audit**, or **upgrade** of a PHP repo against a canonical baseline:

- `pint.json`, `phpstan.neon.dist`, `phpstan-baseline.neon`, `rector.php` — code-quality tooling
- `.editorconfig`, `.gitattributes` (with the `# >>> package-boost (managed) >>>` block — sentinel name preserved for backward compat; owned by `package-boost-php`), `.gitignore`
- `.mcp.json` (Laravel-aware categories only — composer-plugin and rector/phpstan extensions skip it)
- Shared `.github/workflows/{phpstan,pint-check,rector-check,update-changelog}.yml` + per-category `run-tests.yml` + `dependabot.yml`
- `tests/Pest.php` or `phpunit.xml` (vendor-driven default)
- Per-category extras (testbench.yaml, workbench/, ServiceProvider, extension.neon, src/Plugin.{shape}.php for composer-plugin, etc.)

## Install (one-time per machine)

```bash
composer global require sandermuller/repo-init
```

[`sandermuller/boost-core`](https://github.com/SanderMuller/boost-core)'s global-context auto-sync (active under `composer global` since 0.2.0) propagates the `repo-init` skill into `~/.claude/skills/repo-init/`, `~/.cursor/skills/repo-init/`, `~/.agents/skills/repo-init/`, etc. on first install. The skill then auto-activates in any project. See `references/boost-core-user-scope.md` for the full contract.

## Use

Ask Claude (or any agent with the synced skill):

> Set up this repo as a Laravel package.
> Audit this repo against the canonical setup.
> Upgrade tooling here to current baseline.

The agent reads the `repo-init` skill, decides intent + category, and opens the matching phase file from `$(composer global config home)/vendor/sandermuller/repo-init/phases/`. Everything happens in your conversation; nothing is written to your target repo by repo-init itself (the agent does the writes, following the phase's instructions).

## Update

```bash
composer global update sandermuller/repo-init
```

boost-core's plugin re-syncs the skill on the same hook.

## Repo categories supported

| Category | Detection signal |
|---|---|
| `laravel-project` | `type: project` + `laravel/framework` in `require` |
| `laravel-package` (sander-style) | `type: library` + `illuminate/*` in `require` |
| `laravel-package` (spatie-style) | + `spatie/laravel-package-tools` in `require` |
| `php-package` | `type: library`, framework-agnostic |
| `phpstan-extension` | `type: phpstan-extension` |
| `rector-extension` | `type: rector-extension` |
| `composer-plugin` | `type: composer-plugin` |

Each has its own bootstrap, audit, and upgrade phase file (20 phase files total — 6 audit + 6 upgrade + 8 bootstrap, the extra 2 bootstraps cover `filament-plugin` and `nova-tool` which fall through to `laravel-package` for audit/upgrade). `composer-plugin` (added in 0.3.0) covers framework-agnostic Composer plugins (e.g. boost-core, package-boost-php) with sub-flags for command-provider / event-subscriber shapes.

## What's NOT in the package

- No PHP source under `src/`. No artisan commands, no Symfony Console binary. The agent does all the work.
- No state files written to your target repo. No `.repo-init-state.json`, no `.ai/playbooks/repo-init/` copies. Stubs are read in place from the global vendor dir.
- No automatic destructive ops. Every overwrite, every dep install, every `composer require` is gated on a prompt or a documented safety rail (see [`checklists/per-category-never-touch.md`](checklists/per-category-never-touch.md)).

## Project-local install (escape hatch)

If you want to pin a specific repo-init version per project:

```bash
composer require --dev sandermuller/repo-init
vendor/bin/boost sync
```

The project-local install takes precedence over the global one. Remove with `composer remove --dev sandermuller/repo-init`.

## Uninstall

```bash
composer global remove sandermuller/repo-init
```

Optional skill cleanup (the synced user-level skill dirs survive `composer global remove`):

```bash
rm -rf ~/.claude/skills/repo-init \
       ~/.cursor/skills/repo-init \
       ~/.agents/skills/repo-init
```

(Keep the synced skills if you might re-install later — re-running `composer global require sandermuller/repo-init` re-syncs them, so leaving them in place is harmless.)

## Design

See [`SPEC.md`](SPEC.md) for the full design (markdown-only + global-install model).

Highlights:

- Single entry point — [`resources/boost/skills/repo-init/SKILL.md`](resources/boost/skills/repo-init/SKILL.md).
- 20 self-contained phase playbooks under [`phases/`](phases/).
- 18 reference docs under [`references/`](references/) (incl. machine-readable [`per-category-deps.yml`](references/per-category-deps.yml)).
- 5 checklists under [`checklists/`](checklists/).
- 12 stub trees under [`stubs/`](stubs/) — `shared/` + 2 test-framework variants + 9 categories (composer-plugin, filament-plugin, laravel-package, laravel-package-spatie, laravel-project, nova-tool, php-package, phpstan-extension, rector-extension).

## Dependencies

- [`sandermuller/package-boost-php`](https://github.com/SanderMuller/package-boost-php) — direct require; ships AI agent skills for PHP package authors.
- [`sandermuller/boost-core`](https://github.com/SanderMuller/boost-core) — transitive via package-boost-php; Composer plugin engine for `vendor/bin/boost sync` and the `BoostAutoSync::run` callback used in `post-install-cmd` / `post-update-cmd`.

Both pulled in automatically when you `composer global require sandermuller/repo-init`.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Security

See [`SECURITY.md`](SECURITY.md).

## Changelog

See [`CHANGELOG.md`](CHANGELOG.md).

## License

MIT — see [`LICENSE`](LICENSE).
