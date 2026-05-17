
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

- `.claude/skills/`, `.cursor/skills/`, etc. are synced from `.ai/skills/` via `sandermuller/package-boost`.
- `php artisan package-boost:sync` re-syncs after edits to `.ai/`.
- Skills include the global-install `repo-init` skill (from `~/.claude/skills/repo-init/`), which can audit/upgrade this repo's tooling against the canonical baseline.
