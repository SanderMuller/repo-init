# Shared dev deps

Universal `require-dev` list applied to every category (with per-category exclusions listed below).

## Shared list

```
laravel/pao
laravel/pint
phpstan/extension-installer
phpstan/phpstan-strict-rules
phpstan/phpstan-deprecation-rules
phpstan/phpstan-phpunit
rector/rector
rector/type-perfect          # PHP 8.3 floor ONLY — on PHP >= 8.4 it is dropped (tomasvotruba/type-coverage ^2.3 bundles it) — see "Type-perfect dep" below
spaze/phpstan-disallowed-calls
symplify/phpstan-rules        # PHP >= 8.4; PHP 8.3 floor keeps symplify/phpstan-extensions ^12.0 instead — see "Symplify formatter dep" below
tomasvotruba/cognitive-complexity
tomasvotruba/type-coverage    # constraint is PHP-floor-conditional: >=2.2.0 <2.2.2 (PHP 8.3 floor) / ^2.3 (PHP >= 8.4) — see "Type-perfect dep" below
nunomaduro/collision
orchestra/testbench
sandermuller/boost-skills    # floor ^2.27.0 — the version that ships the voice guideline the always-on `voice` tag needs
```

The boost-family umbrella (`sandermuller/package-boost-php` / `package-boost-laravel`) is **NOT** in this shared list — it is assigned per category. See `per-category-deps.md` → "boost-family umbrella".

Test-framework split (`test-framework=pest|phpunit`):

- **`pest`** adds: `pestphp/pest`, `pestphp/pest-plugin-arch`, `mrpunyapal/rector-pest`. Laravel categories also add `pestphp/pest-plugin-laravel`.
- **`phpunit`** adds: `phpunit/phpunit`.

## Why these

