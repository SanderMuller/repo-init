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
spaze/phpstan-disallowed-calls
symplify/phpstan-rules        # ^14.12 — see "Symplify formatter dep" below
tomasvotruba/cognitive-complexity
tomasvotruba/type-coverage    # ^2.3 — it bundles the abandoned rector/type-perfect; see "Type-perfect dep" below
nunomaduro/collision
orchestra/testbench
sandermuller/boost-skills    # floor ^2.27.0 — the version that ships the voice guideline the always-on `voice` tag needs
```

The boost-family umbrella (`sandermuller/package-boost-php` / `package-boost-laravel`) is **NOT** in this shared list — it is assigned per category. See `per-category-deps.md` → "boost-family umbrella".

Test-framework split (`test-framework=pest|phpunit`):

- **`pest`** adds: `pestphp/pest: ^5.0`, `pestphp/pest-plugin-arch: ^5.0`, `pestphp/pest-plugin-rector: ^5.0`, `pestphp/pest-plugin-phpstan: ^5.0`, `pestphp/pest-plugin-agent: ^5.0`. Laravel categories also add `pestphp/pest-plugin-laravel: ^5.0`. Pest 5 requires PHP `^8.4`, which every category now floors at or above. `mrpunyapal/rector-pest` is NOT canonical any more; `pestphp/pest-plugin-rector` replaces it.
- **`phpunit`** adds: `phpunit/phpunit`.

## Why these

- `laravel/pao` — agent-optimized output for phpunit/pest/pint/phpstan/rector/paratest. Framework-agnostic. Its own floor is `^8.3`, below every floor repo-init now scaffolds (see `version-defaults.md`).
- `laravel/pint` — code formatter.
- `phpstan/extension-installer` — auto-includes phpstan extension configs.
- `phpstan/phpstan-strict-rules`, `-deprecation-rules`, `-phpunit` — common rule packs.
- `rector/rector` — automated refactoring.
- `spaze/phpstan-disallowed-calls` — bans dangerous/execution/insecure calls.
- `symplify/phpstan-rules` — adds the symplify error formatter (`phpstan-simplified` script) AND the opt-in rule set the canonical `phpstan.neon.dist` registers by hand. See "Symplify formatter dep" below and `phpstan-config.md` → "Symplify rules".
- `tomasvotruba/cognitive-complexity` — complexity rules.
- `tomasvotruba/type-coverage` — enforces 100% type coverage. From 2.3.0 it also bundles the abandoned `rector/type-perfect`'s rules, which is why `rector/type-perfect` must NOT be installed alongside it. See "Type-perfect dep" below.
- `nunomaduro/collision` — better error output in CLI.
- `orchestra/testbench` — package-category test bootstrap (no longer required for AI sync; boost-core's standalone bin handles that). On a Pest 5 repo the constraint is `^11.0` only — testbench 10 pins `symfony/process: ^7.2` and Pest 5 needs `^8.1`, so the pair cannot install. See `pest-vs-phpunit.md` → "Pest 5 and orchestra/testbench".
- `sandermuller/boost-skills` — the boost-skills skill library (generic dev-workflow skills: code-review, bug-fixing, write-spec, evaluate, …). Synced via boost-core; the active subset is filtered by the `withTags()` call in `.config/boost.php`. **Canonical floor `^2.27.0`** — it is the version verified to ship `resources/boost/guidelines/voice.md` plus its `.boost-tags.yaml` `voice` mapping, which the always-on `voice` tag needs; a lower resolved version makes that tag a silent no-op. See `placeholder-rules.md` (`__SKILL_TAGS__`). **Excluded for `laravel-project`** — it uses `laravel/boost`, not boost-core, so boost-skills would be inert there. `skill-bundle` hand-lists it in its own `mandatory.require-dev` because it opts out of the shared list (`consumes-shared-dev-deps: false`).

The boost-family umbrella is assigned **per category** — see the line above the "Why these" heading and, for the full mapping + the `config.allow-plugins` rule, `per-category-deps.md` → "boost-family umbrella" (its single source of truth).

## Symplify formatter dep (single source of truth)

`symplify/phpstan-extensions` was **abandoned upstream** at 12.0.2 (Nov 2025). Its features (the `symplify` error formatter used by the `phpstan-simplified` script, plus return-type extensions) were merged into `symplify/phpstan-rules` **14.11.0** (Jun 2026). The merged release is a drop-in for that usage: `--error-format symplify` works unchanged via `phpstan/extension-installer`.

Canonical dep: **`symplify/phpstan-rules: ^14.12`**, unconditionally. It requires PHP `^8.4` and PHPStan `^2.2`; every category repo-init scaffolds floors at `^8.4` or higher, so there is no second branch. A constraint that can resolve below 14.11 does NOT satisfy the line — those versions ship no error formatter and `phpstan-simplified` breaks.

`symplify/phpstan-extensions` in `require-dev` is NON-CANONICAL on any repo. Upgrade: `composer remove --dev symplify/phpstan-extensions && composer require --dev symplify/phpstan-rules:^14.12`. No config change is needed for the formatter (`phpstan-simplified` keeps `--error-format symplify`) — but see `phpstan-config.md`, because the canonical `phpstan.neon.dist` also registers this package's opt-in rules, which auto-registration does not reach.

For `laravel-project` with `--with-hihaho-rules`: that bundle already adds `symplify/phpstan-rules`; pin it `^14.12` and it satisfies this line on its own.

## Type-perfect dep (single source of truth)

`rector/type-perfect` was **abandoned upstream**, replacement `tomasvotruba/type-coverage`. `tomasvotruba/type-coverage` **2.3.0** absorbed type-perfect's rules — its `extra.phpstan.includes` now lists `packages/type-perfect/config/extension.neon` alongside its own `config/extension.neon`.

That makes the two packages mutually exclusive. With both installed, `phpstan/extension-installer` includes type-perfect's `extension.neon` **twice** (once from each package) and PHPStan aborts at boot on the duplicate service (`MethodNodeAnalyser` registered twice). This is a hard failure — PHPStan does not start at all.

Canonical: **`tomasvotruba/type-coverage: ^2.3` and NO `rector/type-perfect`**, unconditionally. `^2.3` rather than `^2.2`, or resolution can land on 2.2.2, which registers no `type_perfect` params and fails boot the other way. The stub `phpstan.neon.dist` keeps its `parameters.type_perfect:` block — type-coverage `^2.3` registers those params.

Rules derived from this:

- **Audit**: `rector/type-perfect` anywhere in `require-dev` is **HIGH severity** — PHPStan will not boot on any PHP 8.4+ runner once type-coverage resolves to ≥ 2.3. Every repo scaffolded before this rule landed is in that state.
- **Upgrade (ATOMIC)**: `composer remove --dev rector/type-perfect --no-update` then `composer require --dev tomasvotruba/type-coverage:^2.3`. The `--no-update` is what makes it **one resolution** — the removal is a pure `composer.json` edit, so `vendor/` never holds both packages. A plain `composer remove` first resolves immediately and leaves `parameters.type_perfect:` unregistered while type-coverage is still `< 2.3`, which fails boot the other way. This migration must run BEFORE the phase's MISSING-dev-deps step, which would otherwise raise type-coverage to `^2.3` while type-perfect is still installed and *create* the broken pair.

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
