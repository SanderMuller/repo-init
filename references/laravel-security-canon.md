# Laravel project security canon

The canonical security configuration for a `laravel-project`. Every value here is
verified present in the reference apps — `hihaho/hihaho`, `mijntp`, `collectiq` —
and the deviations between them are recorded as such.

This reference covers `laravel-project` only. Packages have no session, no
middleware stack, and no HTTP surface of their own.

Related: `references/canonical-repos.md`, `references/per-category-deps.md`,
`phases/bootstrap-laravel-project.md`, `phases/audit-laravel-project.md`.

## Why the values are literals, not `env()`

The framework's own defaults are the argument. `vendor/laravel/framework/config/session.php`
on Laravel 13 ships:

```php
'encrypt' => env('SESSION_ENCRYPT', false),
'secure' => env('SESSION_SECURE_COOKIE'),          // no default at all
'http_only' => env('SESSION_HTTP_ONLY', true),
'same_site' => env('SESSION_SAME_SITE', 'lax'),
'partitioned' => env('SESSION_PARTITIONED_COOKIE', false),
```

Three of the five default to off, and `secure` has no default — an app that
never sets `SESSION_SECURE_COOKIE` sends its session cookie over plain HTTP.
`laravel new` publishes the same shape into the project. The canon replaces
those five `env()` calls with literals.

A security setting that reads `env()` fails open. A missing key, a typo, or a
`.env` that a deploy did not update silently downgrades the app. The canon
hard-codes the four session-cookie flags so no environment can weaken them.
`config:cache` does not change this — the literal is baked in either way.

The cost is local development over plain HTTP. `secure => true` means the
browser drops the session cookie on `http://`. The canon accepts that: local
sites run over HTTPS (Herd, Valet, `artisan serve` behind a TLS proxy). Do not
"fix" a broken local login by turning the flag into an `env()` call.

## `config/session.php`

| Key | Canonical value | Source |
|---|---|---|
| `encrypt` | `true` (literal) | all three |
| `secure` | `true` (literal) | hihaho, collectiq |
| `http_only` | `true` (literal) | all three |
| `partitioned` | `true` (literal) | all three |
| `same_site` | `'lax'` — `'none'` only for an embedded app | collectiq / hihaho + mijntp |
| `cookie` | `session_<slug>_partitioned` + environment suffix | hihaho, collectiq |
| `path` | `'/'` | all three |
| `expire_on_close` | `false` | all three |
| `driver`, `lifetime`, `domain` | not security canon — leave on `env()` | — |

`laravel new` writes `config/session.php`. The canon is a set of edits to that
file, not a replacement file. Keep the framework comment blocks.

### The four flags

```php
'encrypt' => true,
'secure' => true,
'http_only' => true,
'partitioned' => true,
```

- `encrypt` — the session payload is encrypted at rest in the store, so a
  compromised Redis or database row does not hand over session contents.
- `secure` — the cookie only travels over HTTPS.
- `http_only` — JavaScript cannot read the cookie, so an XSS payload cannot
  exfiltrate the session id.
- `partitioned` — CHIPS. A third-party cookie is keyed to the embedding site.
  Chrome requires it for a cross-site cookie to survive third-party cookie
  blocking. It requires `secure => true` and `same_site => 'none'` to have any
  effect; it is harmless on a first-party `lax` app, so the canon sets it
  everywhere and the embedded apps get it for free.

**Deviation to fix:** mijntp has `'secure' => env('SESSION_SECURE_COOKIE', true)`.
The default is safe, but an env key can turn it off. Audit flags it.

### `same_site`

This is the one real fork between the reference apps.

- Default: `'lax'` (collectiq). Correct for an app nobody frames.
- Embedded: `'none'` (hihaho, mijntp). Required when the app runs inside an
  iframe on a third-party origin — hihaho's video player, mijntp's portal.
  `'none'` is only accepted by browsers together with `secure => true`, which
  the canon already forces.

Pick `'lax'` unless the app is framed cross-origin. Never `'strict'` — it breaks
return-from-redirect login flows (OAuth, SAML, payment providers).

### Cookie name

```php
'cookie' => env(
    'SESSION_COOKIE',
    'session___PACKAGE___partitioned' . (env('APP_ENV', 'production') === 'production' ? '' : '_' . env('APP_ENV', 'production'))
),
```

Two things this buys:

