# __PACKAGE__

[![Latest Version on Packagist](https://img.shields.io/packagist/v/__VENDOR__/__PACKAGE__.svg?style=flat-square)](https://packagist.org/packages/__VENDOR__/__PACKAGE__)
[![Total Downloads](https://img.shields.io/packagist/dt/__VENDOR__/__PACKAGE__.svg?style=flat-square)](https://packagist.org/packages/__VENDOR__/__PACKAGE__)
[![License](https://img.shields.io/packagist/l/__VENDOR__/__PACKAGE__.svg?style=flat-square)](LICENSE)

__DESCRIPTION__

A Composer-distributed [boost](https://github.com/sandermuller/boost-core) catalog: pure-Markdown agent
skills and guidelines, no runtime code.

## Install

```bash
composer require --dev __VENDOR__/__PACKAGE__
```

Allowlist it and sync with a boost engine
([`sandermuller/boost-core`](https://github.com/sandermuller/boost-core) or
[`laravel/boost`](https://github.com/laravel/boost)):

```php
// boost.php or .config/boost.php
->withAllowedVendors(['__VENDOR__/__PACKAGE__'])
```

```bash
vendor/bin/boost sync
```

The skills and guidelines under `resources/boost/` fan out into each configured agent's directory
(Claude Code, Codex, Cursor, …).

## License

MIT — see [LICENSE](LICENSE).
