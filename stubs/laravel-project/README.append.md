
## Code-quality tooling

This project uses the hihaho rule packs for PHPStan and Rector:

- `hihaho/phpstan-rules` — Hihaho-flavoured PHPStan rules. Auto-loaded via `phpstan/extension-installer`.
- `hihaho/rector-rules` — Hihaho-flavoured Rector rules. Applied via `withSets([HihahoSetList::ALL])` in `rector.php`. Three of its rules belong to no set and need `withConfiguredRule()` — see `references/rector-config.md`.

Plus the universal sander baseline:

- `larastan/larastan` — Laravel-aware PHPStan.
- `laravel/pint` — Laravel-conventioned code formatter.
- `rector/rector` + ecosystem extensions — automated refactoring.
- `spaze/phpstan-disallowed-calls` — bans debug helpers, exec-family, weak hashes.
- `tomasvotruba/cognitive-complexity` + `type-coverage` — quality gates.
- `laravel/pao` — agent-optimized output for phpunit/pest/pint/phpstan/rector.

Run `composer qa` to format + run Rector + PHPStan in sequence.

## Run

- Tests: `php artisan test` or `vendor/bin/phpunit`.
- Static analysis: `composer phpstan` (output) / `composer phpstan-simplified` (agent-friendly).
- Refactoring: `composer rector` (apply) / `vendor/bin/rector process --dry-run` (preview).
- Format: `composer format`.

## AI tooling

- This project uses [`laravel/boost`](https://github.com/laravel/boost) — Laravel's own AI tooling, installed by `laravel new --boost`. It wires the MCP server and ships the bundled Laravel skills.
- [`sandermuller/project-boost-laravel`](https://github.com/sandermuller/project-boost-laravel) syncs the agent files from `.config/boost.php`: the `laravel/boost` skills, filtered by tag, plus remote skills such as Cloudflare's `security-audit`. `composer install` runs the sync; run `php artisan project-boost:sync` after you edit `.config/boost.php`. Do not run `php artisan boost:update`.
- The global-install `repo-init` skill — synced to `~/.claude/skills/repo-init-user/` by `composer global exec -- boost sync --scope=user --all` after `composer global require sandermuller/repo-init` — can audit or upgrade this repo's tooling against the canonical baseline.
