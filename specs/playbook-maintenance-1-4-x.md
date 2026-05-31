# Playbook Maintenance Cycle (post-1.4.0)

## Overview

A periodic maintenance pass over the repo-init playbook (pure-markdown Composer
package — no PHP `src/`; the "code" is `phases/`, `references/`, `stubs/`,
`checklists/`). It fixes shipped-stub defects, reconciles source-of-truth
references, and closes cross-category structural drift surfaced while evaluating
the 1.4.0 façade work. The `.lpv` glob-format fix (already committed on this
branch, `f6c7dcd`) is the first item of this cycle and ships in the same release.

Scope was set by a four-agent discovery sweep + manual verification. Findings the
sweep raised but that verification dismissed are recorded under Findings, not
implemented.

---

## 1. Current State

The 1.4.0 one-package-install façade shipped correctly (verified: all stub
callbacks/floors family-correct, audit/upgrade phases enforce the right canonical,
atomic floor-coupling present on both write paths). This cycle does **not** revisit
that — it addresses adjacent defects:

- **Shipped-stub gap — composer-plugin `.lpv`.** `stubs/composer-plugin/` ships
  `validate-gitattributes` (in `qa`/`qa-check`) but no `.lpv`. `php-package` ships
  one precisely so the validator checks project-specific artifacts (`boost.php`,
  `.ai/`, `.claude/`, `.cache/`) that lean-package-validator's default preset
  doesn't know about. Without it, composer-plugin's `validate-gitattributes` runs
  against the default preset and under-validates. (Verified.)
- **`.lpv` CONTENT drift (Codex F1, verified).** The defect class is not just
  presence/format — it's content parity. `stubs/php-package/.lpv` lists
  `CHANGELOG.md` and `workbench/`, but the `_gitattributes` managed block a
  php-package ships (from `stubs/shared/_gitattributes`) does NOT export-ignore
  either. A fresh php-package's `validate-gitattributes` would flag both as
  missing. `workbench/` is laravel-only (php-package never ships it); `CHANGELOG.md`
  is a canonical-decision item. Modeling composer-plugin on the un-reconciled
  php-package `.lpv` would propagate the mismatch. The `.lpv` for every category
  that ships one must agree with the `_gitattributes` it actually ships.
- **Missing composer-plugin `run-tests.yml` stub (Codex F2, verified).**
  `run-tests.yml` is category-specific — every code-bearing category ships its own
  at `stubs/<cat>/.github/workflows/run-tests.yml` EXCEPT composer-plugin.
  `bootstrap-composer-plugin.md:65` (skip-condition) and `audit-composer-plugin.md:35`
  ("4 shared workflows + `run-tests.yml`") both expect it, so a scaffolded
  composer-plugin lands without CI test execution and its own audit flags it
  MISSING with no stub to copy from. (skill-bundle correctly excludes it — no PHP,
  bootstrap/audit explicitly skip it.)
- **Reference integrity.** `references/gitattributes-managed-block.md` has a
  literal duplicate `phpunit.xml export-ignore` line in its append code-block, its
  per-category `.lpv` extras list (line ~53) names only `php-package`, and its
  "repo-init appends" block lists entries (`.phpunit.cache`, `CHANGELOG.md`) that
  don't match the actual `stubs/shared/_gitattributes` managed block while omitting
  the agent-dir entries the stub does carry.
- **Cross-category drift.** rector-extension doesn't force `phpunit` though its
  rule tests use `RectorTestCase` (PHPUnit-based, exactly like phpstan-extension's
  `RuleTestCase`, which *is* forced); `audit-skill-bundle.md` lacks the structured
  "## MISSING composer.json scripts" section its six siblings have; several audit
  parallelism gaps (phpunit.xml.dist check, run-tests path-filter check, README
  badge check) exist between categories that should share them.
- **Docs.** No `UPGRADING.md` entry for the 1.4.0 façade migration; the
  allow-plugins `≥0.9.0` removal logic reads as stale now that floors are
  `^0.16.0`/`^0.10.0`.

