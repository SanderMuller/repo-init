<?php declare(strict_types=1);

namespace __NAMESPACE__;

use Illuminate\Support\Facades\Event;
use Illuminate\Support\ServiceProvider;
use Laravel\Nova\Events\ServingNova;
use Laravel\Nova\Http\Middleware\Authenticate;
use Laravel\Nova\Nova;

final class __PACKAGE_STUDLY__ServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        $this->app->booted(function (): void {
            $this->routes();
        });

        Event::listen(ServingNova::class, function (): void {
            Nova::script('__PACKAGE__', __DIR__ . '/../dist/js/tool.js');
            Nova::style('__PACKAGE__', __DIR__ . '/../dist/css/tool.css');
        });
    }

    protected function routes(): void
    {
        if ($this->app->routesAreCached()) {
            return;
        }

        Nova::router(['nova', Authenticate::class], '__PACKAGE__')
            ->group(__DIR__ . '/../routes/inertia.php');
    }

    public function register(): void
    {
        //
    }
}
