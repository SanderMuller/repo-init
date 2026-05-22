# Contributing

`sandermuller/repo-init` is a markdown-only package. The contribution surface is therefore writing markdown and YAML stubs, not PHP. If you write PHP source under `src/` you're doing it wrong — this project is intentionally code-free.

## Quick-start

```bash
git clone https://github.com/sandermuller/repo-init.git
cd repo-init
```

That's it. No `composer install` needed for development unless you're running the CI scripts locally:

```bash
composer install   # only needed for orchestra/testbench + package-boost (used by stub-drift CI script)
```

## What to change

| Want to | Change |
|---|---|
| Add a new repo category (e.g. `filament-plugin`) | `references/detection-rules.md` + `references/per-category-deps.md` + `references/per-category-deps.yml` + new `stubs/<cat>/` tree + 3 new phase files (`bootstrap-<cat>.md`, `audit-<cat>.md`, `upgrade-<cat>.md`) + update `SKILL.md` routing table. See SPEC.md §2 and §10 (Phase 8). |
| Adjust the canonical baseline (add a shared dev dep, change a script) | `references/shared-dev-deps.md` + `references/per-category-deps.yml` + `references/composer-scripts.md` + corresponding edits across all affected `stubs/<cat>/composer.json` files. |
| Add a placeholder | `references/placeholder-rules.md` + use it in at least one stub. The Phase 7 `check-placeholders` CI enforces both directions. |
| Add an opt-in to an existing category | `references/per-category-deps.md` MANDATORY vs OPTIONAL split + `references/per-category-deps.yml` + corresponding audit + upgrade phase changes. |
| Update SPEC | `SPEC.md`. Add a new Resolved Question explaining the decision + rationale. Open a PR with rationale in the description. |

## Style

- **Markdown**: GitHub-flavoured. Tables for any per-category / per-mode matrix. Code fences with language hints. No raw HTML.
- **Stub `.json` files**: 4-space indent, trailing newline.
- **Stub `.neon`/`.yaml` files**: 4-space indent.
- **Stub `.php` files**: pint-friendly (the canonical reference repos' style — `declare(strict_types=1);`, `final class`, etc.).
- **Phase files**: each step numbered and self-contained. Each ends with a "What's next" prompt that routes the agent to the next logical phase OR stops cleanly.

## Linting

```bash
# Run all integrity checks locally:
bash .github/scripts/check-paths.sh
bash .github/scripts/check-phase-coverage.sh
python3 .github/scripts/check-dep-sync.py
bash .github/scripts/check-placeholders.sh
bash .github/scripts/check-merge-keys-coverage.sh
bash .github/scripts/check-layout.sh
```

CI runs all of the above on every push + PR.

## Stub drift detection

A weekly GitHub Actions job (`.github/workflows/stub-drift.yml`) fetches each canonical reference repo's relevant files and diffs them against `stubs/`. If drift exceeds a per-file threshold, the workflow opens an issue with a suggested patch.

When the canonical reference moves intentionally (e.g. queue-insights bumps a dep version), update the matching stub in this repo.

## Adding a new canonical reference

If you add a new category in Phase 8, add the matching canonical reference repo to:

- `references/canonical-repos.md`
- `.github/workflows/stub-drift.yml` (add to the matrix)

## PRs

- One concern per PR. New category → one PR. Stub drift sync → separate PR per category. Spec rewrite → separate PR.
- Don't edit `CHANGELOG.md` — it is generated from the GitHub release body by `.github/workflows/update-changelog.yml` on each release.
- Tag a reviewer (`@sandermuller`) when ready.

## Versioning

Semantic versioning, pre-1.0 cadence. MINOR bumps may break compatibility — document in `UPGRADING.md`.