## 2. Proposed Changes

Grouped into four phases by severity. Each task cites the target file. Because the
repo has no test suite, "Tests" entries are concrete **verification commands**
(lean-package-validator, markdownlint, layout-integrity, consistency greps).

## Edge Cases

| Scenario | Handling |
|----------|----------|
| New `composer-plugin/.lpv` lists a path composer-plugin doesn't ship (e.g. `workbench/`) | Harmless — lean-package-validator simply doesn't match it. Curate to composer-plugin's combined shared+own set; don't blindly copy php-package's. Covered by Phase 1 verification (run the validator). |
| `.lpv` re-introduces the `export-ignore` suffix during a future upgrade | Prevented by the format definition added to `gitattributes-managed-block.md` + corrected upgrade-phase prose (already done in `f6c7dcd`). Phase 1 adds composer-plugin to that prose where relevant. |
| Forcing `phpunit` for rector-extension breaks the hihaho path | hihaho already defaults to `phpunit` — only the sander default (`pest`) changes. Preserve the explicit-override escape hatch exactly as phpstan-extension documents it. |
| Reference append-list reconciliation drops an entry the stub actually needs | `stubs/shared/_gitattributes` is authoritative (it's what ships). Reconcile the reference TO the stub, not vice-versa; never remove a live stub entry. Phase 2 verification diffs the two. |
| skill-bundle structured-scripts section drifts from its lean canonical | skill-bundle's canonical set is `format`, `validate-gitattributes`, `qa`, `qa-check`, `post-install-cmd`, `post-update-cmd` (NOT the baseline 11). Mirror `references/composer-scripts.md#skill-bundle` exactly. |
| A parallelism check is added to a category it doesn't apply to | Each added check must be gated on the category actually shipping the artifact (e.g. run-tests path-filter only where `run-tests.yml` + the referenced paths exist). Verify per category before adding. |

## Implementation

### Phase 1: Shipped-stub correctness (Priority: HIGH)

- [ ] **Add `stubs/composer-plugin/.github/workflows/run-tests.yml`** (Codex F2) —
      model on `stubs/php-package/.github/workflows/run-tests.yml` (framework-agnostic,
      PHP-only matrix, no Laravel axis). Verify `bootstrap-composer-plugin.md` has a
      step that copies it (add one if the category-stub copy doesn't cover the new
      `.github/workflows/` path); confirm audit-composer-plugin's "+ run-tests.yml"
      expectation is now satisfiable.
- [ ] **Reconcile `.lpv` CONTENT for all categories that ship one** (Codex F1) —
      for `php-package` and `skill-bundle`, diff each `.lpv` against the
      `_gitattributes` managed block that category actually ships; remove entries the
      block doesn't export-ignore (`workbench/` from php-package — never shipped;
      `CHANGELOG.md` per Open Question 2) so a fresh scaffold's `validate-gitattributes`
      passes. This is the canonical `.lpv` content.
- [ ] **Add `stubs/composer-plugin/.lpv`** built from the RECONCILED canonical (not
      copied from the un-reconciled php-package `.lpv`), bare-glob format, curated to
      composer-plugin's shipped set (shared dev files + its own; drop `PUBLIC_API.md`
      and any path it doesn't ship).
- [ ] Confirm `stubs/php-package/.lpv` + `stubs/skill-bundle/.lpv` are bare-glob
      format (done in `f6c7dcd`) AND now content-reconciled.
- [ ] Tests — for each `.lpv`, run `vendor/bin/lean-package-validator validate`
      against a fixture whose `.gitattributes` carries the category's managed block,
      and confirm `valid: true` (content parity); confirm all `.lpv` parse to proper
      `<path> export-ignore` globs (not space-literals); confirm composer-plugin
      scaffolds with a `run-tests.yml`.

### Phase 2: Source-of-truth reference integrity (Priority: MEDIUM)

- [ ] Remove the duplicate `phpunit.xml export-ignore` line from the append
      code-block in `references/gitattributes-managed-block.md` (keep one, aligned
      spacing).
