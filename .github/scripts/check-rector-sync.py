#!/usr/bin/env python3
"""
Rector-config sync check.

Asserts that every `stubs/<category>/rector.php`, `references/rector-config.md`
and the matching `phases/*-<category>.md` files agree. Every stub builds on
`sandermuller/rector-preset`: it calls the preset that the doc table names for
its category, adds `withPhpSets()`, and calls nothing the preset owns. A phase
file that promises a rector.php the stub tree does not ship fails CI.

Written after a defect of this shape reached main:
phases/audit-composer-plugin.md listed rector.php as an expected file with no
stub anywhere to create it from. (An earlier defect, a stub without the Pest
set, is now the preset's job: it adds the set when the plugin is installed.)

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

PRESET_IMPORT = "use SanderMuller\\RectorPreset\\Preset;"

# The laravel-project stub configures hihaho/rector-rules rules the preset leaves
# unconfigured or does not register, and adds the opt-in fluent-validation sets.
# Each category may import only the preset plus the names listed here.
EXTRA_IMPORTS = {
    "laravel-project": [
        "use Hihaho\\RectorRules\\Rector\\CodeQuality\\FirstPartyFlagArgumentToNamedRector;",
        "use Hihaho\\RectorRules\\Rector\\CodeQuality\\NamedArgumentFromManifestRector;",
        "use Hihaho\\RectorRules\\Rector\\CodeQuality\\NativeFunctionFlagArgumentToNamedRector;",
        "use Hihaho\\RectorRules\\Rector\\CodeQuality\\RemoveDefaultValuedArgumentRector;",
        "use Hihaho\\RectorRules\\Rector\\Routing\\MiddlewareStringToClassRector;",
        "use Hihaho\\RectorRules\\Rector\\Testing\\TestFieldStringToConstantRector;",
        "use Illuminate\\Auth\\Middleware\\Authenticate;",
        "use Illuminate\\Routing\\Middleware\\ThrottleRequests;",
        "use SanderMuller\\FluentValidationRector\\Set\\FluentValidationSetList;",
    ],
}

# Sets a category may add with withSets(): the ones the preset leaves opt-in.
ALLOWED_SETS = {
    "laravel-project": [
        "FluentValidationSetList::SCHEMA",
        "FluentValidationSetList::VALIDATED_INPUT",
    ],
}
PHP_SETS_CALL = "->withPhpSets(php__PHP_VERSION_NEON__: true);"

# Calls and set lists the preset owns. A stub that repeats one duplicates or
# overrides it: withPaths() replaces the detected paths, for example.
PRESET_OWNED = [
    "RectorConfig::configure(",
    "withCache(",
    "withPreparedSets(",
    "withComposerBased(",
    "withParallel(",
    "withMemoryLimit(",
    "withImportNames(",
    "withAttributesSets(",
    "withFluentCallNewLine(",
    "withPaths(",
    "withSets(",
    "LaravelSetList",
    "PestSetList",
    "HihahoSetList",
]

# Parameters Rector 2.6 marks @deprecated on withPreparedSets(). The preset
# does not accept them, so a stub that passes one fails at runtime.
DEPRECATED_PRESET_ARGS = ["instanceOf:", "if:", "earlyReturn:"]

DEP_LINE = re.compile(r'^\s+- "sandermuller/rector-preset: ~\d+\.\d+\.0"', re.M)
DEPS = REPO_ROOT / "references" / "per-category-deps.yml"

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


def normalise(call: str) -> str:
    return re.sub(r"//[^\n]*", "", call).replace(" ", "").replace("\n", "").replace(",)", ")")


def stub_preset_call(text: str) -> str | None:
    code = re.sub(r"//[^\n]*", "", text)
    match = re.search(r"return (Preset::\w+\(.*?\))\s*->", code, re.S)
    return normalise(match.group(1)) if match else None


def check_shape(category: str, text: str) -> None:
    imports = re.findall(r"^use [\w\\]+;", text, re.M)
    expected_imports = sorted([PRESET_IMPORT, *EXTRA_IMPORTS.get(category, [])])
    if sorted(imports) != expected_imports:
        fail(f"stubs/{category}/rector.php must import {expected_imports}, found: {imports}")
    if PHP_SETS_CALL not in text:
        fail(f"stubs/{category}/rector.php does not call {PHP_SETS_CALL}")
    code = re.sub(r"//[^\n]*", "", text)
    allowed_sets = ALLOWED_SETS.get(category, [])
    for sets_call in re.findall(r"withSets\(\[(.*?)\]\)", code, re.S):
        sets = [x.strip() for x in sets_call.split(",") if x.strip()]
        extra = [x for x in sets if x not in allowed_sets]
        if extra:
            fail(f"stubs/{category}/rector.php adds set(s) the preset owns or that are not allowed: {extra}")
    if allowed_sets:
        code = re.sub(r"withSets\(\[.*?\]\)", "", code, flags=re.S)
    owned = [c for c in PRESET_OWNED if c in code]
    if owned:
        fail(f"stubs/{category}/rector.php calls what the preset owns: {owned}")
    deprecated = [a for a in DEPRECATED_PRESET_ARGS if a in code]
    if deprecated:
        fail(f"stubs/{category}/rector.php passes deprecated argument(s): {deprecated}")


def check_preset_matches_doc(category: str, text: str, doc_rows: dict[str, str]) -> None:
    expected = doc_rows.get(category, doc_rows.get("every other category"))
    if expected is None:
        fail(f"references/rector-config.md preset table has no row for '{category}'")
        return
    actual = stub_preset_call(text)
    if actual != normalise(expected):
        fail(f"preset mismatch for {category}: stub={actual} doc={expected} (references/rector-config.md table)")


def check_dependency_listed() -> None:
    if not DEP_LINE.search(DEPS.read_text()):
        fail("references/per-category-deps.yml does not list sandermuller/rector-preset with a ~X.Y.0 constraint")


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


def parse_doc_rows() -> dict[str, str]:
    """Rows include the 'every other category' fallback key."""
    doc = DOC.read_text()
    section = re.search(r"## The preset\n(.*?)\n## ", doc, re.S)
    if not section:
        fail("references/rector-config.md has no '## The preset' section")
        return {}

    rows = {}
    for category, call in re.findall(r"^\|\s*`?([a-z -]+?)`?\s*\|\s*`(Preset::[^`]+)`\s*\|", section.group(1), re.M):
        rows[category] = call
    return rows


def main() -> int:
    if not DOC.exists():
        print(f"FAIL: {DOC.relative_to(REPO_ROOT)} not found")
        return 1

    stubs = sorted(REPO_ROOT.glob("stubs/*/rector.php"))
    print(f"[check-rector-sync] checking {len(stubs)} rector.php stub(s) against doc + phases...")

    doc_rows = parse_doc_rows()

    found = [s.parent.name for s in stubs]
    check_every_expected_stub_exists(found)
    check_dependency_listed()

    for stub in stubs:
        category = stub.parent.name
        text = stub.read_text()

        check_shape(category, text)
        check_preset_matches_doc(category, text, doc_rows)

    if exit_code == 0:
        print("[check-rector-sync] OK — stubs, references/rector-config.md and phases agree.")
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
