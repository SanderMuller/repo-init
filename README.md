# sandermuller/repo-init

[![Latest Version on Packagist](https://img.shields.io/packagist/v/sandermuller/repo-init.svg?style=flat-square)](https://packagist.org/packages/sandermuller/repo-init)
[![GitHub Tests Action Status](https://img.shields.io/github/actions/workflow/status/sandermuller/repo-init/integrity.yml?branch=main&label=tests&style=flat-square)](https://github.com/sandermuller/repo-init/actions/workflows/integrity.yml)
[![Total Downloads](https://img.shields.io/packagist/dt/sandermuller/repo-init.svg?style=flat-square)](https://packagist.org/packages/sandermuller/repo-init)
[![License](https://img.shields.io/packagist/l/sandermuller/repo-init.svg?style=flat-square)](LICENSE)
[![Laravel Boost](https://badge.laravel.cloud/boost-badge.svg?style=flat-square)](https://github.com/laravel/boost)

AI playbook + stub library for bootstrapping the canonical Sander / hihaho dev setup. Pure markdown + stub files. **No PHP code in the package itself.** Install globally once, use everywhere — same UX as `composer global require laravel/installer`.

## What it does

Walks an AI agent (Claude Code, Cursor, GitHub Copilot, …) through **bootstrap**, **audit**, or **upgrade** of a PHP repo against a canonical baseline:

- `pint.json`, `phpstan.neon.dist`, `phpstan-baseline.neon`, `rector.php` — code-quality tooling. PHPStan runs at `level: max` with `strictRules.allRules`, 100% type coverage and a hand-picked `symplify/phpstan-rules` list (its rule sets are switched off, because 14.17 turns them all on)
- A PHP floor per repo kind — `^8.5` for `laravel-project` (an application takes the newest stable PHP), `^8.4` for every package and plugin category. PHP 8.3 is not supported
- `.editorconfig`, `.gitattributes` (with the `# >>> package-boost (managed) >>>` block — sentinel name preserved for backward compat; owned by `package-boost-php`), `.gitignore`
- `.mcp.json` (Laravel-aware categories only; the framework-agnostic categories — `php-package`, `composer-plugin`, `phpstan-extension`, `rector-extension`, `skill-bundle` — skip it)
- `.config/boost.php` — boost-core agent config, pinning Claude Code / Copilot / Codex (every category except `laravel-project`, which uses `laravel/boost`). The `.config/` layout is canonical (boost-core ≥ 0.17); the sync manifest lives at `.config/boost/`
- `sandermuller/boost-skills` (floor `^2.27.0`) — the shared dev-workflow skill library, added to `require-dev` + `.config/boost.php`; bootstrap interactively picks which skill tags (`php` / `frontend` / `github` / `jira`) to activate. The `voice` tag is always on and is not part of that pick — it ships the writing-voice guideline every repo in this setup uses
- Shared `.github/workflows/{phpstan,pint-check,rector-check,zizmor,update-changelog}.yml` + `.github/zizmor.yml` (rule config) + per-category `run-tests.yml` + `dependabot.yml`
- `tests/Pest.php` (Pest 5, Tia engine on for local runs) or `phpunit.xml` — vendor-driven default. Pest 5 needs a PHP `^8.4` floor
- `laravel-project` also gets the security canon — session-cookie flags as literals (`encrypt` / `secure` / `http_only` / `partitioned`), HSTS via `zae/strict-transport-security`, a `SecurityHeaders` middleware, and an `ApplicationIntegrityTest` that asserts the header contract. See [`references/laravel-security-canon.md`](references/laravel-security-canon.md)
- `laravel-project` also gets a Blade rule — a `@php ... @endphp` block, never the inline `@php(...)` directive — as a `laravel/boost` rule in `.ai/rules/views.md`, enforced by `tests/Unit/Blade/InlinePhpDirectiveTest.php`
- Per-category extras (testbench.yaml, workbench/, ServiceProvider, extension.neon, src/Plugin.{shape}.php for composer-plugin, etc.)

## Install (one-time per machine)

```bash
composer global require sandermuller/repo-init
composer global exec -- boost sync --scope=user --all
```

The second command publishes the `repo-init` skill, and the skills of every other globally installed [`sandermuller/boost-core`](https://github.com/SanderMuller/boost-core) consumer, into `~/.{claude,cursor,agents,…}/skills/repo-init-user/` (`sandermuller__repo-init/` before boost-core 1.13). The skill then activates in any project. `composer global exec --` runs `boost` from Composer's global `vendor/bin/`, and the `--` stops Composer from reading `boost`'s flags as its own. See `references/boost-core-user-scope.md` for the full contract.

## Use

Ask Claude (or any agent with the synced skill):

> Set up this repo as a Laravel package.
> Audit this repo against the canonical setup.
> Upgrade tooling here to current baseline.

The agent reads the `repo-init` skill, decides intent + category, and opens the matching phase file from `$(composer global config home)/vendor/sandermuller/repo-init/phases/`. Everything happens in your conversation; nothing is written to your target repo by repo-init itself (the agent does the writes, following the phase's instructions).

For a new repo, the [`repo new`](https://github.com/SanderMuller/repo-new) CLI (`composer global require sandermuller/repo-new`) does the mechanical scaffolding in one command. The skill uses it when version 1.2.0 or later is installed, and falls back to the manual phase steps otherwise.

## Update

```bash
composer global update sandermuller/repo-init
composer global exec -- boost sync --scope=user --all
```

The second line refreshes the user-scope skill dirs. Composer does not run it for you.

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
| `skill-bundle` | `type: library` + `sandermuller/boost-core` in `require` |

Each has its own bootstrap, audit, and upgrade phase file (23 phase files total — 7 audit + 7 upgrade + 9 bootstrap, the extra 2 bootstraps cover `filament-plugin` and `nova-tool` which fall through to `laravel-package` for audit/upgrade). `composer-plugin` covers framework-agnostic Composer plugins (e.g. boost-core, package-boost-php) with sub-flags for command-provider / event-subscriber shapes. `skill-bundle` covers distributable packages whose product is AI agent skills — `type: library`, `sandermuller/boost-core` in runtime `require`, ships `resources/boost/skills/`, no `src/`.

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

Optional skill cleanup (the synced user-level skill dirs survive `composer global remove` because `sync` writes file copies — see `references/boost-core-user-scope.md`):

```bash
rm -rf ~/.{claude,cursor,agents,amp,gemini,junie,kiro,opencode}/skills/{repo-init-user,sandermuller__repo-init}
```

(The brace expansion covers the 8 agent dirs boost-core writes. A `~/.{agent}/skills/repo-init/` folder from before boost-core 0.4 may also exist: check that it is repo-init's before you delete it. The next `composer global exec -- boost sync --scope=user --all` also removes an unedited copy. Keep the synced skills if you might re-install later: the install and sync commands overwrite them.)

## Design

See [`SPEC.md`](SPEC.md) for the full design (markdown-only + global-install model).

Highlights:

- Single entry point — [`resources/boost/skills/repo-init/SKILL.md`](resources/boost/skills/repo-init/SKILL.md).
- 23 self-contained phase playbooks under [`phases/`](phases/).
- 19 reference docs under [`references/`](references/) (incl. machine-readable [`per-category-deps.yml`](references/per-category-deps.yml) and the [Laravel security canon](references/laravel-security-canon.md)).
- 5 checklists under [`checklists/`](checklists/).
- 13 stub trees under [`stubs/`](stubs/) — `shared/` + 2 test-framework variants + 10 categories (composer-plugin, filament-plugin, laravel-package, laravel-package-spatie, laravel-project, nova-tool, php-package, phpstan-extension, rector-extension, skill-bundle).

## Dependencies

Runtime (`require`) — what `composer global require sandermuller/repo-init` pulls in for every consumer:

- [`sandermuller/boost-core`](https://github.com/SanderMuller/boost-core) — `type: library`. Ships the `vendor/bin/boost` bin and the `BoostAutoSync::run` auto-sync engine. `skill-bundle` wires `BoostAutoSync::run` in `post-install-cmd` / `post-update-cmd`. The package categories wire their wrapper's `AutoSync::run` façade, which delegates to it. `laravel-project` wires a dev-mode-guarded `artisan project-boost:sync` call instead. See [`references/composer-scripts.md`](references/composer-scripts.md).

Maintenance (`require-dev`) — used only by repo-init's own dev workflow; NOT propagated to consumers (Composer never installs a required package's `require-dev`):

- [`sandermuller/package-boost-php`](https://github.com/SanderMuller/package-boost-php) — the boost-family umbrella repo-init dogfoods (it's also what the `php-package` / `phpstan-extension` / `rector-extension` / `composer-plugin` scaffolds pin).
- [`sandermuller/boost-skills`](https://github.com/SanderMuller/boost-skills) — the shared dev-workflow skill library (code-review, bug-fixing, pre-release, evaluate, …); boost-core syncs its skills into repo-init's agent dirs at dev time.
- `laravel/pint` — code style.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Security

See [`SECURITY.md`](SECURITY.md).

## Changelog

See [`CHANGELOG.md`](CHANGELOG.md).

## License

MIT — see [`LICENSE`](LICENSE).