- [ ] Update the per-category `.lpv` extras list (`gitattributes-managed-block.md`
      ~line 53): `php-package` → `php-package`, `composer-plugin`, `skill-bundle`
      (all three that ship a `.lpv`).
- [ ] Reconcile the "repo-init appends" block to the authoritative
      `stubs/shared/_gitattributes` managed block: verify whether `.phpunit.cache`
      and `CHANGELOG.md` are actually appended (add to the stub or drop from the
      reference), and make clear which entries are package-boost-owned (agent dirs,
      `AGENTS.md`/`CLAUDE.md`/`GEMINI.md`) vs repo-init appends vs per-category
      (laravel-only `testbench.yaml`/`workbench/`).
- [ ] Tests — `diff` the reference's documented entries against
      `stubs/shared/_gitattributes`; markdownlint the reference; confirm no entry
      present in the live stub was dropped.

### Phase 3: Cross-category parallelism (Priority: MEDIUM)

- [ ] ~~rector-extension force phpunit~~ — DROPPED per Resolved Question 1 (either
      runner is fine; no change).
- [ ] Add a structured "## MISSING composer.json scripts" section to
      `audit-skill-bundle.md` mirroring `references/composer-scripts.md#skill-bundle`
      (lean key set: `format`, `validate-gitattributes`, `qa`, `qa-check`,
      `post-install-cmd`, `post-update-cmd`) — keep the existing NON-CANONICAL prose
      checks.
- [ ] Add the `phpunit.xml.dist` NON-CANONICAL check to `audit-composer-plugin.md`
      (parity with php-package/rector/phpstan); leave laravel-project's inverse note
      as-is.
- [ ] Add a brief audit→upgrade pointer: in each audit's MISSING-scripts section,
      note that a `post-install-cmd`/`post-update-cmd` callback fix must bump the
      wrapper floor in the same patch (per the ATOMIC rule in the upgrade phase).
- [ ] Evaluate the run-tests.yml path-filter drift check for rector/phpstan-extension
      audits — add only if those categories ship `run-tests.yml` with the referenced
      paths (verify first; don't add a check that can't apply).
- [ ] Tests — markdownlint all changed phase files; grep to confirm the
      skill-bundle scripts section matches the reference's key set; layout-integrity
      check stays green.

### Phase 4: Documentation & low-priority polish (Priority: LOW)

