<?php

declare(strict_types=1);

namespace __NAMESPACE_ESCAPED__;

use Composer\Command\BaseCommand;
use Composer\Plugin\Capability\CommandProvider as ComposerCommandProvider;

final class CommandProvider implements ComposerCommandProvider
{
    /**
     * @return array<BaseCommand>
     */
    public function getCommands(): array
    {
        return [];
    }
}
