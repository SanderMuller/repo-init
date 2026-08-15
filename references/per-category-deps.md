# Per-category deps

What each category adds on top of the shared list (`shared-dev-deps.md`). Split into **MANDATORY** (audit flags MISSING if absent) and **OPTIONAL/CONDITIONAL** (audit flags only if user confirmed opt-in at audit-start prompt).

**Hard rule: no package appears in both `require` AND `require-dev` in the same row.** Per-category exclusions (`shared-dev-deps.md`) drop conflicting packages from the shared install for that category.

## MANDATORY (per category)

| Category | Adds to `require-dev` | Adds to `require` |
|---|---|---|
| `laravel-project` | `larastan/larastan`, `laravel/boost`, `laravel/pail`, `laravel/tinker`, `driftingly/rector-laravel` | (the `laravel new` baseline) |
| `laravel-package` | `larastan/larastan`, `laravel/boost`, `driftingly/rector-laravel`, `sandermuller/package-boost-laravel` | `illuminate/contracts`, `illuminate/support` at `__LARAVEL_VERSIONS__` |
| `php-package` | `phpstan/phpstan`, `stolt/lean-package-validator`, `sandermuller/package-boost-php` | (no `illuminate/*`) |
| `phpstan-extension` | `sandermuller/package-boost-php` (minus `phpstan/phpstan` per shared exclusion) | `phpstan/phpstan: ^2` |
| `rector-extension` | `sandermuller/package-boost-php` (minus `rector/rector` per §5.1.1) | `rector/rector: ^2`, `symplify/rule-doc-generator-contracts: ^11.2` |
| `composer-plugin` | `composer/composer: ^2.6`, `sandermuller/package-boost-php` | `composer-plugin-api: ^2.6` (and optionally `composer-runtime-api: ^2.2`) |
| `skill-bundle` | `laravel/pint`, `sandermuller/boost-skills`, `stolt/lean-package-validator` | `sandermuller/boost-core` (runtime) |

`laravel-package` `require` is intentionally minimal — `illuminate/contracts` + `illuminate/support`. Phase file tells the agent to extend per feature (add `illuminate/console`, `illuminate/queue`, `illuminate/redis`, etc. as the package uses them).

## OPTIONAL / CONDITIONAL (only flagged when opt-in confirmed)

| Category | Opt-in flag / sub-flag | Adds to `require-dev` | Adds to `require` |
|---|---|---|---|
| `laravel-project` | `--with-hihaho-rules` (default `y` for vendor=hihaho) | `hihaho/phpstan-rules`, `hihaho/rector-rules`, `symplify/phpstan-rules` | — |
| `laravel-project` | `--with-security-advisories` (default `N`) | `roave/security-advisories: dev-latest` | — |
| `laravel-package` | suggest (not mandatory) | `livewire/livewire` (suggested only — not auto-installed, not audited) | — |
| `laravel-package` | sub-flag `hihaho-package-tools-flavoured` (or `--variant=spatie`) | — | `spatie/laravel-package-tools` |
| `phpstan-extension` | Laravel-aware (has `illuminate/*` in `require`) | `larastan/larastan` (replaces shared `phpstan/phpstan`) | `illuminate/support` |
| `rector-extension` | Laravel-aware (`--with-laravel-sets`) | — | `driftingly/rector-laravel` |

## Opt-in inference (audit + upgrade)

Before walking deps, the audit phase confirms opt-ins. Where possible, infer the default from existing `composer.json` content:

- `--with-hihaho-rules` → `y` if vendor is `hihaho` OR `hihaho/phpstan-rules` already in `require-dev`.
- `--with-security-advisories` → `y` if `roave/security-advisories` already in `require-dev`.
- Laravel-aware phpstan-extension → `y` if `illuminate/*` already in `require`.
- Laravel-aware rector-extension → `y` if `driftingly/rector-laravel` already in `require` OR `require-dev`.
- Spatie-flavoured laravel-package → `y` if `spatie/laravel-package-tools` already in `require`.

For bootstrap, opt-ins come from user input directly (see SKILL.md "Knobs to collect").

## Notes on specific rows

### boost-family umbrella (per category, NOT shared)