- [ ] Add an `UPGRADING.md` entry for the 1.4.0 façade migration (wrapper-family
      callback swap + floor bump; cross-reference the release notes). Use the
      `upgrading` skill's structure. Do NOT rewrite the historical 0.4.x→0.5.0
      entry (it's accurate for its era).
- [ ] Clarify the allow-plugins `≥0.9.0` removal logic in the upgrade phases now
      that floors are `^0.16.0`/`^0.10.0` — note it covers repos being upgraded
      from pre-0.9.0 states; new scaffolds at the current floor are already past it.
- [ ] Harmonize the README badge check across audits: add it to
      `audit-laravel-project.md` (parity) and align "MUST"/badge-list wording;
      keep skill-bundle's justified 3-badge/MEDIUM variant.
- [ ] Tests — markdownlint; confirm no contradictory canonical introduced.

---

## Open Questions

None — both resolved (see Resolved Questions).

---

## Resolved Questions

1. **rector-extension test-framework: force `phpunit` or document-and-warn?**
   **Decision:** Neither — leave as-is (pest default for sander, phpunit for hihaho).
   **Rationale:** Sander confirmed either runner is fine; `RectorTestCase` is
   PHPUnit-based but Pest runs PHPUnit `TestCase` subclasses, so the default works.
   The Phase 3 force-phpunit task is dropped; no warning added.

2. **Should `CHANGELOG.md` (and `.phpunit.cache`) be export-ignored?**
   **Decision:** Yes — export-ignore both. **Rationale:** Sander chose export-ignore
   for `CHANGELOG.md`; `.phpunit.cache` is a pure runtime cache that should never
   ship. **Reconciliation direction:** ADD `CHANGELOG.md` and `.phpunit.cache` to the
   shared `_gitattributes` managed block (option A), keeping them in `.lpv` + the
   reference so all three agree. `workbench/` is the inverse: it's laravel-only, so
   REMOVE it from `php-package/.lpv` (php-package never ships it); laravel categories
   keep it via their own `_gitattributes`.

## Findings

**Implementation status (2026-05-31, branch `fix/lpv-stub-glob-format`):**

- ✅ **Phase 1 (HIGH)** — created `stubs/composer-plugin/.github/workflows/run-tests.yml`
  and its bootstrap prose; added `CHANGELOG.md` + `.phpunit.cache` to shared
  `_gitattributes`; removed `workbench/` from `php-package/.lpv`; created
  `composer-plugin/.lpv`. All three `.lpv` validate clean against the updated block
  (empirically verified — subset `.lpv` is valid; the real bug was `CHANGELOG.md`
  un-ignored).
- ✅ **Phase 2 (MEDIUM)** — removed the duplicate `phpunit.xml` line; updated the
  `.lpv` per-category extras list (php-package + composer-plugin + skill-bundle);
  separated laravel-only `testbench.yaml`/`workbench/` from the universal append set.
  `.cursorrules`/`.windsurfrules` verified CORRECT in the reference (package-boost's
  `ManagedBlockWriter` writes them; the stub seed self-heals via `boost sync`) — no
  change.
- ✅ **Phase 3 (MEDIUM)** — added the structured "MISSING composer.json scripts"
  section to `audit-skill-bundle.md`; added the floor-coupling ATOMIC pointer to all
  5 wrapper audits; added the `phpunit.xml.dist` check to `audit-composer-plugin.md`.
  rector force-phpunit dropped per Resolved Q1.
- ✅ **Phase 4.1** — added the 1.4.0 façade entry to `UPGRADING.md`.
- ⏭️ **Deferred (LOW, not blocking)** — 3.5 run-tests path-filter parity for
  rector/phpstan audits (conditional, needs per-category applicability check); 4.2
  allow-plugins `≥0.9.0` clarity wording; 4.3 README badge-check harmonization across
  audits. Tracked here for a future pass.

**Codex review of this spec (warranted, incorporated):**

- **F1 — `.lpv` content parity.** Codex flagged that the original plan treated the
  `.lpv` defect as presence/format only; verified that `php-package/.lpv` lists
  `CHANGELOG.md`/`workbench/` absent from the shipped `_gitattributes`, so modeling
  composer-plugin on it would propagate drift. Phase 1 now reconciles `.lpv` content
  against `_gitattributes` before building composer-plugin's. Accepted.
- **F2 — missing composer-plugin `run-tests.yml`.** Codex flagged that
  bootstrap/audit-composer-plugin expect `run-tests.yml` but no stub ships it.
  Verified: every other code-bearing category ships its own; composer-plugin doesn't;
  skill-bundle correctly excludes it. Phase 1 now creates the stub. Accepted — both
  were missed by the discovery sweep (which looked at present/format, not
  missing/content).

Dismissed during evaluation (not implemented — recorded to prevent re-litigation):

- **rector/phpstan-extension needing `.lpv`** — false positive. Neither ships a
  `validate-gitattributes` script (only php-package + composer-plugin do), so
  neither needs a `.lpv`. Only composer-plugin is missing one.
- **Rewriting `UPGRADING.md:138`** — that 0.4.x→0.5.0 entry accurately describes a
  historical migration (`BoostAutoSync::run` was canonical then). The real gap is a
  *missing* 1.4.0 entry (Phase 4), not a rewrite of history.
- **"1.4.0 work is broken" claims** — the recent-changes agent confirmed all 9
  stub composer.json callbacks/floors, audit/upgrade canonical values, and the
  atomic floor-coupling are correct. No action.
- **composer-plugin plugin-shape checks / skill-bundle boost-core-in-require check
  as "drift"** — correct categorical differentiation, not drift.
