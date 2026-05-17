# Per-category never-touch list

Files the agent must never write, regardless of phase.

## Scope per mode

- **Bootstrap mode**: target dir is empty (modulo `.git/`) — the cwd-empty precondition is the protection. The git-dirty rule is NOT applied; new files from `laravel new` are expected to be untracked at the moment bootstrap starts writing on top of them. Security never-touch paths below still apply.
- **Audit / Upgrade mode**: BOTH security never-touch paths AND git-dirty rule apply. Agent runs `git status --porcelain` before any write and skips paths with prefixes `M`, ` M`, `MM`, `A`, `??`. Override requires explicit per-file user opt-in.

## `laravel-project` security never-touch (all modes)

Never write to:

- `app/Http/Middleware/Authenticate.php`
- Anything under `app/Policies/`
- Anything under `app/Http/Middleware/`
- `config/auth.php`
- `config/sanctum.php`
- `config/permission.php`
- Any file matching `config/auth*.php`
- `routes/auth.php`
- `.env`
- Any file matching `.env.*` (with one exception: `.env.example` may be written on bootstrap only)

## All categories security never-touch (all modes)

Never write to:

- Anything matching `.env*` glob (except `.env.example` on bootstrap)
- Anything under `.git/`
- Anything under `vendor/`
- Anything under `node_modules/`
- Anything under `.idea/`, `.vscode/`, `.fleet/`, `.cursor/`

## Override semantics

`--force` (or any agent-side equivalent) does NOT override this list. Bypassing requires an explicit "yes write to <specific-path>" from the user, per-file.

## Why these paths

Security-sensitive code (auth middleware, policies) and secrets (`.env`) are the highest-risk surfaces; an agent overwrite is irreversible without git history. Vendor/build directories are derived state — overwriting them confuses Composer/npm.