The `sandermuller/boost-*` umbrella is assigned **per category**, not via the shared dev-deps list:

| Category shape | Boost-family dep (`require-dev`) |
|---|---|
| Framework-agnostic Composer package — `php-package`, `phpstan-extension`, `rector-extension`, `composer-plugin` | `sandermuller/package-boost-php` |
| Laravel-specific Composer package — `laravel-package` (+ `laravel-package-spatie`, `filament-plugin`, `nova-tool`) | `sandermuller/package-boost-laravel` |
| Laravel application — `laravel-project` | `laravel/boost` |
| Skill-distribution package — `skill-bundle` | `sandermuller/boost-core` directly, in runtime `require` |

All three umbrellas pull `sandermuller/boost-core` (the skill-sync engine, `type: library` from 0.6.0) transitively; `package-boost-laravel` also pulls `package-boost-php`. Neither `sandermuller/boost-core` nor `sandermuller/package-boost-php` is a composer-plugin anymore — both shed plugin status (boost-core in 0.6.0; package-boost-php in 0.9.0, when its subcommands moved to the standalone `vendor/bin/package-boost-php` bin). Scaffolds therefore need NO `sandermuller/*` entries in `config.allow-plugins`. Pre-0.9.0 scaffolds that still list `sandermuller/package-boost-php: true` (or `sandermuller/boost-core: true` from pre-0.6.0) carry harmless-but-stale entries — Composer ignores them; audit phases flag for removal. Audit and upgrade phases handle this drift; see each category's audit phase.

`composer-plugin` GETS `package-boost-php` like the other framework-agnostic categories — the pre-0.5.0 `shared-exclusions` entry that dropped it was removed.

`skill-bundle` is the exception: its product *is* AI skills, so it depends on `sandermuller/boost-core` (the engine, `type: library`) directly in runtime `require` — not via an umbrella, and not in `require-dev` (consumers need boost-core present to discover the shipped skills). Its `config.allow-plugins` is empty (no `boost-core` entry — `type: library`; no `package-boost-php` — not pulled in).

### `skill-bundle`

A distributable Composer package whose deliverable is the AI agent skills it ships under `resources/boost/skills/<skill-name>/SKILL.md`. Distinguishing characteristics:

- **`type: library`**, no `src/` PHP code. Detected by `sandermuller/boost-core` in runtime `require` (see `detection-rules.md`).
- **`require`**: `sandermuller/boost-core` — runtime, so consumers receive it transitively and can sync the skills. **Canonical floor `^1.6`**: 1.6.0 makes `boost sync` delete only boost-owned files (the ownership manifest that fixes `laravel/boost` coexistence), adds the `boost doctor` coexistence report, and bundles the `boost-command-surfaces` skill. It is additive over 1.1 — no API or config change.
- **`require-dev`**: `laravel/pint`, `sandermuller/boost-skills`, `stolt/lean-package-validator`. A skill-bundle ships pure-markdown skills and no PHP source, so it carries **no test runner** (no `pest`, no `phpunit`) and does not consume the shared dev-dep block — neither the PHPStan / Rector packs nor the shared test-framework block. In the yml, `consumes-shared-dev-deps: false` marks that; `sandermuller/boost-skills` is hand-listed in its `mandatory.require-dev` (the one shared library a skill bundle still wants), so the three above are its full dep set.
- **`config.allow-plugins`**: empty. `sandermuller/boost-core` is `type: library` from 0.6.0 — no allow-plugins entry required; if a pre-0.6.0 scaffold still lists `sandermuller/boost-core: true`, audit flags it for removal.
- Skips the PHP-toolchain stubs — see the `shared-stub-skip` key below.

### `shared-stub-skip`

`shared-stub-skip` is a per-category key in `per-category-deps.yml` — a **denylist** of `stubs/shared/` files a category does NOT plain-copy when it overlays the shared stub tree (because the file is handled specially, or does not apply). It is the machine-readable parallel of the skip prose in the bootstrap phases, so a CLI scaffolder can honour the skips without re-deriving them from prose.

