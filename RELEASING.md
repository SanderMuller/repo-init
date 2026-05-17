# Releasing

How to cut a release of `sandermuller/repo-init`.

## Pre-release checklist

- [ ] All integrity CI checks green on `main`.
- [ ] CHANGELOG.md `[Unreleased]` section has entries; move them to a new versioned section.
- [ ] `UPGRADING.md` has a section for this version if there are breaking changes.
- [ ] If `sandermuller/package-boost` was bumped to a new MINOR/MAJOR: verify the `--scope=user` sync contract still holds; smoke-test by `composer global update sandermuller/repo-init` and checking `~/.claude/skills/repo-init/SKILL.md` is up-to-date.
- [ ] Stub drift CI is clean (no untracked drift against canonical refs).

## Versioning rules

- **Pre-1.0**: MINOR bumps may break — document in UPGRADING.md. PATCH bumps are non-breaking.
- **Post-1.0** (future): standard SemVer. MAJOR for breaking, MINOR for additive, PATCH for fixes.

What counts as breaking for repo-init:

- Stub content change that requires consumers to re-run audit + upgrade (most stub edits are MINOR-breaking pre-1.0).
- Phase file step ordering change that an in-flight agent might trip on.
- Reference doc rename / removal.
- `references/per-category-deps.yml` schema change.
- Adding a new category (additive, MINOR).
- Removing a category (MAJOR).

## Release steps

1. **Update CHANGELOG.md** — move `[Unreleased]` entries to a new `[X.Y.Z] - YYYY-MM-DD` section. Update the link references at the bottom.
2. **Commit** the CHANGELOG bump:

   ```bash
   git commit -am "Release X.Y.Z"
   ```

3. **Tag**:

   ```bash
   git tag -s X.Y.Z -m "Release X.Y.Z"
   # or unsigned:
   git tag X.Y.Z
   ```

4. **Push tag**:

   ```bash
   git push origin main --tags
   ```

5. **Verify Packagist auto-publish** — the Packagist webhook fires on tag push; check <https://packagist.org/packages/sandermuller/repo-init> for the new version.
6. **Verify the install path** by running on a fresh machine (or VM / container):

   ```bash
   composer global require sandermuller/repo-init:X.Y.Z
   ls -la ~/.claude/skills/repo-init/SKILL.md
   ```

7. **GitHub release**:

   ```bash
   gh release create X.Y.Z --generate-notes
   ```

   The `update-changelog.yml` workflow will pick up the release body and update CHANGELOG.md if needed.

## Hot-fix path

If a release breaks the install (e.g. `composer global require` errors out):

1. Yank from Packagist (<https://packagist.org/packages/sandermuller/repo-init> → Settings → mark version as abandoned, or contact packagist support).
2. Cut a `.PATCH+1` with the fix.
3. Document the yank in CHANGELOG with a `[YANKED]` marker.

## Coordinated bump with `sandermuller/package-boost`

If the release depends on a new package-boost feature (e.g. the v0.1.0 dependency on `--scope=user` sync):

1. Ship the package-boost feature first.
2. Tag package-boost with the new MINOR.
3. Update repo-init's `composer.json` `require: sandermuller/package-boost` constraint to require the new MINOR.
4. Commit, tag repo-init.
5. Verify both install cleanly together: `composer global require sandermuller/repo-init` should pull the right package-boost version.

## Post-release

- [ ] Smoke-test on a fresh machine.
- [ ] Add a tweet / announcement (optional).
- [ ] Open a follow-up issue if any post-release feedback comes in.
