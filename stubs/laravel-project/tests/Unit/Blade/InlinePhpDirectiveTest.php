<?php declare(strict_types=1);

namespace Tests\Unit\Blade;

use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;
use Symfony\Component\Finder\Finder;

/**
 * Pint does not format Blade, so this test enforces the rule in
 * .ai/rules/views.md. Blade also compiles `@php ($x = 1)`, hence the
 * optional whitespace in the pattern.
 */
final class InlinePhpDirectiveTest extends TestCase
{
    #[Test]
    public function blade_templates_use_php_blocks_instead_of_the_inline_directive(): void
    {
        $viewsPath = dirname(__DIR__, 3) . '/resources/views';

        if (! is_dir($viewsPath)) {
            self::markTestSkipped('This application has no resources/views directory.');
        }

        $finder = new Finder()
            ->files()
            ->in($viewsPath)
            ->name('*.blade.php');

        $violations = [];

        foreach ($finder as $file) {
            foreach (explode("\n", $file->getContents()) as $lineNumber => $line) {
                if (preg_match('/@php[ \t]*\(/', $line) === 1) {
                    $violations[] = $file->getRelativePathname() . ':' . ($lineNumber + 1);
                }
            }
        }

        self::assertSame([], $violations, sprintf(
            "Use a @php ... @endphp block instead of the inline @php(...) directive:\n%s",
            implode("\n", $violations),
        ));
    }
}
