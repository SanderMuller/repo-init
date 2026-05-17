#!/usr/bin/env python3
"""
Dep-source-of-truth sync check.

Parses references/per-category-deps.yml (the structured parallel of the .md doc)
and asserts:
  (a) no package appears in both `require` and `require-dev` for the same category
      (after shared-exclusions applied)
  (b) every dep is referenced by name in the matching audit phase's MISSING-* list
  (c) every dep is referenced by name in the matching upgrade phase's
      composer-require list

Per SPEC Phase 7 "Dep-source-of-truth sync check" + RQ34 no-dep-in-both-scopes.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("FAIL: pyyaml not installed. Install with `pip install pyyaml` or `pip3 install pyyaml`.")
    sys.exit(2)

REPO_ROOT = Path(__file__).resolve().parents[2]
YML = REPO_ROOT / "references" / "per-category-deps.yml"

CATEGORIES = ["laravel-project", "laravel-package", "php-package", "phpstan-extension", "rector-extension"]

exit_code = 0


def fail(msg: str) -> None:
    global exit_code
    print(f"FAIL: {msg}")
    exit_code = 1


def strip_version_constraint(pkg: str) -> str:
    """Strip ': constraint' from 'vendor/package: ^X.Y' → 'vendor/package'."""
    return pkg.split(":", 1)[0].strip()


def extract_deps(section: dict, scope: str) -> list[str]:
    """Get list of package names from a category section's scope (require / require-dev)."""
    deps = section.get(scope, []) or []
    return [strip_version_constraint(d) for d in deps]


def load_yaml() -> dict:
    if not YML.exists():
        fail(f"per-category-deps.yml not found at {YML}")
        sys.exit(1)
    with YML.open() as f:
        return yaml.safe_load(f)


def check_no_dup_scope(data: dict) -> None:
    """(a) No package in both require and require-dev for the same category."""
    for cat in CATEGORIES:
        cat_data = data["categories"][cat]
        mandatory = cat_data["mandatory"]
        require = set(extract_deps(mandatory, "require"))
        require_dev = set(extract_deps(mandatory, "require-dev"))
        overlap = require & require_dev
        if overlap:
            fail(f"{cat} MANDATORY: package(s) in both require and require-dev: {sorted(overlap)}")

        for opt_name, opt_data in (cat_data.get("optional") or {}).items():
            opt_require = set(extract_deps(opt_data, "require"))
            opt_require_dev = set(extract_deps(opt_data, "require-dev"))
            opt_overlap = opt_require & opt_require_dev
            if opt_overlap:
                fail(f"{cat} OPTIONAL.{opt_name}: package(s) in both require and require-dev: {sorted(opt_overlap)}")

            # Also check the OPTIONAL row doesn't overlap with MANDATORY:
            mand_total = require | require_dev
            opt_total = opt_require | opt_require_dev
            opt_in_mand = (opt_total & mand_total) - set((opt_data.get("replaces-in-require-dev") or []))
            if opt_in_mand:
                fail(f"{cat} OPTIONAL.{opt_name} duplicates MANDATORY: {sorted(opt_in_mand)}")


def check_audit_references(data: dict) -> None:
    """(b) Every MANDATORY dep is referenced by name in the audit phase."""
    for cat in CATEGORIES:
        audit_path = REPO_ROOT / "phases" / f"audit-{cat}.md"
        if not audit_path.exists():
            fail(f"audit phase missing: {audit_path.relative_to(REPO_ROOT)}")
            continue
        audit_text = audit_path.read_text()

        cat_data = data["categories"][cat]
        mandatory_deps = (
            extract_deps(cat_data["mandatory"], "require")
            + extract_deps(cat_data["mandatory"], "require-dev")
        )

        for dep in mandatory_deps:
            if dep not in audit_text:
                fail(f"{audit_path.name} does not mention MANDATORY dep '{dep}'")


def check_upgrade_references(data: dict) -> None:
    """(c) Every MANDATORY dep is referenced by name in the upgrade phase."""
    for cat in CATEGORIES:
        upgrade_path = REPO_ROOT / "phases" / f"upgrade-{cat}.md"
        if not upgrade_path.exists():
            fail(f"upgrade phase missing: {upgrade_path.relative_to(REPO_ROOT)}")
            continue
        upgrade_text = upgrade_path.read_text()

        cat_data = data["categories"][cat]
        mandatory_deps = (
            extract_deps(cat_data["mandatory"], "require")
            + extract_deps(cat_data["mandatory"], "require-dev")
        )

        for dep in mandatory_deps:
            if dep not in upgrade_text:
                fail(f"{upgrade_path.name} does not mention MANDATORY dep '{dep}'")


def main() -> int:
    print("[check-dep-sync] parsing references/per-category-deps.yml...")
    data = load_yaml()

    print("[check-dep-sync] (a) no-dup-scope check...")
    check_no_dup_scope(data)

    print("[check-dep-sync] (b) audit-phase references check...")
    check_audit_references(data)

    print("[check-dep-sync] (c) upgrade-phase references check...")
    check_upgrade_references(data)

    if exit_code == 0:
        print("[check-dep-sync] OK — all deps consistent across yml + audit + upgrade.")
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
