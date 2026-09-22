---
paths:
  - 'resources/views/**/*.blade.php'
---

# Views

## Use @php blocks, never the inline @php(...) directive

Write Blade PHP as a multi-line `@php ... @endphp` block (statements end with `;`), never the single-line `@php($x = ...)` directive. Grouped blocks read better and the team standardized on them. Enforced by `tests/Unit/Blade/InlinePhpDirectiveTest.php`, which fails on any `@php(` or `@php (` in `resources/views`.