- **Denylist, not allowlist** — absent ⇒ copy all of `stubs/shared/`. Consistent with `shared-exclusions`; a newly-added shared stub is caught by the category's bootstrap phase + audit, so silent leakage into a lean category is low-risk.
- **Entry form** — stub-relative paths, **PRE-rename**: `_gitattributes` (not `.gitattributes`). A trailing `/` marks a directory prefix (`tests/`).
- Populated for `laravel-project` (Laravel ships its own equivalents; `.config/boost.php` is boost-core-only) and `skill-bundle` (no PHP toolchain). The framework-agnostic categories also skip `.mcp.json` — currently expressed in their bootstrap-phase prose + audit per-category exclusions; the key can be extended to them if a consumer needs it machine-readable.

### `phpstan-extension` Laravel-aware

When this opt-in fires:

- `larastan/larastan` REPLACES the bare `phpstan/phpstan` that would otherwise be in `require-dev` (per `larastan` vs `phpstan/phpstan` exclusivity — see `phpstan-config.md`).
- The `require` `phpstan/phpstan: ^2` stays (so the extension's own `composer.json` keeps declaring its phpstan dependency cleanly for consumers).
- The agent's `composer require --dev` call lists `larastan/larastan` but NOT `phpstan/phpstan`. Composer will install both (larastan transitively pulls phpstan), but the lockfile shows only larastan as a direct dep.

### `rector-extension` Laravel-aware

When this opt-in fires:

- `driftingly/rector-laravel` is added to `require` (not `require-dev`) so the extension can use the Laravel rector sets in its own `config/config.php`.

### `--with-hihaho-rules`

Adds three packages to `require-dev`. `symplify/phpstan-rules` is bundled here because hihaho/phpstan-rules has it as a peer dep in practice (see `vendor/hihaho/phpstan-rules/extension.neon`).

### `laravel-package` runtime range

`illuminate/*` constraint defaults to `^12.0||^13.0` for new packages. Phase file asks the user if they want to restrict (e.g. `^13.0` only). Existing packages keep whatever they had — audit doesn't second-guess the range. Laravel 11 was dropped from the default in repo-init 0.3.0 because `laravel/pao` 1.0.5+ conflicts with `laravel/framework: <12.0.0`.

### `composer-plugin`

Framework-agnostic plugins that hook Composer's lifecycle. Distinguishing characteristics:

- **`require`**: `composer-plugin-api: ^2.6` is the contract version. Plugins targeting Composer 2.6+ APIs use this floor. Optionally also `composer-runtime-api: ^2.2` if the plugin uses `Composer\InstalledVersions` from inside the running app (rare for plugins; common for plugins that ship runtime helpers).
- **`require-dev`**: `composer/composer: ^2.6` for type hints, test fixtures, and `Composer\Command\BaseCommand` parent classes. This is dev-only — end users have Composer installed; pulling it into runtime bloats vendor by ~5 MB.
- **`extra.class`**: MUST be set to a FQCN implementing `Composer\Plugin\PluginInterface`. Audit verifies the class exists and implements the interface.
- **`config.allow-plugins`**: if the plugin declares itself in its own composer.json's `require-dev` (e.g. for dogfooding), the entry SHOULD allow-list itself. Audit flags if any required composer-plugin dependency is NOT in allow-plugins (will fail end-user install with "blocked" error).
- **Per-category exclusions from shared dev deps**: drop `orchestra/testbench` (testbench is for testing Laravel packages, not Composer plugins); drop `larastan/larastan` (no Laravel runtime); drop `pestphp/pest-plugin-laravel` (no Laravel runtime). The rest of the shared list applies as-is.
- **Sub-flag `command-provider`**: plugin ships `composer <name>` commands via `Composer\Plugin\Capability\CommandProvider`. Audit verifies provider class declared in `getCapabilities()` returns valid `BaseCommand` instances. If commands also need standalone-bin invocation (`vendor/bin/<plugin>`), they must work without `Composer\*` autoload (adapter pattern; see `sandermuller/boost-core` as reference).
- **Sub-flag `event-subscriber`**: plugin hooks `ScriptEvents` (POST_AUTOLOAD_DUMP, etc.) via `EventSubscriberInterface`. Audit verifies subscribed event constants exist.
