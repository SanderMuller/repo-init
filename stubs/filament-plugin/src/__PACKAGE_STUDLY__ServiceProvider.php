<?php declare(strict_types=1);

namespace __NAMESPACE__;

use Filament\Contracts\Plugin;
use Filament\Panel;
use Illuminate\Support\ServiceProvider;

final class __PACKAGE_STUDLY__ServiceProvider extends ServiceProvider implements Plugin
{
    public function getId(): string
    {
        return '__PACKAGE__';
    }

    public function register(?Panel $panel = null): void
    {
        if ($panel !== null) {
            // Plugin registration on a Filament panel — register resources, pages, widgets here:
            // $panel->resources([...]);
            // $panel->pages([...]);
            return;
        }

        // ServiceProvider register() — bind container services here:
        $this->mergeConfigFrom(__DIR__ . '/../config/__PACKAGE__.php', '__PACKAGE__');
    }

    public function boot(?Panel $panel = null): void
    {
        if ($panel !== null) {
            // Plugin boot — runs after panel is fully resolved.
            return;
        }

        // ServiceProvider boot() — publish assets, register views:
        if ($this->app->runningInConsole()) {
            $this->publishes([
                __DIR__ . '/../config/__PACKAGE__.php' => config_path('__PACKAGE__.php'),
            ], '__PACKAGE__-config');

            // $this->loadViewsFrom(__DIR__ . '/../resources/views', '__PACKAGE__');
            // $this->publishes([
            //     __DIR__ . '/../resources/views' => resource_path('views/vendor/__PACKAGE__'),
            // ], '__PACKAGE__-views');
        }
    }

    public static function make(): static
    {
        /** @phpstan-ignore-next-line — static used to support `Filament\Panel::plugin(YourPlugin::make())` consumer call */
        return new self();
    }
}
