
## Code-quality tooling

This project uses the hihaho rule packs for PHPStan and Rector:

- `hihaho/phpstan-rules` — Hihaho-flavoured PHPStan rules. Auto-loaded via `phpstan/extension-installer`.
- `hihaho/rector-rules` — Hihaho-flavoured Rector rules. Applied via `withSets([...Hihaho\RectorRules\Sets::ALL])` in `rector.php`.

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

- This project uses [`laravel/boost`](https://github.com/laravel/boost) — Laravel's own AI tooling, installed by `laravel new --boost`. It writes `boost.json` and wires the MCP server.
- Laravel Boost installs AI agent skills based on the packages detected in `composer.json`. Run `php artisan boost:install` once; `php artisan boost:update` re-syncs after dependency changes.
- The global-install `repo-init` skill — synced to `~/.claude/skills/sandermuller__repo-init/` when you `composer global require sandermuller/repo-init` — can audit or upgrade this repo's tooling against the canonical baseline.
