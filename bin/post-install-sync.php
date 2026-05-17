#!/usr/bin/env php
<?php

declare(strict_types=1);

/**
 * Post-install / post-update hook for sandermuller/repo-init.
 *
 * Tries to sync the repo-init skill into the user's Claude/Cursor/Agents
 * skill dirs via `vendor/bin/testbench package-boost:sync --scope=user`.
 *
 * The --scope=user flag is a package-boost feature that may not be shipped
 * yet (tracked as repo-init Open Question #3 + references/package-boost-user-scope.md).
 * If the flag is unrecognised, this script falls back to project-scope sync
 * (which writes to ./<cwd>/.claude/skills/... — useful when repo-init was
 * installed project-locally rather than globally).
 *
 * Silent no-op if testbench isn't installed or no sync command is available
 * — the user gets a clear message at the next agent invocation rather than
 * a confusing composer error.
 */

$autoload = __DIR__ . '/../vendor/autoload.php';
if (!file_exists($autoload)) {
    $autoload = __DIR__ . '/../../../autoload.php';
}
if (file_exists($autoload)) {
    require $autoload;
}

$testbench = __DIR__ . '/../vendor/bin/testbench';
if (!file_exists($testbench)) {
    $alternates = [
        __DIR__ . '/../../../bin/testbench',
        __DIR__ . '/../../../../bin/testbench',
    ];
    foreach ($alternates as $alt) {
        if (file_exists($alt)) {
            $testbench = $alt;
            break;
        }
    }
}

if (!file_exists($testbench)) {
    echo "[repo-init] testbench not found; skipping skill propagation.\n";
    echo "[repo-init] Install orchestra/testbench (it's in repo-init's `require`), then re-run:\n";
    echo "[repo-init]   composer global update sandermuller/repo-init\n";
    exit(0);
}

// Capture --scope=user attempt output to detect feature-not-shipped case.
$cmd = escapeshellarg($testbench) . ' package-boost:sync --scope=user 2>&1';
$outputStr = shell_exec($cmd);
$outputStr = $outputStr === null ? '' : $outputStr;

// shell_exec returns null on failure; treat as exit code != 0.
// Heuristic: success looks like a "synced X skills" message. Failure looks like
// "option does not exist" / "Unknown option" / a stack trace.
$looksLikeSuccess = (
    stripos($outputStr, 'synced') !== false
    || stripos($outputStr, 'sync complete') !== false
    || (trim($outputStr) === '' && file_exists(getenv('HOME') . '/.claude/skills/repo-init/SKILL.md'))
);

if ($looksLikeSuccess) {
    echo "[repo-init] Skill propagated to user-scope skill dirs (~/.claude/skills/repo-init/ etc.).\n";
    exit(0);
}

// Fallback: --scope=user not recognised (package-boost feature not yet shipped — Open Q #3).
if (
    stripos($outputStr, 'option does not exist') !== false
    || stripos($outputStr, 'unknown option') !== false
    || stripos($outputStr, 'no such option') !== false
    || stripos($outputStr, 'unrecognized option') !== false
) {
    echo "[repo-init] package-boost --scope=user not supported yet (see Open Question #3).\n";
    echo "[repo-init] Falling back to project-scope sync — the skill will only be available\n";
    echo "[repo-init] in the current project, NOT globally. To make the skill global, install\n";
    echo "[repo-init] repo-init in a target repo with `composer require --dev sandermuller/repo-init`\n";
    echo "[repo-init] then run `vendor/bin/testbench package-boost:sync` from that target.\n";

    $fallbackCmd = escapeshellarg($testbench) . ' package-boost:sync 2>&1';
    passthru($fallbackCmd);
    exit(0);  // Don't fail composer install — degraded sync is OK.
}

// Some other error — surface it but don't fail composer install.
if (trim($outputStr) !== '') {
    echo "[repo-init] Skill sync had errors (continuing without failing composer install):\n";
    echo $outputStr . "\n";
}
exit(0);
