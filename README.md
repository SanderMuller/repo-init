# sandermuller/repo-init

[![Latest Version on Packagist](https://img.shields.io/packagist/v/sandermuller/repo-init.svg?style=flat-square)](https://packagist.org/packages/sandermuller/repo-init)
[![GitHub Tests Action Status](https://img.shields.io/github/actions/workflow/status/sandermuller/repo-init/integrity.yml?branch=main&label=tests&style=flat-square)](https://github.com/sandermuller/repo-init/actions/workflows/integrity.yml)
[![Total Downloads](https://img.shields.io/packagist/dt/sandermuller/repo-init.svg?style=flat-square)](https://packagist.org/packages/sandermuller/repo-init)
[![License](https://img.shields.io/packagist/l/sandermuller/repo-init.svg?style=flat-square)](LICENSE)

AI playbook + stub library for bootstrapping the canonical Sander / hihaho dev setup. Pure markdown + stub files. **No PHP code in the package itself.** Install globally once, use everywhere — same UX as `composer global require laravel/installer`.

## What it does

Walks an AI agent (Claude Code, Cursor, GitHub Copilot, …) through **bootstrap**, **audit**, or **upgrade** of a PHP repo against a canonical baseline:

- `pint.json`, `phpstan.neon.dist`, `phpstan-baseline.neon`, `rector.php` — code-quality tooling
- `.editorconfig`, `.gitattributes` (with package-boost managed block), `.gitignore`
- `.mcp.json` — laravel-boost MCP wiring
- `.github/workflows/{phpstan,pint-check,rector-check,run-tests,update-changelog}.yml` + `dependabot.yml`
- `tests/Pest.php` or `phpunit.xml` (vendor-driven default)
- Per-category extras (testbench.yaml, workbench/, ServiceProvider, extension.neon, etc.)

## Install (one-time per machine)

```bash
composer global require sandermuller/repo-init
```

The `post-install-cmd` hook propagates the skill into `~/.claude/skills/repo-init/` (and `~/.cursor/skills/`, `~/.agents/skills/`, etc.) via `sandermuller/package-boost`'s `--scope=user` sync. From then on, the `repo-init` skill auto-activates in any project.

> ⚠️ **Status: requires unreleased package-boost feature.** The user-scope sync (`package-boost:sync --scope=user`) is tracked as repo-init [Open Question #3 in SPEC.md](SPEC.md) — see `references/boost-core-user-scope.md` for the contract. The post-install hook auto-detects the missing feature and falls back to project-scope sync with a clear warning (the skill installs into the current project rather than globally). Once package-boost ships the feature and repo-init tags `0.1.0`, the global path activates automatically with no user action needed.

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

The `post-update-cmd` hook re-syncs the skill.

## Repo categories supported (v1)

| Category | Detection signal |
|---|---|
| `laravel-project` | `type: project` + `laravel/framework` in `require` |
| `laravel-package` (sander-style) | `type: library` + `illuminate/*` in `require` |
| `laravel-package` (spatie-style) | + `spatie/laravel-package-tools` in `require` |
| `php-package` | `type: library`, framework-agnostic |
| `phpstan-extension` | `type: phpstan-extension` |
| `rector-extension` | `type: rector-extension` |

Each has its own bootstrap, audit, and upgrade phase file — 15 total.

## What's NOT in the package

- No PHP source under `src/`. No artisan commands, no Symfony Console binary. The agent does all the work.
- No state files written to your target repo. No `.repo-init-state.json`, no `.ai/playbooks/repo-init/` copies. Stubs are read in place from the global vendor dir.
- No automatic destructive ops. Every overwrite, every dep install, every `composer require` is gated on a prompt or a documented safety rail (see [`checklists/per-category-never-touch.md`](checklists/per-category-never-touch.md)).

## Project-local install (escape hatch)

If you want to pin a specific repo-init version per project:

```bash
composer require --dev sandermuller/repo-init
vendor/bin/testbench package-boost:sync
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

See [`SPEC.md`](SPEC.md) for the full design — 40 resolved questions and 4 open. The architecture is the result of multiple codex review rounds (v3 → v4 → v5 → v6) refining the markdown-only + global-install model.

Highlights:

- Single entry point — [`.ai/skills/repo-init/SKILL.md`](.ai/skills/repo-init/SKILL.md).
- 15 self-contained phase playbooks under [`phases/`](phases/).
- 14 reference docs under [`references/`](references/) (incl. machine-readable [`per-category-deps.yml`](references/per-category-deps.yml)).
- 5 checklists under [`checklists/`](checklists/).
- 6 stub trees under [`stubs/`](stubs/) (shared + 5 categories).

## Dependencies

- `sandermuller/package-boost` — AI tooling propagation (skill sync).
- `orchestra/testbench` — required to invoke `package-boost:sync` outside a Laravel app context.

Both pulled in automatically when you `composer global require sandermuller/repo-init`.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Security

See [`SECURITY.md`](SECURITY.md).

## Changelog

See [`CHANGELOG.md`](CHANGELOG.md).

## License

MIT — see [`LICENSE`](LICENSE).
