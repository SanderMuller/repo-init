<?php declare(strict_types=1);

namespace __NAMESPACE__\Tests\Unit;

use PHPUnit\Framework\TestCase;

final class ExampleTest extends TestCase
{
    public function test_php_runtime_is_available(): void
    {
        $this->assertNotFalse(getmypid());
    }
}
