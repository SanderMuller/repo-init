#!/usr/bin/env bash
# Validate YAML files in references/ for syntactic correctness.
# Surfaces YAML errors with a clear "invalid YAML" message before
# check-dep-sync.py runs (which would otherwise show a python traceback).
#
# Per code-review finding #10.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

EXIT_CODE=0

if ! command -v python3 >/dev/null 2>&1; then
    echo "FAIL: python3 not installed. CI must install python3 before running this check."
    exit 1
fi

# Inline check: requires PyYAML (also needed by check-dep-sync.py).
# If pyyaml missing, surface as an actionable error.
if ! python3 -c "import yaml" 2>/dev/null; then
    echo "FAIL: PyYAML not installed. Run 'pip install pyyaml' first (CI installs it before check-dep-sync.py)."
    exit 2
fi

YAML_FILES=(
    "references/per-category-deps.yml"
)

echo "[check-yaml-validity] validating ${#YAML_FILES[@]} YAML file(s)..."

for yaml_file in "${YAML_FILES[@]}"; do
    if [[ ! -f "$yaml_file" ]]; then
        echo "FAIL: YAML file missing: $yaml_file"
        EXIT_CODE=1
        continue
    fi

    if err=$(python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>&1); then
        echo "  ✓ $yaml_file"
    else
        echo "FAIL: $yaml_file is not valid YAML:"
        echo "$err" | sed 's/^/    /'
        EXIT_CODE=1
    fi
done

if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "[check-yaml-validity] OK — all YAML files syntactically valid."
fi

exit "$EXIT_CODE"
