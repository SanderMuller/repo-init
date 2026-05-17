# `extra.branch-alias`

When and how to add `extra.branch-alias` to a package's `composer.json`. Bootstrap doesn't add it by default; this reference is for the agent to consult when the user asks about it (or when bootstrapping a known-early-stage package).

## What it is

`extra.branch-alias` tells Composer to treat a development branch as if it were a versioned release. Example:

```json
{
  "extra": {
    "branch-alias": {
      "dev-main": "0.2.x-dev"
    }
  }
}
```

This lets consumers require `vendor/package: ^0.2` from `main` before there's a tagged `0.2.0` release. Without the alias, consumers would need `dev-main` or `0.2.x-dev` directly — which is more friction.

## When to add it

- Early-stage packages (pre-1.0) where you want consumers to pin to `^0.X` and pick up `main` until the first `0.X.0` tag.
- Packages with frequent unreleased changes that downstream apps want to track ahead of tags.
- Pre-release / RC workflows where a dev branch represents an upcoming MAJOR.

## When NOT to add it

- Stable packages (1.0+) — semver tagging is enough.
- Packages where you actively don't want consumers pulling unreleased `main` code.
- Packages where the alias would lie about compatibility (e.g. `dev-main: 1.x-dev` when main is breaking changes for v2 — confusing for consumers).

## Observed pattern in sander packages

- `sandermuller/laravel-x402-mcp` uses `extra.branch-alias.dev-main: 0.2.x-dev`.
- `sandermuller/php-x402` uses `extra.branch-alias.dev-main: 0.2.x-dev`.
- Older / stable sander packages (queue-insights, fluent-validation, solana-pubkey) do NOT use it — they tag frequently.

## How to add (manual / per-package decision)

Edit `composer.json`:

```json
{
  "extra": {
    "branch-alias": {
      "dev-main": "0.X.x-dev"
    }
  }
}
```

Substitute `0.X` with your current MINOR + 1 (the about-to-be-released version). When you tag `0.X.0`, update the alias to `0.(X+1).x-dev`.

## Audit / upgrade behaviour in repo-init

- Audit phases do NOT flag `extra.branch-alias` as MISSING. It's opt-in per package, not part of the canonical baseline (per `references/upgrade-merge-modes.md` `merge-keys` mode, only documented keys are checked).
- Upgrade phases never add or modify `extra.branch-alias` automatically. If the user wants to add it, they edit `composer.json` manually following this doc.

## Phase 8 / v0.2

If repo-init eventually ships interactive branch-alias prompts at bootstrap time, the agent will read this doc to derive the right alias version for new packages. v0.1 keeps it manual.
