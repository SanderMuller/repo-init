# Self-removal contract

Documents what stays behind when `sandermuller/repo-init` is removed from a machine, and the property of `sandermuller/boost-core`'s user-scope sync that decides it.

This file isn't a runtime artifact — it's a design document for contributors. The matching user-facing steps live in `checklists/self-removal.md`. The sync mechanics are in `references/boost-core-user-scope.md`.

## The contract (one line)

> `boost sync --scope=user --all` **copies** `resources/boost/skills/repo-init/SKILL.md` from the global vendor dir to `~/.{agent}/skills/repo-init-user/SKILL.md` as a regular file. It does **not** symlink.

So removing the package does not break the skill copy it left behind.

## Why this matters

In the global-install model:

1. The user runs `composer global require sandermuller/repo-init`, then `composer global exec -- boost sync --scope=user --all`.
2. boost-core reads `vendor/sandermuller/repo-init/resources/boost/skills/repo-init/SKILL.md` from the global vendor dir.
3. boost-core **copies** it to `~/.claude/skills/repo-init-user/SKILL.md` (and the other agent dirs) and records it in `~/.boost/manifests/sandermuller__repo-init.json`.
4. From any future session in any project, the skill auto-activates.

If `composer global remove sandermuller/repo-init` happens later:

- `vendor/sandermuller/repo-init/` is deleted.
- `~/.claude/skills/repo-init-user/SKILL.md` stays (copy, not symlink). The skill still activates; its pre-flight finds no `SPEC.md` under the global vendor dir and tells the user to re-install.
- The next `boost sync --scope=user --all` removes it, if boost-core is still installed globally through another package. boost-core reconciles removed packages: it deletes the files the package's manifest names, when their hash still matches, and then the manifest. An edited copy stays. When repo-init was the only global package that required boost-core, the removal also removes boost-core, and the copy stays until the user deletes it.

If boost-core wrote symlinks instead, the second bullet would break: removing the package would leave a dangling link.

## Verifying the contract

```bash
# Install
composer global require sandermuller/repo-init
composer global exec -- boost sync --scope=user --all

# Confirm it's a copy, not a symlink:
ls -la ~/.claude/skills/repo-init-user/SKILL.md
# Expected: regular file (no `->` arrow indicating a symlink target).

# The copy is not byte-identical to the vendor source: the sync renames the
# skill to `repo-init-user` in its frontmatter. Compare it with the hash boost-core
# recorded in the ownership manifest instead — they match right after the sync:
# (sha256sum on Linux; on macOS use `shasum -a 256` instead.)
sha256sum ~/.claude/skills/repo-init-user/SKILL.md
grep -o '"\.claude/skills/repo-init-user/SKILL.md": *"[0-9a-f]*"' ~/.boost/manifests/sandermuller__repo-init.json

# Now remove:
composer global remove sandermuller/repo-init

# Confirm the user-scope skill survives the removal:
ls -la ~/.claude/skills/repo-init-user/SKILL.md
# Expected: still present, still a regular file with the previous hash.

# Confirm the next user-scope sync reaps it. Skip this step when the removal also
# removed boost-core (`composer global show sandermuller/boost-core` fails):
composer global show sandermuller/boost-core && composer global exec -- boost sync --scope=user --all
ls -la ~/.claude/skills/repo-init-user/SKILL.md
# Expected: gone.
```

If the second `ls` shows the file is gone or a broken symlink, the copy contract is violated — file an issue against `sandermuller/boost-core`. If the last `ls` still shows an unedited file, reconcile-on-remove did not run — check that `~/.boost/manifests/sandermuller__repo-init.json` exists.

## What happens if the contract breaks

If boost-core shifts to symlinks, repo-init's user-scope skill becomes a dangling reference after `composer global remove`. The fix per `checklists/self-removal.md`:

1. Detect the broken symlink: `readlink ~/.claude/skills/repo-init-user/SKILL.md` returns a path that doesn't exist.
2. User must either:
   - Re-install: `composer global require sandermuller/repo-init`, then sync. Skill works again.
   - Manually clean: `rm -rf ~/.claude/skills/repo-init-user`. Skill won't auto-activate next session.

## Test in CI

The integrity workflow does NOT test this contract at the runtime level (it would require installing repo-init globally on the CI runner, which is destructive). Instead:

- `.github/workflows/integrity.yml` validates the spec + stub layout.
- This file (`tests/self-removal-contract.md`) serves as the design assertion.
- Manual verification at release time, per `RELEASING.md` step 6 ("Verify install path by running on a fresh machine").

## Related

- `checklists/self-removal.md` — the user-facing flow.
- `references/boost-core-user-scope.md` — the user-scope sync, manifest and reconcile-on-remove.
- `references/gitattributes-managed-block.md` — a parallel contract with package-boost (preserving foreign entries inside its managed block).
- SPEC.md §10 + RQ40 — the global-install architecture decision.
