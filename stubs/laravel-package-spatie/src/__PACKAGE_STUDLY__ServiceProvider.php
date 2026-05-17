<?php declare(strict_types=1);

namespace __NAMESPACE__;

use Spatie\LaravelPackageTools\Package;
use Spatie\LaravelPackageTools\PackageServiceProvider;

final class __PACKAGE_STUDLY__ServiceProvider extends PackageServiceProvider
{
    #[\Override]
    public function configurePackage(Package $package): void
    {
        $package
            ->name('__PACKAGE__')
            ->hasConfigFile();
        // ->hasViews()
        // ->hasMigration('create_yourtable_table')   // <- replace with your actual migration name
        // ->hasCommand(YourCommand::class);
    }
}
