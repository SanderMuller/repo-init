<?php declare(strict_types=1);

namespace __NAMESPACE__;

use Illuminate\Http\Request;
use Laravel\Nova\Menu\MenuSection;
use Laravel\Nova\Tool;

final class __PACKAGE_STUDLY__ extends Tool
{
    public function boot(): void
    {
        // Register tool assets here:
        // Nova::script('__PACKAGE__', __DIR__ . '/../dist/js/tool.js');
    }

    public function menu(Request $request): MenuSection
    {
        return MenuSection::make('__PACKAGE_STUDLY__')
            ->path('/__PACKAGE__')
            ->icon('chart-bar');
    }
}
