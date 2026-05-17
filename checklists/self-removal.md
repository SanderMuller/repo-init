# Self-removal — final step only

**Self-removal is the explicit final step of the user's repo-init session — invoked once, not after every phase.**

If the user is still in the middle of a workflow (bootstrap done, audit not yet run; audit done, upgrade not yet applied), do NOT prompt for removal. Ask "what's next" instead.

## Pre-conditions

Before running `composer remove`:

- [ ] User has explicitly said they're done with repo-init for this repo.
- [ ] No half-finished writes (last phase ran to completion or the user aborted cleanly).
- [ ] No unstaged repo-init-driven changes pending review.

## Decision — does the skill need to survive?

The synced `.claude/skills/repo-init/SKILL.md` (and equivalents in `.cursor/skills/`, `.agents/skills/`, etc.) was COPIED from the package by `package-boost:sync` — it does not symlink. So `composer remove` deletes `vendor/sandermuller/repo-init/` but leaves the synced skill on disk.

- **User wants the skill to remain** (so they can re-invoke later without re-installing): no extra action. Note: re-invoking the skill without the package installed will succeed at the SKILL.md routing layer, then re-prompt to install via `composer require --dev sandermuller/repo-init`. This is by design.
- **User wants a fully clean removal**: also delete the synced skill dirs:
  ```bash
  rm -rf .claude/skills/repo-init .cursor/skills/repo-init .agents/skills/repo-init .github/skills/repo-init .junie/skills/repo-init .kiro/skills/repo-init
  ```

## Run

```bash
composer remove --dev sandermuller/repo-init
```

This also removes the transitive dev deps that repo-init pulled in (`sandermuller/package-boost`, `orchestra/testbench`) UNLESS the target repo also declared them directly in its own `require-dev` (which the bootstrap phase does — so package-boost and testbench stay).

## Verify

- [ ] `vendor/sandermuller/repo-init/` is gone.
- [ ] `composer.lock` regenerated cleanly (no orphan lock entries; `composer validate` passes).
- [ ] If user kept the synced skill: confirm `.claude/skills/repo-init/SKILL.md` still on disk.
- [ ] `vendor/sandermuller/package-boost/` and `vendor/orchestra/testbench/` still present (the bootstrap phase added them to the target's `require-dev` directly).

## Re-installing later

```bash
composer require --dev sandermuller/repo-init
```

Re-installs into `vendor/sandermuller/repo-init/`, post-install hook re-syncs the skill, and the user is back where they were. Nothing here is destructive.