- `laravel/pao` — agent-optimized output for phpunit/pest/pint/phpstan/rector/paratest. Framework-agnostic. Floor `^8.3` (matches our hard floor; see `version-defaults.md`).
- `laravel/pint` — code formatter.
- `phpstan/extension-installer` — auto-includes phpstan extension configs.
- `phpstan/phpstan-strict-rules`, `-deprecation-rules`, `-phpunit` — common rule packs.
- `rector/rector` — automated refactoring.
- `rector/type-perfect` — type-narrowing rules. **Abandoned upstream**, replaced by `tomasvotruba/type-coverage`; carried only on a PHP 8.3 floor — see "Type-perfect dep" below.
- `spaze/phpstan-disallowed-calls` — bans dangerous/execution/insecure calls.
- `symplify/phpstan-rules` — adds the symplify error formatter (`phpstan-simplified` script). PHP-floor-conditional — see below.
- `tomasvotruba/cognitive-complexity` — complexity rules.
- `tomasvotruba/type-coverage` — enforces 100% type coverage. From 2.3.0 it also absorbs `rector/type-perfect`'s rules — constraint is PHP-floor-conditional, see "Type-perfect dep" below.
- `nunomaduro/collision` — better error output in CLI.
- `orchestra/testbench` — package-category test bootstrap (no longer required for AI sync; boost-core's standalone bin handles that).
- `sandermuller/boost-skills` — the boost-skills skill library (generic dev-workflow skills: code-review, bug-fixing, write-spec, evaluate, …). Synced via boost-core; the active subset is filtered by the `withTags()` call in `.config/boost.php`. **Canonical floor `^2.27.0`** — it is the version verified to ship `resources/boost/guidelines/voice.md` plus its `.boost-tags.yaml` `voice` mapping, which the always-on `voice` tag needs; a lower resolved version makes that tag a silent no-op. See `placeholder-rules.md` (`__SKILL_TAGS__`). **Excluded for `laravel-project`** — it uses `laravel/boost`, not boost-core, so boost-skills would be inert there. `skill-bundle` hand-lists it in its own `mandatory.require-dev` because it opts out of the shared list (`consumes-shared-dev-deps: false`).

The boost-family umbrella is assigned **per category** — see the line above the "Why these" heading and, for the full mapping + the `config.allow-plugins` rule, `per-category-deps.md` → "boost-family umbrella" (its single source of truth).

## Symplify formatter dep is PHP-floor-conditional (single source of truth)

`symplify/phpstan-extensions` was **abandoned upstream** at 12.0.2 (Nov 2025). Its features (the `symplify` error formatter used by the `phpstan-simplified` script, plus return-type extensions) were merged into `symplify/phpstan-rules` **14.11.0** (Jun 2026). The merged release is a drop-in for our usage: `--error-format symplify` works unchanged via `phpstan/extension-installer`, and no extra rules are enabled by default (`ctor`, `mocks`, `maximumIgnoredErrorCount`, and the return-type extension params all default off).

The catch: `symplify/phpstan-rules` ≥ 14.11 requires **PHP ^8.4** (and PHPStan ^2.2), while our hard PHP floor is `^8.3` (see `version-defaults.md`). So the dep is conditional on the target's `require.php` floor:

| Target `require.php` floor | Canonical dep | Status |
|---|---|---|
| `^8.4` or `^8.5` | `symplify/phpstan-rules: ^14.12` | Canonical |
| `^8.3` | `symplify/phpstan-extensions: ^12.0` | Allowed — abandoned upstream but functional with PHPStan 2; ADVISORY note in audit: bumping the PHP floor to `^8.4` drops the abandoned package |

Rules derived from the table:

- **Bootstrap**: stubs ship `symplify/phpstan-extensions: ^12.0` — installable on every accepted floor, so a consumer that only does placeholder substitution still emits a working `composer.json` at the default `php=8.3`. When the user picks `php=8.4` or `8.5`, replace it with `symplify/phpstan-rules: ^14.12` in the same composer.json pass, AND align the `run-tests.yml` matrix with the chosen floor: drop cells below it (the shipped `8.3` cells assume the default `^8.3` floor and would fail `composer update` against a higher `require.php` — and against `symplify/phpstan-rules`'s PHP ^8.4) and add cells the stub matrix lacks (it ships `8.3`/`8.4` cells only, so `php=8.5` needs an `8.5` cell).
- **Audit**: the formatter line is satisfied by `symplify/phpstan-rules: ^14.12` (PHP ≥ 8.4 floor) or by `symplify/phpstan-extensions: ^12.0` (PHP 8.3 floor — with the ADVISORY above). A PHP ≥ 8.4 repo with `symplify/phpstan-extensions` is NON-CANONICAL (migrate to `symplify/phpstan-rules: ^14.12`). A `symplify/phpstan-rules` constraint that can resolve below 14.11 does NOT satisfy the line — versions before 14.11 ship no error formatter, so `phpstan-simplified` breaks. Neither satisfied = MISSING.
- **Upgrade**: when the repo's PHP floor is ≥ 8.4, migrate — `composer remove --dev symplify/phpstan-extensions && composer require --dev symplify/phpstan-rules:^14.12`. No config changes needed (`phpstan-simplified` keeps `--error-format symplify`). Note for laravel-project `--with-hihaho-rules`: that bundle already adds `symplify/phpstan-rules`; on a PHP ≥ 8.4 floor pin it `^14.12` and it satisfies this line on its own — on a PHP 8.3 floor it resolves below 14.11 (no formatter), so `symplify/phpstan-extensions: ^12.0` is still required alongside it.

## Type-perfect dep is PHP-floor-conditional (single source of truth)

`rector/type-perfect` was **abandoned upstream**, replacement `tomasvotruba/type-coverage`. `tomasvotruba/type-coverage` **2.3.0** absorbed type-perfect's rules — its `extra.phpstan.includes` now lists `packages/type-perfect/config/extension.neon` alongside its own `config/extension.neon`.

That makes the two packages mutually exclusive. With both installed, `phpstan/extension-installer` includes type-perfect's `extension.neon` **twice** (once from each package) and PHPStan aborts at boot on the duplicate service (`MethodNodeAnalyser` registered twice). This is a hard failure — PHPStan does not start at all.

The catch: `tomasvotruba/type-coverage` ≥ 2.2.2 requires **PHP ^8.4**, while our hard PHP floor is `^8.3` (see `version-defaults.md`). And Composer resolves against the **runtime** PHP, not `require.php` — so an unconstrained `^2.2` on a PHP 8.3-floor repo installs 2.2.1 on the `8.3` CI cell but **2.3.0 on the `8.4` cell**, which is exactly where the boot failure fires. The constraint therefore has to be pinned by floor:

| Target `require.php` floor | Canonical deps | Why |
|---|---|---|
| `^8.4` or `^8.5` | `tomasvotruba/type-coverage: ^2.3` — and NO `rector/type-perfect` | 2.3 bundles the type-perfect rules; `^2.3` (not `^2.2`) is required, or resolution could land on 2.2.2, which registers no `type_perfect` params and fails boot the other way |
| `^8.3` | `tomasvotruba/type-coverage: >=2.2.0 <2.2.2` **plus** `rector/type-perfect: ^2.1` | 2.2.1 is the newest release that installs on PHP 8.3 — **both** 2.2.2 and 2.3.0 require PHP ^8.4. The cap has to be `<2.2.2`, not `<2.3`: it keeps the `8.4` CI cell off 2.3.0 (the duplicate registration) AND keeps an 8.4 dev machine from locking 2.2.2, which the `8.3` cell then can't install. ADVISORY: bumping the PHP floor to `^8.4` drops the abandoned package and uncaps the constraint |

Either way the stub `phpstan.neon.dist` keeps its `parameters.type_perfect:` block — exactly one of the two packages registers those params on every accepted floor.

Rules derived from the table:

- **Bootstrap**: stubs ship the PHP 8.3-floor pair (`rector/type-perfect: ^2.1` + `tomasvotruba/type-coverage: >=2.2.0 <2.2.2`) — installable on every accepted floor, so a consumer that only does placeholder substitution emits a working `composer.json` at the default `php=8.3`. When the user picks `php=8.4` or `8.5`, in the same composer.json pass **remove** `rector/type-perfect` and change `tomasvotruba/type-coverage` to `^2.3`.
- **Audit**: `tomasvotruba/type-coverage` present with a floor-appropriate constraint satisfies the line. `rector/type-perfect` is required on a PHP 8.3 floor and NON-CANONICAL on a PHP ≥ 8.4 floor. **HIGH severity**: `rector/type-perfect` present alongside a `tomasvotruba/type-coverage` constraint that can resolve to ≥ 2.3 (e.g. an `^2.2` scaffolded before this rule landed, or `^2`, or `*`) — PHPStan won't boot on any PHP 8.4+ runner. Every repo scaffolded before this rule landed is in that state.
- **Upgrade**: the migration runs on ANY target that still has `rector/type-perfect` in `require-dev`, and it must run **before** the phase's MISSING-dev-deps step — that step raises `tomasvotruba/type-coverage` to its canonical constraint, which on a PHP ≥ 8.4 floor is `^2.3`, and doing so alongside type-perfect *creates* the broken pair. Do not gate the migration on the audit's duplicate-registration finding: an older target on `^2.1` doesn't trip that finding yet is equally broken once the dep step runs.
  - PHP ≥ 8.4 floor: `composer remove --dev rector/type-perfect --no-update` then `composer require --dev tomasvotruba/type-coverage:^2.3`. The `--no-update` is what makes it **one resolution** — the removal is a pure `composer.json` edit, so `vendor/` never holds both packages. (Equivalently: hand-edit both lines, then one `composer update rector/type-perfect tomasvotruba/type-coverage`.) A plain `composer remove` first resolves immediately and leaves `parameters.type_perfect:` unregistered while type-coverage is still `< 2.3` — PHPStan then fails boot the other way.
  - PHP 8.3 floor: keep both, but tighten `tomasvotruba/type-coverage` to `>=2.2.0 <2.2.2` and run `composer update tomasvotruba/type-coverage` — this is the fix for the HIGH finding above.

## Per-category exclusions

When a category puts a package in its `require` (per `per-category-deps.md`), it must be REMOVED from the shared dev-deps install for that category — Composer rejects a package being in both `require` and `require-dev`.

| Category | Drop from shared list | Because added to `require` |
|---|---|---|
| `rector-extension` | `rector/rector` | `rector/rector: ^2` |
| `phpstan-extension` | `phpstan/phpstan` (bare) — the `-strict-rules`/`-deprecation-rules`/`-phpunit`/`-extension-installer` stay | `phpstan/phpstan: ^2` |
| `laravel-package` (sub-flag `hihaho-package-tools-flavoured`) | (none — `spatie/laravel-package-tools` isn't in shared) | `spatie/laravel-package-tools` |
| Others | (none) | — |

Note: the shared list above does not directly include bare `phpstan/phpstan`. It enters transitively via `larastan/larastan` (Laravel categories) or via `phpstan/phpstan-strict-rules`. For non-Laravel categories (`php-package`, `phpstan-extension`), `phpstan/phpstan` is added explicitly via `per-category-deps.md` (in `require-dev` for php-package; in `require` for phpstan-extension).

## Audit honours exclusions

A `rector-extension` repo with `rector/rector` in `require` and absent from `require-dev` is **correct**, not MISSING. Same for `phpstan/phpstan` in `phpstan-extension`.

## Audit verification protocol (MANDATORY)

**The agent MUST check each package line-by-line, not skim.** Real audits have missed `laravel/pao` (and similar) because the agent read the section structure and assumed compliance instead of verifying each entry.

Required protocol for the `## MISSING dev deps` section of every audit phase:

1. **Read the target's `composer.json` `require-dev` block once.** Extract package names into a set.
2. **For each bullet in the canonical list** (shared + category-mandatory + test-framework, minus per-category exclusions): explicitly state "PRESENT" or "MISSING" against the extracted set. Don't aggregate ("looks fine") — call each one out by name.
3. **Print a verification line** in the audit report listing every MISSING entry. If none are missing, print "all required dev-deps present (N/N checked)" with the count.
4. **Do NOT trust visual scanning.** If the canonical list has 16 entries and you only mentioned 8 in your response, you skipped half. The check is mechanical: 1 bullet = 1 explicit verdict.

This protocol applies regardless of category. Per-category exclusions (above) trim the canonical list BEFORE this check runs — once trimmed, every remaining bullet gets verified.
