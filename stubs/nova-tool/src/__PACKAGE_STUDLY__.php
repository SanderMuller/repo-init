<?php declare(strict_types=1);

namespace __NAMESPACE__;

use Laravel\Nova\Tool;

final class __PACKAGE_STUDLY__ extends Tool
{
    public function boot(): void
    {
        // Register tool assets here:
        // Nova::script('__PACKAGE__', __DIR__ . '/../dist/js/tool.js');
    }

    public function menu(\Illuminate\Http\Request $request): \Laravel\Nova\Menu\MenuSection
    {
        return \Laravel\Nova\Menu\MenuSection::make('__PACKAGE_STUDLY__')
            ->path('/__PACKAGE__')
            ->icon('chart-bar');
    }
}
