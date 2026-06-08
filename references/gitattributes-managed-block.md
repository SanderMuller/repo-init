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
.config/                export-ignore
.editorconfig           export-ignore
.gitattributes          export-ignore
.gitignore              export-ignore
.mcp.json               export-ignore
.phpunit.cache          export-ignore
composer.lock           export-ignore
CHANGELOG.md            export-ignore
phpstan-baseline.neon   export-ignore
phpstan.neon.dist       export-ignore
phpunit.xml             export-ignore
pint.json               export-ignore
rector.php              export-ignore
tests/                  export-ignore
```

This universal set is seeded in `stubs/shared/_gitattributes` and shipped by every
category. `.config/` (whole-dir) replaced the old `boost.php` entry: it excludes both
the canonical config `.config/boost.php` AND the gitignored sync-manifest dir
`.config/boost/` (boost-core ≥ 0.17/0.18 layout) in one line. `.config/` is not part of
package-boost-php's canonical `ManagedBlockWriter` set, so it is preserved as a *foreign*
line inside the block on every `boost sync` — repo-init seeds it, the writer keeps it.

> **Anchoring exception — `.config/` in repo-init's OWN `.gitattributes`.** In a
> *generated package* (and in the stub `_gitattributes`) the entry is the UNANCHORED
> `.config/ export-ignore` shown above — correct, because that file becomes the target's
> own repo-root `.gitattributes`. But repo-init's OWN `.gitattributes` MUST use the
> leading-slash form `/.config/ export-ignore`. repo-init ships `stubs/shared/.config/boost.php`,
> so an unanchored `.config/` would match `stubs/**/.config/` too and exclude the stub
> from repo-init's *own* published archive — silently breaking scaffolding. The leading
> slash root-anchors the match. A maintenance pass that "normalizes" repo-init's self-file
> down to the stub form would reintroduce that packaging bug — keep it anchored.

Two entries are **laravel-only** — added by the laravel categories'
own `_gitattributes` (`laravel-package`, `laravel-package-spatie`, `filament-plugin`,
`nova-tool`), NOT by the framework-agnostic shared block:

```
testbench.yaml          export-ignore
workbench/              export-ignore
```

Plus per-category extras:

- `php-package`, `composer-plugin`, `skill-bundle`: also `.lpv` (the
  lean-package-validator glob file — see "`.lpv` file format" below). `php-package`
  additionally ships `PUBLIC_API.md`.
- `phpstan-extension`: also `extension.neon`
- `rector-extension`: also `config/` (the extension's own rector config dir — careful, this is a real published path; only the test-fixture `config/` is `export-ignore`d when applicable)

## `.lpv` file format (NOT `.gitattributes` syntax)

`.lpv` is lean-package-validator's glob-pattern file (`php-package`, `composer-plugin`, and `skill-bundle` ship one). It does **not** use `.gitattributes` syntax. Each line is a **bare glob pattern** — one artifact per line, with **no `export-ignore` suffix**:

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

**Status:** the foreign-line-preservation behaviour is implemented in `sandermuller/package-boost-php`'s `ManagedBlockWriter` (the owner of the block) and covered by end-to-end command tests.

### Convergence and idempotency (package-boost-php ≥ 0.16.2)

The package-boost gitattributes writer is **convergent** and **idempotent**:

- **Convergent (single-pass):** one run of the gitattributes command produces the canonical managed block from ANY input — including a malformed block (open marker, no close), stray duplicate markers, or mixed line endings. The self-heal happens in that single run; an audit does NOT need to run it twice to converge.
- **Idempotent (strict):** `sync(sync(x))` equals `sync(x)` byte-for-byte for any input. Re-running on an already-synced file is a no-op, so `--check` exits 0.
- **Preservation (the repo-init contract):** foreign lines inside the block — anything that isn't a canonical package-boost entry, i.e. repo-init's appends — survive, rendered AFTER the canonical lines; exact duplicates are collapsed (first occurrence kept, first-seen order). Stray block markers captured inside a malformed region are dropped (not preserved as foreign). Content outside the block (before the first START / after the last END) is untouched.
- **Matching:** canonical lines are matched on their whitespace-normalized form, so a differently-padded variant of a managed rule is recognized as package-boost's own and not re-emitted as a foreign duplicate. The file's dominant line ending (LF/CRLF) is preserved.

These guarantees land in `package-boost-php` 0.16.2. repo-init's scaffold floor is `^1.0`, so a freshly scaffolded repo resolves to the newest (≥ 0.16.2) and gets them; an older audited repo on 0.16.0/0.16.1 still has the pre-self-heal behaviour. The audit's managed-block check is therefore **version-agnostic** — it verifies the block is correct (canonical set present + foreign lines preserved) and never relies on single-pass convergence as a precondition. Convergence/idempotency is a documented property of the writer ≥ 0.16.2, not an audit assumption.

## Fallback if package-boost doesn't accept the contract

repo-init writes its own block:

```
# >>> repo-init (managed) >>>
.cache/                 export-ignore
...
# <<< repo-init (managed) <<<
```

Two managed blocks coexist in `.gitattributes`. Audit reports the two-blocks state as `NON-CANONICAL` so it's visible but not blocked. This fallback is documented but not preferred.

**Superseded:** package-boost now implements the foreign-line-preservation contract (see above), so the single-block path is always available and the fallback is no longer needed for new work. The two-block NON-CANONICAL detection below stays valid for legacy repos that already have a separate `# >>> repo-init (managed) >>>` block — the fix is to fold those lines into the package-boost block and remove the second block.

## Audit detection

- `replace` mode? No — `.gitattributes` is `managed-block` mode (see `upgrade-merge-modes.md`).
- Audit diffs only inside the package-boost block; outside the block is user-owned, not flagged.
- Audit flags MISSING per repo-init line not present inside the block.
- Audit flags `NON-CANONICAL` if a separate `# >>> repo-init (managed) >>>` block exists alongside the package-boost block.

## Outside the managed block

Lines outside the managed block are user-owned: per-language attributes (`*.php text=auto eol=lf`, `*.css diff=css`), git-LFS pointers, etc. Never touched by repo-init.
