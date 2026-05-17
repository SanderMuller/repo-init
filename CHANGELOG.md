# Changelog

All notable changes to `sandermuller/repo-init` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Pre-`1.0.0` releases may introduce breaking changes in MINOR bumps; we surface those here clearly.

## [Unreleased]

## [0.1.0] - 2026-05-17

Initial release. Global-install model (`composer global require sandermuller/repo-init`).

### Added

- **Skill** — `.ai/skills/repo-init/SKILL.md` single entry point. Routes the agent through 3 steps: decide intent (bootstrap/audit/upgrade), decide category (5 options), open the matching phase file.
- **5 categories supported**: `laravel-project`, `laravel-package` (sander-style + spatie-style variants), `php-package`, `phpstan-extension`, `rector-extension`.
- **15 phase playbooks** under `phases/` — one per (category × mode), each self-contained.
- **14 reference docs** under `references/` covering detection rules, dep lists (md + machine-readable yml parallel), composer scripts, phpstan/rector configs, canonical reference repos, version defaults, pest-vs-phpunit, gitattributes managed-block contract, upgrade merge modes, composer failure modes, placeholder transforms.
- **5 checklists** under `checklists/` — preflight, per-category-never-touch, post-bootstrap-verification, post-upgrade-verification, self-removal.
- **6 stub trees** under `stubs/` — shared + 5 categories. Stubs use literal `__PLACEHOLDER__` strings the agent finds-and-replaces per `references/placeholder-rules.md`.
- **Composer scripts** in package's own composer.json: `post-install-cmd` and `post-update-cmd` auto-sync the skill into `~/.claude/skills/` via `package-boost:sync --scope=user`.

### Architecture decisions

- **Zero PHP code in the package.** No `src/`, no artisan, no Symfony Console. The agent does the work; the package is the playbook.
- **Global install by default** (matches `composer global require laravel/installer`). Project-local install kept as escape hatch.
- **Stays-installed-until-done** — no per-target install or self-removal. Repo-init lives globally; targets stay clean.
- **No state files written to targets.** Findings are conversation-scoped.

### Dependencies

- Requires `sandermuller/package-boost: ^0.15` (for skill propagation).
- Requires `orchestra/testbench: ^9.0||^10.0||^11.0` (to invoke `package-boost:sync` outside a Laravel app).

### Known blockers (resolved before release)

- `sandermuller/package-boost` must ship the `--scope=user` sync feature (Open Question #3 in SPEC.md). Tracking this as a pre-release dependency.

### Spec

- 40 Resolved Questions documenting every architectural decision + rationale.
- 4 Open Questions remaining: `--ai` flag verification on Laravel installer; package-boost user-scope sync feature; skill-copy-not-symlink behavior verification.
- Independently reviewed via codex in 3 rounds (v3 → v4 → v5 → v6). All findings addressed.

[Unreleased]: https://github.com/sandermuller/repo-init/compare/0.1.0...HEAD
[0.1.0]: https://github.com/sandermuller/repo-init/releases/tag/0.1.0
