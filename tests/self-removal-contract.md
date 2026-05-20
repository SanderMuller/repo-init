# Self-removal contract

Documents the survives-vs-clean tradeoff when removing `sandermuller/repo-init` from a target environment, plus the load-bearing contract with `sandermuller/package-boost` that makes the "survives" case work.

This file isn't a runtime artifact — it's a design document for contributors. The matching logic lives in `checklists/self-removal.md`.

## The contract (one line)

> When `package-boost:sync` copies `.ai/skills/<package>/SKILL.md` from `vendor/<package>/.ai/skills/` to `~/.claude/skills/<package>/SKILL.md` (user-scope) or `<target>/.claude/skills/<package>/SKILL.md` (project-scope), it **copies** the file. It does **not** symlink.

This is the property that makes "you can `composer global remove sandermuller/repo-init` and still keep the skill" work.

## Why this matters

In v7's global-install model:

1. User runs `composer global require sandermuller/repo-init`.
2. `post-install-cmd` fires `vendor/bin/boost sync --scope=user`.
3. package-boost reads `vendor/sandermuller/repo-init/.ai/skills/repo-init/SKILL.md` from the global vendor dir.
4. package-boost **copies** the file to `~/.claude/skills/sandermuller__repo-init/SKILL.md`.
5. From any future Claude Code session in any project, the skill auto-activates.

If `composer global remove sandermuller/repo-init` happens later:

- `vendor/sandermuller/repo-init/` is deleted.
- BUT `~/.claude/skills/sandermuller__repo-init/SKILL.md` remains (copy, not symlink).
- The skill is still activatable. When invoked, its pre-flight detects the missing `vendor/` and prompts the user to re-install.

If package-boost used symlinks instead, the second-to-last bullet would break — removing the global package would break the user-scope skill.

## Verifying the contract

```bash
# Install
composer global require sandermuller/repo-init

# Confirm it's a copy, not a symlink:
ls -la ~/.claude/skills/sandermuller__repo-init/SKILL.md
# Expected: regular file (no `->` arrow indicating a symlink target).

# Compute hashes — should be identical right after install:
# (sha256sum on Linux; on macOS use `shasum -a 256` instead.)
sha256sum "$(composer global config home)/vendor/sandermuller/repo-init/resources/boost/skills/repo-init/SKILL.md"
sha256sum ~/.claude/skills/sandermuller__repo-init/SKILL.md

# Now remove:
composer global remove sandermuller/repo-init

# Confirm user-scope skill survives:
ls -la ~/.claude/skills/sandermuller__repo-init/SKILL.md
# Expected: still present, still a regular file with the previous hash.
```

If the second `ls` shows the file is gone or the symlink target is broken, the contract is violated — file an issue against `sandermuller/package-boost`.

## What happens if the contract breaks

If package-boost shifts to symlinks (intentionally or accidentally), repo-init's user-scope skill becomes a dangling reference after `composer global remove`. The fix per `checklists/self-removal.md`:

1. Detect the broken symlink: `readlink ~/.claude/skills/sandermuller__repo-init/SKILL.md` returns a path that doesn't exist.
2. User must either:
   - Re-install: `composer global require sandermuller/repo-init`. Skill works again.
   - Manually clean: `rm ~/.claude/skills/sandermuller__repo-init/SKILL.md`. Skill won't auto-activate next session.

We surface this in `checklists/self-removal.md` "Optional skill cleanup" as a forward guard.

## Alternative: explicit user-scope persistence

If we wanted to make the survives-vs-clean tradeoff EXPLICITLY user-controlled (rather than implicit-via-package-boost-behavior), the design would change:

- Add a flag at install time: `composer global require sandermuller/repo-init --no-persist-skill` would skip the user-scope sync.
- Add an explicit "persist skill on uninstall" step in `composer global remove sandermuller/repo-init`. (Composer doesn't directly support pre-uninstall hooks for global packages — would need a wrapper script.)

Both options add UX complexity for a property that's already free in the current package-boost-copies-not-symlinks model. We defer them to v0.2+ if user feedback indicates the implicit behavior is surprising.

## Test in CI

Phase 7's integrity workflow does NOT test this contract at the runtime level (it would require installing repo-init globally on the CI runner, which is destructive). Instead:

- `.github/workflows/integrity.yml` validates the spec + stub layout.
- This file (`tests/self-removal-contract.md`) serves as the design assertion.
- Manual verification at release time, per `RELEASING.md` step 6 ("Verify install path by running on a fresh machine").

## Related

- `checklists/self-removal.md` — the user-facing flow.
- `references/gitattributes-managed-block.md` — a parallel contract with package-boost (preserving foreign entries inside its managed block).
- SPEC.md §10 + RQ40 — the global-install architecture decision.
