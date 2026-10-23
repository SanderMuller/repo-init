<?php

declare(strict_types=1);

use SanderMuller\BoostCore\Config\BoostConfig;
use SanderMuller\BoostCore\Enums\Agent;
use SanderMuller\BoostCore\Enums\Tag;
use SanderMuller\BoostCore\Skills\Remote\RemoteSkillSource;

/**
 * boost-core configuration, read by `sandermuller/project-boost-laravel`.
 *
 * `laravel/boost` keeps the MCP server; `project-boost-laravel` takes over the
 * agent-file fan-out (including laravel/boost's bundled skills) and adds tag
 * filtering and remote skill sources. Sync with `php artisan project-boost:sync`
 * — never the bare `vendor/bin/boost sync`, which skips the `laravel/boost`
 * skill set — and never run `php artisan boost:update` here.
 *
 * `withAgents()` lists the agents `laravel/boost` wrote into `boost.json`. A
 * successful sync archives `boost.json` only after every agent in it that
 * boost-core supports appears here, so keep the two lists aligned.
 *
 * `withTags()` filters every non-host skill (allowlisted vendors, remote
 * sources, and the injected `laravel/boost` set): a tagged skill ships only
 * when all its tags are listed. `voice` is always on — it ships the writing-voice guideline
 * every repo in this setup uses; keep it in the list. Add the tags your stack
 * needs (`frontend`, `livewire`, `pest`, …) and check the result with
 * `php artisan project-boost:where` and `vendor/bin/boost tags`.
 *
 * `withAllowedVendors()` is an explicit allowlist: a dependency's own boost
 * skills sync ONLY if its package name is listed here. `laravel/boost` is not
 * listed — the wrapper injects its skills.
 *
 * `withRemoteSkills()` pulls skills straight from GitHub. The entry below is
 * repo-init's canonical set, pinned to a commit SHA so an upstream push cannot
 * change what lands here. The first sync downloads it; set `BOOST_GITHUB_TOKEN`
 * if you hit GitHub's anonymous rate limit. To opt out, keep the entry and add
 * `->withExcludedSkills(['cloudflare/security-audit-skill:security-audit'])`.
 *
 * Docs: https://sandermuller.github.io/boost-core/packages/project-boost-laravel/configuration
 */
return BoostConfig::configure()
    ->withAgents([
        Agent::CLAUDE_CODE,
        Agent::CURSOR,
        Agent::COPILOT,
        Agent::CODEX,
    ])
    ->withAllowedVendors([
        'sandermuller/boost-skills',
    ])
    ->withTags(['voice', Tag::Laravel__SKILL_TAGS__])
    ->withRemoteSkills([
        RemoteSkillSource::githubPath('cloudflare/security-audit-skill', 'c1c8a8c1471069fb0e188eeaff69b8e8db6564a8', [
            'security-audit' => 'skills/security-audit',
        ]),
    ])
    ->withDisabledEmitters([]);
