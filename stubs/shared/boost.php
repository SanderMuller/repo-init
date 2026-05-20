<?php

declare(strict_types=1);

use SanderMuller\BoostCore\Config\BoostConfig;
use SanderMuller\BoostCore\Enums\Agent;

/**
 * boost-core configuration — which AI agents `composer boost:sync` writes to,
 * and which dependency vendors' shipped skills/guidelines are synced.
 *
 * `withAllowedVendors()` is an explicit allowlist: a dependency's skills sync
 * ONLY if its package name is listed here. Both boost umbrellas are listed
 * below — your package installs at most one of them; any not installed is a
 * harmless no-op. Add other skill-shipping dependency vendors as you adopt them.
 *
 * Re-run `composer boost:install` to change agents/vendors interactively, or
 * hand-edit this file; then run `composer boost:sync`.
 *
 * Docs: https://github.com/sandermuller/boost-core
 */
return BoostConfig::configure()
    ->withAgents([
        Agent::CLAUDE_CODE,
        Agent::COPILOT,
        Agent::CODEX,
    ])
    ->withAllowedVendors([
        'sandermuller/package-boost-laravel',
        'sandermuller/package-boost-php',
    ])
    ->withDisabledEmitters([]);
