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

The synced user-level skill dirs survive `composer global remove`. The next `composer global exec -- boost sync --scope=user --all` deletes them (an edited copy stays), as long as boost-core is still installed globally. Otherwise, clean up by hand:

```bash
rm -rf ~/.{claude,cursor,agents,amp,gemini,junie,kiro,opencode}/skills/{repo-init-user,sandermuller__repo-init}
```

A `~/.{agent}/skills/repo-init/` folder from before boost-core 0.4 may also exist. No manifest covers it, so check that it is repo-init's before you delete it.

(Keep the synced skills if you might re-install later — the install and sync commands overwrite them, so leaving them in place is harmless.)

## Project-local removal (if installed locally per §3.4)

```bash
composer remove --dev sandermuller/repo-init
vendor/bin/boost sync  # or skip — the project-local skill stays under .claude/skills/repo-init/
```

## Re-installing later

```bash
composer global require sandermuller/repo-init
```

Then run `composer global exec -- boost sync --scope=user --all` to re-sync the skill into `~/.claude/skills/repo-init-user/`. User is back where they were.

## Verify removal

- `composer global show sandermuller/repo-init` reports "Package not found".
- `$(composer global config home)/vendor/sandermuller/repo-init/` is gone.
- If user did the optional skill cleanup, the per-skill-dir paths above are also gone.
