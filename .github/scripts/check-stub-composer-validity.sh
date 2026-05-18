#!/usr/bin/env bash
# Validate each stub composer.json after dummy-placeholder substitution.
# A typo in a stub's JSON would only surface when someone scaffolds with it
# — this check catches it at CI time.
#
# Per code-review finding #9.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

EXIT_CODE=0

if ! command -v composer >/dev/null 2>&1; then
    echo "FAIL: composer not installed. CI must install composer before running this check."
    exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

DUMMY_VENDOR="dummy"
DUMMY_PACKAGE="test-stub"
DUMMY_VENDOR_STUDLY="Dummy"
DUMMY_PACKAGE_STUDLY="TestStub"
DUMMY_NAMESPACE="Dummy\\\\TestStub"
DUMMY_NAMESPACE_ESCAPED="Dummy\\\\\\\\TestStub"
DUMMY_AUTHOR_NAME="Dummy Author"
DUMMY_AUTHOR_EMAIL="dummy@example.com"
DUMMY_PHP_VERSION="^8.3"
DUMMY_LARAVEL_VERSIONS="^11.0||^12.0||^13.0"
DUMMY_PHP_VERSION_NEON="83"
DUMMY_DESCRIPTION="A stub package for CI validation"

substitute() {
    sed \
        -e "s/__VENDOR_STUDLY__/$DUMMY_VENDOR_STUDLY/g" \
        -e "s/__PACKAGE_STUDLY__/$DUMMY_PACKAGE_STUDLY/g" \
        -e "s/__VENDOR__/$DUMMY_VENDOR/g" \
        -e "s/__PACKAGE__/$DUMMY_PACKAGE/g" \
        -e "s|__NAMESPACE_ESCAPED__|$DUMMY_NAMESPACE_ESCAPED|g" \
        -e "s|__NAMESPACE__|$DUMMY_NAMESPACE|g" \
        -e "s/__AUTHOR_NAME__/$DUMMY_AUTHOR_NAME/g" \
        -e "s/__AUTHOR_EMAIL__/$DUMMY_AUTHOR_EMAIL/g" \
        -e "s/__PHP_VERSION__/$DUMMY_PHP_VERSION/g" \
        -e "s/__LARAVEL_VERSIONS__/$DUMMY_LARAVEL_VERSIONS/g" \
        -e "s/__PHP_VERSION_NEON__/$DUMMY_PHP_VERSION_NEON/g" \
        -e "s/__DESCRIPTION__/$DUMMY_DESCRIPTION/g"
}

echo "[check-stub-composer-validity] validating each stub composer.json..."

for stub_dir in stubs/laravel-package stubs/laravel-package-spatie stubs/php-package stubs/phpstan-extension stubs/rector-extension stubs/filament-plugin stubs/nova-tool stubs/composer-plugin; do
    stub_json="$stub_dir/composer.json"

    if [[ ! -f "$stub_json" ]]; then
        echo "FAIL: stub composer.json missing: $stub_json"
        EXIT_CODE=1
        continue
    fi

    # Substitute placeholders + write to tmp.
    substituted="$TMP/$(basename "$stub_dir")-composer.json"
    substitute < "$stub_json" > "$substituted"

    # Validate without checking publish/version constraints (the dummy values
    # would fail those). Just confirms the JSON is structurally valid + the
    # composer.json schema is well-formed.
    if composer validate --no-check-publish --no-check-version --no-check-lock --strict "$substituted" 2>&1 | grep -E "(FAIL|error|invalid|expected)" >/dev/null; then
        echo "FAIL: $stub_json validation errors:"
        composer validate --no-check-publish --no-check-version --no-check-lock --strict "$substituted" 2>&1 | head -10 | sed 's/^/    /'
        EXIT_CODE=1
    else
        echo "  ✓ $stub_json"
    fi
done

if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "[check-stub-composer-validity] OK — all stub composer.json files validate after placeholder substitution."
fi

exit "$EXIT_CODE"
