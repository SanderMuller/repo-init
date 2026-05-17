# Pre-flight checklist

Run before any phase. If anything is red, stop and ask the user before proceeding.

## Git state

- [ ] Are we in a git repo? (`git rev-parse --is-inside-work-tree`)
- [ ] What branch are we on? (`git branch --show-current`) — if `main`/`master`, suggest creating a feature branch first.
- [ ] Is the working tree clean? (`git status --porcelain`) — for **audit/upgrade** modes, untracked or modified files are blocked by the git-dirty guard (see `per-category-never-touch.md`). For **bootstrap** mode, cwd should be empty modulo `.git/`.

## Composer state

- [ ] Is `composer` available in PATH? (`composer --version`)
- [ ] If `vendor/` exists, is it healthy? (`composer validate --no-check-publish` returns 0)
- [ ] If `composer.lock` exists, does it match `composer.json`? (`composer validate` warns if not)

## Repo-init state

- [ ] Is `vendor/sandermuller/repo-init/` present? (SKILL.md handles install if not, per its pre-flight step 1.)
- [ ] Is `.claude/skills/repo-init/SKILL.md` present? (Should be, after `package-boost:sync`.)

## Target-dir verification (bootstrap mode only)

- [ ] Did the user pass a positional `name`?
  - **Yes** → `mkdir <name>` succeeds (dir didn't exist) AND `cd <name>` works.
  - **No** → cwd contains only `.git/` (and nothing else). If anything else is present, stop and ask the user for a `name` to scaffold into a fresh subdir.

## Network reachability (bootstrap + upgrade modes)

- [ ] Can we reach packagist? (`composer search laravel/framework 2>&1 | head -3` returns rows, not a network error.)
- [ ] If `--with-hihaho-rules` opt-in: can we reach packagist's `hihaho/*` packages?

## Stop conditions

Stop and ask the user if any of:

- Working tree has uncommitted changes the agent didn't create (`git status` shows pre-existing diffs/untracked).
- `composer.lock` and `composer.json` are out of sync (would interact badly with our subsequent `composer require`).
- Network is down (can't reach packagist).
- Running as root (`id -u` returns 0) — composer warns; ask user to confirm.
