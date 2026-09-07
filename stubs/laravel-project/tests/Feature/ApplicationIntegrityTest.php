<?php declare(strict_types=1);

namespace Tests\Feature;

use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * The header contract, asserted on a real request. This is the regression guard
 * for the middleware stack: reorder it, or let a package strip a header, and
 * this fails. See references/laravel-security-canon.md.
 *
 * Extend it per response surface — the web app, the API, an embed — and assert
 * the CORS headers that must be absent as well as those present.
 */
final class ApplicationIntegrityTest extends TestCase
{
    #[Test]
    public function verify_http_headers(): void
    {
        $this->get('/')
            ->assertOk()
            ->assertHeaderMissing('Access-Control-Allow-Credentials')
            ->assertHeaderMissing('Access-Control-Allow-Origin')
            ->assertHeader('X-Frame-Options', 'SAMEORIGIN')
            ->assertHeader('Strict-Transport-Security', 'max-age=31536000;includeSubDomains;preload')
            ->assertHeader('X-XSS-Protection', '1; mode=block')
            ->assertHeader('Referrer-Policy', 'strict-origin-when-cross-origin')
            ->assertHeader('X-Content-Type-Options', 'nosniff')
            ->assertHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
    }

    #[Test]
    public function non_existing_page_gives_404(): void
    {
        $this->get('/this/page/should/not/exists/and/return/a/404')
            ->assertNotFound();
    }
}
