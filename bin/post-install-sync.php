#!/usr/bin/env php
<?php

declare(strict_types=1);

/**
 * Post-install / post-update hook for sandermuller/repo-init.
 *
 * Propagates the repo-init skill into the user's Claude/Cursor/Agents skill
 * dirs via boost-core's `vendor/bin/boost sync --scope=user` command (shipped
 * in boost-core commit bebd046b).
 *
 * Falls back gracefully to project-scope sync if --scope=user is unavailable
 * (older boost-core version, or boost-core not installed at all).
 *
 * See references/boost-core-user-scope.md for the full contract.
 */

$autoload = __DIR__ . '/../vendor/autoload.php';
if (!file_exists($autoload)) {
    $autoload = __DIR__ . '/../../../autoload.php';
}
if (file_exists($autoload)) {
    require $autoload;
}

// Prefer boost-core's `vendor/bin/boost` (where --scope=user lives).
$boost = __DIR__ . '/../vendor/bin/boost';
if (!file_exists($boost)) {
    $alternates = [
        __DIR__ . '/../../../bin/boost',
        __DIR__ . '/../../../../bin/boost',
    ];
    foreach ($alternates as $alt) {
        if (file_exists($alt)) {
            $boost = $alt;
            break;
        }
    }
}

if (!file_exists($boost)) {
    echo "[repo-init] boost-core binary not found; skipping skill propagation.\n";
    echo "[repo-init] sandermuller/boost-core is in repo-init's `require`; re-run:\n";
    echo "[repo-init]   composer global update sandermuller/repo-init\n";
    exit(0);
}

// User-scope sync — writes to $HOME/.{agent}/skills/repo-init/.
$cmd = escapeshellarg($boost) . ' sync --scope=user 2>&1';
$outputStr = shell_exec($cmd);
$outputStr = $outputStr === null ? '' : $outputStr;

$looksLikeSuccess = (
    stripos($outputStr, 'synced') !== false
    || stripos($outputStr, 'sync complete') !== false
    || (trim($outputStr) === '' && file_exists((getenv('HOME') ?: '') . '/.claude/skills/repo-init/SKILL.md'))
);

if ($looksLikeSuccess) {
    echo "[repo-init] Skill propagated to user-scope skill dirs (~/.claude/skills/repo-init/ etc.).\n";
    exit(0);
}

// Fallback: --scope=user not recognised (older boost-core, before bebd046b).
if (
    stripos($outputStr, 'option does not exist') !== false
    || stripos($outputStr, 'unknown option') !== false
    || stripos($outputStr, 'no such option') !== false
    || stripos($outputStr, 'unrecognized option') !== false
) {
    echo "[repo-init] boost-core --scope=user not supported in installed version.\n";
    echo "[repo-init] Bump sandermuller/boost-core to the version that ships commit bebd046b\n";
    echo "[repo-init] (or later). Falling back to project-scope sync — skill will only be\n";
    echo "[repo-init] available in current project. To force global propagation manually:\n";
    echo "[repo-init]   cd into any target repo with repo-init installed, then run\n";
    echo "[repo-init]   `vendor/bin/boost sync --scope=user`.\n";

    $fallbackCmd = escapeshellarg($boost) . ' sync 2>&1';
    passthru($fallbackCmd);
    exit(0);
}

// Some other error — surface it but don't fail composer install.
if (trim($outputStr) !== '') {
    echo "[repo-init] Skill sync had errors (continuing without failing composer install):\n";
    echo $outputStr . "\n";
}
exit(0);
