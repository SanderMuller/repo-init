<?php declare(strict_types=1);

namespace __NAMESPACE__;

use Illuminate\Support\ServiceProvider;

final class __PACKAGE_STUDLY__ServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->mergeConfigFrom(__DIR__ . '/../config/__PACKAGE__.php', '__PACKAGE__');
    }

    public function boot(): void
    {
        if ($this->app->runningInConsole()) {
            $this->publishes([
                __DIR__ . '/../config/__PACKAGE__.php' => config_path('__PACKAGE__.php'),
            ], '__PACKAGE__-config');
        }
    }
}