1. **The `_partitioned` suffix forces a fresh cookie.** Browsers key a cookie by
   name; changing the flags on an existing name leaves the old un-partitioned
   cookie in place. A new name retires it.
2. **The environment suffix isolates environments.** `session_app_partitioned`
   in production, `session_app_partitioned_staging` on staging. Without it, a
   shared parent domain lets staging and production overwrite each other's
   session cookie.

mijntp's `'mytp_session_' . env('APP_ENV')` is the older shape — same intent, no
`_partitioned` marker. Leave it; do not churn a live cookie name during an
upgrade unless the flags change with it.

### `.env.example`

Ship `SESSION_DRIVER`, `SESSION_LIFETIME`, and `SESSION_DOMAIN` only. Never ship
`SESSION_ENCRYPT` or `SESSION_SECURE_COOKIE` — the config hard-codes both, so
the keys are dead and read as knobs that do not exist.

Remove any `SESSION_ENCRYPT` line during bootstrap. The framework's own
`config/session.php` reads `env('SESSION_ENCRYPT', false)`, so the key is real
until the project's published config replaces the call with a literal — and a
line that survives that replacement reads as a knob that still works. collectiq
carries `SESSION_ENCRYPT=false` against a hard-coded `true`. Audit flags it.

## HSTS

Package: `zae/strict-transport-security: ^0.0.3` in `require` (all three apps).

`config/hsts.php` is byte-identical across all three:

```php
'max-age' => 31536000,       // one year
'includeSubdomains' => true,
'preload' => true,
```

Header produced: `Strict-Transport-Security: max-age=31536000;includeSubDomains;preload`.

The package registers no service provider and publishes no config. `HSTS`
constructor-injects `Illuminate\Config\Repository`, which the container already
binds, and reads `hsts.max-age` / `hsts.includeSubdomains` / `hsts.preload` with
the same defaults the file above sets. So the file is hand-written, not
published, and nothing goes in `bootstrap/providers.php`.

The middleware sets the header unconditionally — it does not gate on
`$request->secure()`. That is why the integrity test asserts the header on a
plain test request with no HTTPS setup.

**`preload => true` is a commitment.** Submitting to the HSTS preload list means
every browser refuses plain HTTP to the domain and every subdomain, and removal
takes months. Only keep it on if every subdomain — including internal tooling
and anything on a staging suffix of the same apex — serves HTTPS.

## Security headers middleware

`app/Http/Middleware/SecurityHeaders.php`, appended globally.

Canonical header set:

| Header | Value | Source |
|---|---|---|
| `X-Frame-Options` | `SAMEORIGIN` | all three |
| `X-XSS-Protection` | `1; mode=block` | all three |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | all three |
| `X-Content-Type-Options` | `nosniff` | all three |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=()` | collectiq only |

`Permissions-Policy` is the one header the canon adds beyond what all three apps
agree on. hihaho sends the deprecated `Feature-Policy` instead (see below) and
mijntp sends neither. It is in the canon because it is the current header and
the three values above are the safe default for an app that uses none of them.

The stub always sends `X-Frame-Options: SAMEORIGIN`. An app that is framed on
purpose relaxes it per allowed origin — hihaho and collectiq both do, and both
need a per-app origin list, so it is not part of the floor. Match the origin on
the full host or on a leading-dot suffix (`.example.com`). A bare
`str_ends_with($host, 'example.com')` also matches `evilexample.com`.

The middleware returns early for `RedirectResponse`, `BinaryFileResponse`, and
`StreamedResponse` — a header on a file download or a redirect is noise, and a
`StreamedResponse` may already have flushed.

`X-XSS-Protection` is a dead header in current browsers. It stays because it is
still read by old scanners and costs nothing.

### Optional tier

Two additions collectiq carries. Add them when the app warrants it; they are not
the floor because both need per-app tuning:

- **Content-Security-Policy** — needs a per-app source list. Use
  `Vite::useCspNonce()` plus `'nonce-...'` for scripts. Filament panels need
  `'unsafe-inline'`; keep that scoped to the panel routes, not the whole app.
- **No-cache for authenticated responses** — `Pragma: no-cache` +
  `Cache-Control: no-cache, no-store, must-revalidate` when `$request->user()`
  is not null. Stops the back button from showing a logged-out user the previous
  page from the browser cache. Pair it with removing PHP's own
  `Pragma: no-cache` on guest responses, or guest pages lose normal caching.

### Do not use `mazedlx/feature-policy`

hihaho carries `AddFeaturePolicyHeaders` and `config/feature-policy.php`. The
`Feature-Policy` header is the deprecated predecessor of `Permissions-Policy`
and no current browser reads it. New projects set `Permissions-Policy` as a
plain header string in `SecurityHeaders`. Do not carry the package forward.

## `bootstrap/app.php` wiring

```php
->withMiddleware(function (Middleware $middleware): void {
    $middleware->append([
        SecurityHeaders::class,
        StrictTransportSecurity::class,
    ]);
})
```

`append()` — not `web()`. The headers must land on API and webhook responses
too, not only the web group.

mijntp is still on the Laravel 10 `app/Http/Kernel.php` layout; the same two
classes go in the global `$middleware` array there.

## `ApplicationIntegrityTest`

`tests/Feature/ApplicationIntegrityTest.php`. One test asserts the whole header
contract on a real request, one asserts the 404 path. It is a regression guard:
the day someone reorders the middleware stack or a package strips a header, this
fails.

Assert the headers that must be **absent** as well as those present.
`assertHeaderMissing('Access-Control-Allow-Origin')` on a non-CORS request is
what catches a wildcard CORS config.

The stub is the floor. Extend it per app:

- Per response surface — hihaho asserts a different contract for the studio, the
  player, the embed, and the API.
- CORS — assert the allowed origin echoes back and a denied origin does not.
- Frame-ancestors — assert a look-alike domain (`evilexample.com` against
  `example.com`) is refused. A bare suffix comparison matches it; the dot in
  `https://*.example.com` is what keeps it out.

