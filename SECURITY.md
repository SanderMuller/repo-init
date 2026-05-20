# Security policy

## Supported versions

| Version | Supported |
|---|---|
| 0.1.x | ✅ |

Pre-`1.0.0`: only the latest MINOR is actively supported.

## Reporting a vulnerability

Email security issues to **<github@scode.nl>** with the subject `[repo-init security]`. Do NOT open a public GitHub issue for security-related concerns.

You'll get an acknowledgement within 72 hours. Coordinated disclosure timeline is negotiated case-by-case.

## What's in scope

`sandermuller/repo-init` ships **only markdown + stub files** — no PHP code, no executable scripts. The security surface is therefore:

1. **Malicious phase / reference content** — if a phase or reference doc instructs the agent to do something destructive (e.g. silently overwrite `.env`, exfiltrate secrets), that's a security issue. Report it.
2. **Stub composer.json files** — if a stub lists a typosquatted or malicious package as a dep that gets `composer require`d into target repos by the agent, that's a security issue.
3. **Skill activation triggers** — if the `repo-init` skill activates on prompts the user didn't intend (e.g. on every "help" prompt), that's a usability bug, not a security issue. Open a regular issue.

## What's out of scope

- Issues with `sandermuller/package-boost`, `orchestra/testbench`, `laravel/boost`, or any other transitive dep — report to the respective project.
- The AI agent's own behaviour (Claude Code, Cursor, etc.) — we don't control the agents; we ship the instructions they read.
- User errors in following the phase instructions — phase files include safety rails (`checklists/per-category-never-touch.md`, git-dirty guard) but rely on the agent honouring them.

## Hardening recommendations for users

- Pin `sandermuller/repo-init` to a specific version in `composer.lock` (global or project-local) so a malicious package-boost release can't auto-propagate without your knowledge.
- Review the propagated skill before letting it auto-activate: `cat ~/.claude/skills/sandermuller__repo-init/SKILL.md`.
- Use the git-dirty guard religiously — never run audit/upgrade against a dirty working tree.
- Verify the `--with-hihaho-rules` opt-in default is correct for your context (vendor-driven inference may not match your intent for forked / org-specific scenarios).
