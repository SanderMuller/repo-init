#!/usr/bin/env python3
"""
Rector-config sync check.

Asserts that every `stubs/<category>/rector.php`, `references/rector-config.md`
and the matching `phases/*-<category>.md` files agree. A phase file that promises
a rector.php the stub tree does not ship, or a Pest category whose stub never
registers the Pest set, fails CI.

Written after two defects of exactly this shape reached main:
  - stubs/laravel-project/rector.php shipped no PestSetList while all three of
    its phase files required pestphp/pest-plugin-rector
  - phases/audit-composer-plugin.md lists rector.php as an expected file with no
    stub anywhere to create it from

Per SPEC Phase 7. Runs on every push/PR touching phases/, references/ or stubs/.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
DOC = REPO_ROOT / "references" / "rector-config.md"

# Category model — mirrors check-phase-coverage.sh. Keep the two in sync.
FULL_CATEGORIES = [
    "laravel-project",
    "laravel-package",
    "php-package",
    "phpstan-extension",
    "rector-extension",
    "composer-plugin",
    "skill-bundle",
]
BOOTSTRAP_ONLY_CATEGORIES = ["filament-plugin", "nova-tool"]

# Variant trees are selected by a sub-flag and have no phase files of their own;
# they inherit the parent category's expectations (SPEC RQ18).
VARIANTS = {"laravel-package-spatie": "laravel-package"}

# Categories that ship no PHP source, so Rector has nothing to act on. The audit
# phase states the exclusion explicitly.
EXCLUDED_CATEGORIES = ["skill-bundle"]

LARAVEL_CATEGORIES = [
    "laravel-project",
    "laravel-package",
    "laravel-package-spatie",
    "filament-plugin",
    "nova-tool",
]

REQUIRED_CALLS = [
    "withCache(",
    "containerCacheDirectory:",
    "withPaths([",
    "withPreparedSets(",
    "withAttributesSets()",
    "withImportNames()",
    "withFluentCallNewLine()",
    "withParallel(",
    "withMemoryLimit(",
    "withPhpSets(",
    "withSkip([",
]

PREPARED_SET_FLAGS = [
    "deadCode",
    "codeQuality",
    "codingStyle",
    "typeDeclarations",
    "typeDeclarationDocblocks",
    "privatization",
    "instanceOf",
    "earlyReturn",
    "carbon",
    "rectorPreset",
    "phpunitCodeQuality",
]

LARAVEL_SETS = [
    "LARAVEL_CODE_QUALITY",
    "LARAVEL_ARRAYACCESS_TO_METHOD_CALL",
    "LARAVEL_CONTAINER_STRING_TO_FULLY_QUALIFIED_NAME",
    "LARAVEL_FACADE_ALIASES_TO_FULL_NAMES",
]

# Set names from the superseded mrpunyapal/rector-pest package. The phase files
# flag these as NON-CANONICAL, so no stub may ship them.
NON_CANONICAL_PEST = ["RectorPest", "PEST_CODE_QUALITY", "PEST_CHAIN", "PEST_LARAVEL"]

# Imports that are not skip-list entries, so they never appear in withSkip.
NON_SKIP_IMPORTS = {"FileCacheStorage", "RectorConfig", "LaravelSetList", "PestSetList"}

exit_code = 0


def fail(msg: str) -> None:
    global exit_code
    print(f"FAIL: {msg}")
    exit_code = 1


def stub_path(category: str) -> Path:
    return REPO_ROOT / "stubs" / category / "rector.php"


def phase_files(category: str) -> list[Path]:
    """Phase files whose expectations govern this category."""
    category = VARIANTS.get(category, category)
    modes = ["bootstrap"] if category in BOOTSTRAP_ONLY_CATEGORIES else ["bootstrap", "audit", "upgrade"]
    return [p for p in (REPO_ROOT / "phases" / f"{m}-{category}.md" for m in modes) if p.exists()]


def skip_block(text: str) -> str:
    match = re.search(r"withSkip\(\[(.*?)\]\);", text, re.S)
    return match.group(1) if match else ""


def check_required_calls(category: str, text: str) -> None:
    missing = [c for c in REQUIRED_CALLS if c not in text]
    if missing:
        fail(f"stubs/{category}/rector.php missing required call(s): {missing}")


def check_prepared_sets(category: str, text: str) -> None:
    match = re.search(r"withPreparedSets\((.*?)\n    \)", text, re.S)
    if not match:
        fail(f"stubs/{category}/rector.php has no parseable withPreparedSets()")
        return
    flags = dict(re.findall(r"(\w+):\s*(true|false)", match.group(1)))
    missing = [f for f in PREPARED_SET_FLAGS if f not in flags]
    if missing:
        fail(f"stubs/{category}/rector.php withPreparedSets missing flag(s): {missing}")
    off = [f for f in PREPARED_SET_FLAGS if flags.get(f) == "false"]
    if off:
        fail(f"stubs/{category}/rector.php withPreparedSets has flag(s) set false: {off}")


def check_pest_coupling(category: str, text: str) -> None:
    """A category whose phases require pest-plugin-rector must register the set."""
    phases = phase_files(category)
    if not phases:
        fail(f"{category}: no phase files resolved — category model out of date?")
        return

    needs_pest = any("pest-plugin-rector" in p.read_text() for p in phases)
    has_import = "use Pest\\Rector\\Set\\PestSetList;" in text
    has_set = "PestSetList::CODING_STYLE" in text

    if needs_pest and not (has_import and has_set):
        names = ", ".join(p.name for p in phases)
        fail(
            f"stubs/{category}/rector.php does not register the Pest set, but {names} "
            f"require pestphp/pest-plugin-rector (import={has_import}, set={has_set})"
        )
    if has_set and not has_import:
        fail(f"stubs/{category}/rector.php uses PestSetList::CODING_STYLE without importing PestSetList")


def check_non_canonical_pest(category: str, text: str) -> None:
    found = [n for n in NON_CANONICAL_PEST if n in text]
    if found:
        fail(f"stubs/{category}/rector.php ships superseded mrpunyapal/rector-pest form(s): {found}")


def check_laravel_sets(category: str, text: str) -> None:
    present = [s for s in LARAVEL_SETS if s in text]
    if category in LARAVEL_CATEGORIES:
        missing = [s for s in LARAVEL_SETS if s not in present]
        if missing:
            fail(f"stubs/{category}/rector.php missing Laravel set(s): {missing}")
    elif present:
        fail(f"stubs/{category}/rector.php is not a Laravel category but ships Laravel set(s): {present}")


def check_paths_match_doc(category: str, text: str, doc_rows: dict[str, list[str]]) -> None:
    match = re.search(r"withPaths\(\[(.*?)\]\)", text, re.S)
    if not match:
        fail(f"stubs/{category}/rector.php has no parseable withPaths()")
        return
    stub_paths = re.findall(r"__DIR__ \. '/([\w/]+)'", match.group(1))

    if category not in doc_rows:
        fail(f"references/rector-config.md per-category table has no row for '{category}'")
        return
    if doc_rows[category] != stub_paths:
        fail(
            f"withPaths mismatch for {category}: stub={stub_paths} "
            f"doc={doc_rows[category]} (references/rector-config.md table)"
        )


def check_skip_imports(category: str, text: str) -> None:
    imports = {m.split("\\")[-1] for m in re.findall(r"^use ([\w\\]+);", text, re.M)}
    skips = set(re.findall(r"^\s+(\w+Rector)::class", skip_block(text), re.M))

    unimported = skips - imports
    if unimported:
        fail(f"stubs/{category}/rector.php skips un-imported class(es) — fatal at runtime: {sorted(unimported)}")

    unused = imports - skips - NON_SKIP_IMPORTS
    if unused:
        fail(f"stubs/{category}/rector.php has unused import(s): {sorted(unused)}")


def check_skip_list_matches_doc(category: str, text: str, doc_skips: set[str]) -> None:
    skips = set(re.findall(r"^\s+(\w+Rector)::class", skip_block(text), re.M))
    if skips != doc_skips:
        fail(
            f"withSkip mismatch for {category}: doc-only={sorted(doc_skips - skips)} "
            f"stub-only={sorted(skips - doc_skips)} (references/rector-config.md 'stub defaults')"
        )


def check_pest_detector_is_armed() -> None:
    """Guard against the Pest assertion silently disarming.

    check_pest_coupling() only fires when a phase file names pestphp/pest-plugin-rector.
    If that string is renamed everywhere, the assertion would pass vacuously and stop
    protecting anything. Every full category is expected to name it today, so a drop to
    zero means the marker moved, not that Pest was dropped.
    """
    arming = [c for c in FULL_CATEGORIES if any("pest-plugin-rector" in p.read_text() for p in phase_files(c))]
    if not arming:
        fail(
            "no phase file names 'pest-plugin-rector' — the Pest coupling assertion is "
            "now vacuous. Update the marker in check_pest_coupling() to match the phases."
        )


def expected_categories() -> list[str]:
    """Every category that must ship a rector.php stub."""
    return [
        c
        for c in FULL_CATEGORIES + BOOTSTRAP_ONLY_CATEGORIES + list(VARIANTS)
        if c not in EXCLUDED_CATEGORIES
    ]


def check_every_expected_stub_exists(found: list[str]) -> None:
    """Assert the stub set, so a deleted stub cannot silently drop out of the loop.

    The per-stub checks iterate a glob, so a deleted rector.php is simply not visited
    and every assertion about it passes vacuously. Driving the expectation from the
    category model instead makes a deletion fail loudly, and flags an unexpected new
    stub directory the model does not know about.
    """
    for category in expected_categories():
        if not stub_path(category).exists():
            phases = phase_files(category)
            promising = ", ".join(p.name for p in phases if "rector.php" in p.read_text())
            detail = f" — {promising} reference rector.php" if promising else ""
            fail(
                f"stubs/{category}/rector.php does not exist{detail}. Add the stub, or state a "
                f"per-category exclusion and add the category to EXCLUDED_CATEGORIES "
                f"(see audit-skill-bundle.md)"
            )

    unexpected = sorted(set(found) - set(expected_categories()))
    if unexpected:
        fail(
            f"rector.php stub(s) for category/categories the model does not know about: {unexpected} — "
            f"add them to FULL_CATEGORIES / BOOTSTRAP_ONLY_CATEGORIES / VARIANTS"
        )


def parse_doc_rows() -> dict[str, list[str]]:
    """Category → withPaths list, from the per-category table.

    Scoped to that one section: an unscoped scan would also match any future
    two-column table whose cells happen to be backticked, silently overwriting a row.
    """
    doc = DOC.read_text()
    section = re.search(r"## Per-category `withPaths` and `withSets`\n(.*?)\n## ", doc, re.S)
    if not section:
        fail("references/rector-config.md has no '## Per-category `withPaths` and `withSets`' section")
        return {}

    rows = {}
    for category, paths in re.findall(r"^\|\s*`([a-z-]+)`\s*\|\s*`([^`]+)`\s*\|", section.group(1), re.M):
        rows[category] = [p.strip() for p in paths.split(",")]
    return rows


def parse_doc_skips() -> set[str]:
    doc = DOC.read_text()
    match = re.search(r"## `withSkip` — stub defaults.*?```php\n(.*?)```", doc, re.S)
    if not match:
        fail("references/rector-config.md has no parseable '## `withSkip` — stub defaults' code block")
        return set()
    return set(re.findall(r"(\w+Rector)::class", match.group(1)))


def main() -> int:
    if not DOC.exists():
        print(f"FAIL: {DOC.relative_to(REPO_ROOT)} not found")
        return 1

    stubs = sorted(REPO_ROOT.glob("stubs/*/rector.php"))
    print(f"[check-rector-sync] checking {len(stubs)} rector.php stub(s) against doc + phases...")

    doc_rows = parse_doc_rows()
    doc_skips = parse_doc_skips()

    found = [s.parent.name for s in stubs]
    check_every_expected_stub_exists(found)

    for stub in stubs:
        category = stub.parent.name
        text = stub.read_text()

        check_required_calls(category, text)
        check_prepared_sets(category, text)
        check_pest_coupling(category, text)
        check_non_canonical_pest(category, text)
        check_laravel_sets(category, text)
        check_paths_match_doc(category, text, doc_rows)
        check_skip_imports(category, text)
        check_skip_list_matches_doc(category, text, doc_skips)

    check_pest_detector_is_armed()


    if exit_code == 0:
        print("[check-rector-sync] OK — stubs, references/rector-config.md and phases agree.")
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
