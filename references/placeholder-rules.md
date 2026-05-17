# Placeholder rules

Exact derivation rules for the placeholders used in `stubs/`. No agent guessing.

## Placeholders

| Placeholder | Derived from | Example: input `sandermuller/queue-insights` |
|---|---|---|
| `__VENDOR__` | composer name, part before `/` | `sandermuller` |
| `__PACKAGE__` | composer name, part after `/` | `queue-insights` |
| `__VENDOR_STUDLY__` | StudlyCase of `__VENDOR__` | `SanderMuller` |
| `__PACKAGE_STUDLY__` | StudlyCase of `__PACKAGE__` | `QueueInsights` |
| `__NAMESPACE__` | `{__VENDOR_STUDLY__}\\{__PACKAGE_STUDLY__}` | `SanderMuller\\QueueInsights` |
| `__NAMESPACE_ESCAPED__` | `__NAMESPACE__` with `\\` doubled for JSON | `SanderMuller\\\\QueueInsights` |
| `__DESCRIPTION__` | user input | (free text) |
| `__AUTHOR_NAME__` | `git config user.name` fallback to user input | `Sander Muller` |
| `__AUTHOR_EMAIL__` | `git config user.email` fallback to user input | `sander@hihaho.com` |
| `__PHP_VERSION__` | `^{8.3\|8.4\|8.5}` per `--php=` | `^8.3` |
| `__LARAVEL_VERSIONS__` | per `--laravel=` (laravel-package only) | `^11.0\|\|^12.0\|\|^13.0` |
| `__PHP_VERSION_NEON__` | bare `{8.3\|8.4\|8.5}` for rector PHP set name | `83` (used as `php83` in `withPhpSets`) |
| `__YEAR__` | current year, four digits | `2026` |

## StudlyCase rule

Algorithm:

1. Split the input on `-` and `_`.
2. Lowercase each part.
3. Uppercase the first letter of each part.
4. Concatenate.

Examples:

| Input | StudlyCase |
|---|---|
| `queue-insights` | `QueueInsights` |
| `laravel_js_store` | `LaravelJsStore` |
| `sandermuller` | `Sandermuller` |
| `SanderMuller` | `Sandermuller` (lowercase-then-uppercase normalises) |
| `php-x402` | `PhpX402` |
| `x402` | `X402` |

## Edge cases

### Vendor with no hyphens / underscores

`sandermuller` → StudlyCase: `Sandermuller`. This is intentional — matches the composer-name → namespace convention. If the user wants `SanderMuller` (camel-cased vendor), they should set the composer name accordingly: `sandermuller/x` will namespace as `Sandermuller\X` after StudlyCase normalisation.

**Special-case override**: The repo-init phase asks the user once at bootstrap time to confirm the namespace. The user can override (e.g. accept `SanderMuller\\QueueInsights` instead of `Sandermuller\\QueueInsights`). The override is recorded in conversation and applied to all stubs.

The override is necessary because canonical sander packages use `SanderMuller\` (not `Sandermuller\`) as the namespace prefix. The composer-name convention is all-lowercase, but the namespace convention is StudlyCase-with-camel-on-vendor.

### Digits in vendor or package

`php-x402` → `PhpX402` (digits treated as their own segment with no case change).

`hihaho2` → `Hihaho2` (digit at end stays put).

### All-caps input

`HiHaHo` → `Hihaho` after lowercase-then-uppercase. Surprising but consistent. The override-on-confirmation step catches this.

### Mixed separators

`my-package_name` → split on both `-` and `_` → `My`, `Package`, `Name` → `MyPackageName`.

## File-path placeholders

Stub file paths use the same placeholders. Examples:

| Stub path | Filled (input `sandermuller/queue-insights`) |
|---|---|
| `src/__PACKAGE_STUDLY__ServiceProvider.php` | `src/QueueInsightsServiceProvider.php` |
| `src/__PACKAGE_STUDLY__.php` | `src/QueueInsights.php` |
| `config/__PACKAGE__.php` | `config/queue-insights.php` |

The agent renames the file as part of the copy step (it's not just a content substitution).

## Inside file contents

Same placeholders substituted in file contents. JSON files use `__NAMESPACE_ESCAPED__` (with `\\\\`) because JSON-encoded namespaces need escaped backslashes. PHP files use `__NAMESPACE__` (with `\\`) which is the PHP source-form.

## When the agent must ask

Always confirm with the user:

1. The derived namespace at first stub-copy (single confirmation, not per stub).
2. The author email if `git config user.email` is empty.

Never confirm:

- Each stub's filled-in content.
- The vendor StudlyCase (it's deterministic; the override is namespace-only).
