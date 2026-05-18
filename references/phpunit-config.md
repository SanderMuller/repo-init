# PHPUnit config

Canonical `phpunit.xml` shape. Applies to every category that uses `test-framework=phpunit` (`phpstan-extension`, hihaho L-packages/projects, manual opt-ins).

## Canonical shape

See `$REPO_INIT_HOME/stubs/shared/phpunit.xml` for the full file. The load-bearing attributes:

```xml
<phpunit ...
         cacheDirectory=".cache/phpunit"
         executionOrder="random"
         failOnWarning="true"
         failOnRisky="true"
         failOnEmptyTestSuite="true"
         beStrictAboutOutputDuringTests="true">
```

## Cache directory rule

`cacheDirectory=".cache/phpunit"` is **mandatory**. Rationale:

- All tool caches (phpunit, rector, phpstan) live under `.cache/<tool>/` — one root, one `.gitignore` entry (`.cache`, already in `stubs/shared/.gitignore` line 13).
- PHPUnit's default cache location when `cacheDirectory` is unset is `.phpunit.cache/` at the repo root. That dir is NOT covered by the canonical `.gitignore` and **must never be committed**.

## Audit rule (NON-CANONICAL)

When the target uses PHPUnit, flag the following:

- [ ] **`.phpunit.cache/` directory present at repo root** (HIGH severity): PHPUnit's default cache leaked because `cacheDirectory` is missing or wrong. Flag NON-CANONICAL. Verify with `test -d .phpunit.cache`.
- [ ] **`phpunit.xml` missing `cacheDirectory` attribute** (HIGH severity): grep `<phpunit ...>` opening tag; if `cacheDirectory=` absent → flag NON-CANONICAL.
- [ ] **`phpunit.xml` `cacheDirectory` set but not to `.cache/phpunit`** (MEDIUM severity): drift from canonical. Flag NON-CANONICAL; suggest realignment.
- [ ] **`.phpunit.cache` committed to git** (HIGH severity): worse than just existing on disk — already in history. Flag NON-CANONICAL; upgrade must `git rm -r .phpunit.cache` and add to .gitignore as belt-and-suspenders.

## Upgrade actions

For each finding above, the matching upgrade step:

1. **Set `cacheDirectory` attribute** in `phpunit.xml` opening `<phpunit>` tag. If absent → add. If wrong value → fix to `.cache/phpunit`.
2. **Remove `.phpunit.cache/` from working tree**: `rm -rf .phpunit.cache`.
3. **If `.phpunit.cache` was committed**: `git rm -r --cached .phpunit.cache` then `rm -rf .phpunit.cache`. Optionally add explicit `.phpunit.cache/` line to `.gitignore` (the `.cache` line covers the new location; the explicit one defends against future regressions).
4. **Re-run tests** to populate `.cache/phpunit` cleanly and verify the new location works.

## Pest exception

Pest reuses PHPUnit's config. `tests/Pest.php` exists alongside `phpunit.xml` (Pest projects keep both). Same `cacheDirectory` rule applies — Pest writes the same cache, just via PHPUnit's mechanism.

If `phpunit.xml` is absent in a Pest project (some sandermuller packages skip it, relying on Pest defaults), no cache rule applies — Pest's own `.cache/` handling differs. Don't flag absence.
