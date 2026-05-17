# Self-removal

Mostly N/A. Repo-init is installed globally (`composer global require sandermuller/repo-init`) and stays installed across all projects and sessions. There is nothing to remove per target.

## When removal IS warranted

- User is decommissioning the tool entirely.
- User is troubleshooting a global install corruption.
- User installed project-locally (`composer require --dev sandermuller/repo-init`, per SPEC §3.4) and wants to clean up for that specific project.

## Global removal

```bash
composer global remove sandermuller/repo-init
```

Optional skill cleanup (the synced user-level skill dirs survive `composer global remove`):

```bash
rm -rf ~/.claude/skills/repo-init \
       ~/.cursor/skills/repo-init \
       ~/.agents/skills/repo-init \
       ~/.junie/skills/repo-init \
       ~/.kiro/skills/repo-init \
       ~/.github/skills/repo-init
```

(Keep the synced skills if you might re-install later — re-running `composer global require sandermuller/repo-init` will re-sync them, so leaving them in place is harmless.)

## Project-local removal (if installed locally per §3.4)

```bash
composer remove --dev sandermuller/repo-init
vendor/bin/testbench package-boost:sync  # or skip — the project-local skill stays under .claude/skills/repo-init/
```

## Re-installing later

```bash
composer global require sandermuller/repo-init
```

The post-install hook re-syncs the skill into `~/.claude/skills/repo-init/`. User is back where they were.

## Verify removal

- `composer global show sandermuller/repo-init` reports "Package not found".
- `$(composer global config home)/vendor/sandermuller/repo-init/` is gone.
- If user did the optional skill cleanup, the per-skill-dir paths above are also gone.
