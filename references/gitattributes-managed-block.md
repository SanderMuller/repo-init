# `.gitattributes` managed-block contract

repo-init writes its `export-ignore` entries INSIDE `sandermuller/package-boost-php`'s existing managed block, NOT in a separate block. (The sentinel name is `# >>> package-boost (managed) >>>` for historical backward compatibility — every existing repo has this exact sentinel, so the naming convention is locked. The OWNING package is now `package-boost-php`, which uses boost-core's `GitattributesManager` to write the block.)

## What package-boost-php writes

`vendor/bin/boost sync` (via boost-core, pulled in transitively by package-boost-php) maintains a block in the target's `.gitattributes`:

```
# >>> package-boost (managed) >>>
.agents/                export-ignore
.ai/                    export-ignore
.claude/                export-ignore
.cursor/                export-ignore
.cursorrules            export-ignore
.github/                export-ignore
.junie/                 export-ignore
.kiro/                  export-ignore
.windsurfrules          export-ignore
AGENTS.md               export-ignore
CLAUDE.md               export-ignore
GEMINI.md               export-ignore
# <<< package-boost (managed) <<<
```

## What repo-init adds

Inside the same block, repo-init appends:

```
.cache/                 export-ignore
.editorconfig           export-ignore
.gitattributes          export-ignore
.gitignore              export-ignore
.mcp.json               export-ignore
.phpunit.cache          export-ignore
boost.php               export-ignore
composer.lock           export-ignore
CHANGELOG.md            export-ignore
phpstan-baseline.neon   export-ignore
phpstan.neon.dist       export-ignore
phpunit.xml             export-ignore
phpunit.xml        export-ignore
pint.json               export-ignore
rector.php              export-ignore
testbench.yaml          export-ignore
tests/                  export-ignore
workbench/              export-ignore
```

Plus per-category extras:

- `php-package`: also `.lpv`, `PUBLIC_API.md`
- `phpstan-extension`: also `extension.neon`
- `rector-extension`: also `config/` (the extension's own rector config dir — careful, this is a real published path; only the test-fixture `config/` is `export-ignore`d when applicable)

## `.lpv` file format (NOT `.gitattributes` syntax)

`.lpv` is lean-package-validator's glob-pattern file (`php-package` and `skill-bundle` ship one). It does **not** use `.gitattributes` syntax. Each line is a **bare glob pattern** — one artifact per line, with **no `export-ignore` suffix**:

```text
.editorconfig
.github/
CHANGELOG.md
pint.json
```

The validator joins the lines into a single brace glob (`{.editorconfig,.github/,CHANGELOG.md,pint.json}*`) and checks that everything matching it is `export-ignore`d in `.gitattributes`. A line written in `.gitattributes` form (`pint.json export-ignore`) becomes the literal glob `pint.json export-ignore` — with the space — which matches no file, so the expected-export-ignore set collapses to empty and `validate` **passes vacuously**, silently defeating its own purpose. When the validator warns about a missing artifact: add the `<path> export-ignore` line to the `.gitattributes` managed block AND the **bare `<path>`** (no suffix) to `.lpv`.

## Contract with package-boost

For repo-init to append into package-boost's block, package-boost must preserve foreign lines during its sync. The contract:

1. package-boost's sync command walks the existing block, identifies its own lines (by exact match against its declared list), and leaves all other lines in place.
2. repo-init's append is line-based with dedup (don't insert the same line twice).
3. If a third tool later wants to manage `.gitattributes`, it follows the same contract — append inside the block, dedupe by line text.

**This contract requires a one-time update to package-boost** (~30 LOC) to add the "preserve foreign lines" behaviour. As of this writing (May 2026) this update is open work. Open Question #2 in the SPEC tracks it.

## Fallback if package-boost doesn't accept the contract

repo-init writes its own block:

```
# >>> repo-init (managed) >>>
.cache/                 export-ignore
...
# <<< repo-init (managed) <<<
```

Two managed blocks coexist in `.gitattributes`. Audit reports the two-blocks state as `NON-CANONICAL` so it's visible but not blocked. This fallback is documented but not preferred.

## Audit detection

- `replace` mode? No — `.gitattributes` is `managed-block` mode (see `upgrade-merge-modes.md`).
- Audit diffs only inside the package-boost block; outside the block is user-owned, not flagged.
- Audit flags MISSING per repo-init line not present inside the block.
- Audit flags `NON-CANONICAL` if a separate `# >>> repo-init (managed) >>>` block exists alongside the package-boost block.

## Outside the managed block

Lines outside the managed block are user-owned: per-language attributes (`*.php text=auto eol=lf`, `*.css diff=css`), git-LFS pointers, etc. Never touched by repo-init.