`phpunit.xml` needs no HTTPS setup for the test to pass. The reference apps set
`APP_ENV=testing`, `APP_HOST=<app>.test`, `SESSION_DRIVER=array`, and
`BCRYPT_ROUNDS=4`.

## Supporting canon

Verified identical across all three apps:

- `config/app.php` — debug is cast and defaults to `false`. mijntp and collectiq
  write `'debug' => (bool) env('APP_DEBUG', false)` inline; hihaho assigns
  `$debug = false` first and only then `$debug = (bool) env('APP_DEBUG', false)`
  under its own guard, so the fail-closed default survives even when the env
  read is skipped. Either shape is canonical; an uncast `env('APP_DEBUG')` or a
  default of `true` is not. Also `'cipher' => 'AES-256-CBC'` and
  `'key' => env('APP_KEY')`.

  `config('app.host')` is NOT a framework key. All three apps add it themselves.
  Anything in the canon that needs the app host — a framing allow-list, a CORS
  origin — has to add the key first, and read it as `Config::string('app.host')`
  so PHPStan does not see `mixed`.
- `config/hashing.php` — nothing to change. hihaho and mijntp publish the file
  with `'driver' => 'bcrypt'`, `'rounds' => env('BCRYPT_ROUNDS', 12)` and
  `'verify' => true`; collectiq does not publish it at all. Those are the
  framework defaults (`vendor/laravel/framework/config/hashing.php` ships
  `env('BCRYPT_ROUNDS', 12)`), so publishing the file buys nothing. Only act
  when a published file LOWERS the rounds.
- `config/auth.php` — `'password_timeout' => 10800`, password reset
  `'expire' => 60`, `'throttle' => 60`.
- `spatie/security-advisories-health-check: ^1.3.2` in `require`, registered as
  `SecurityAdvisoriesCheck::new()` in the health-check list. It fails the health
  check when a dependency has a published advisory.
- `config/cors.php` — only ship it when the app actually serves cross-origin
  requests. `'allowed_origins' => ['*']` is acceptable **only** with
  `'supports_credentials' => false`; the two together are a session-theft
  primitive and the browser rejects the combination anyway. An app that needs
  credentials must list its origins.

## Known findings in the reference apps

Recorded so an audit does not copy them forward:

- collectiq — `SecurityHeaders::originIsAllowedToFrameApplication()` reads
  `config('hihaho.allowed-origins.studio')`. That key does not exist in
  collectiq; the config path was copied from hihaho. The call returns the `[]`
  default, so every non-app-host referer falls through to `SAMEORIGIN`. It fails
  closed, but the branch is dead code.
- collectiq — `.env.example` `SESSION_ENCRYPT=false` against a hard-coded `true`. The skeleton wrote the line; nobody removed it.
- mijntp — `'secure' => env('SESSION_SECURE_COOKIE', true)`.
