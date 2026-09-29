<?php

use App\Models\PricingRule;
use App\Models\SystemSetting;
use App\Models\User;
use Database\Seeders\PricingConfigurationSeeder;
use Database\Seeders\RoleSeeder;
use Database\Seeders\VehicleTypeSeeder;

test('pricing configuration seeder is safe to run repeatedly', function () {
    $this->seed([RoleSeeder::class, VehicleTypeSeeder::class]);
    User::factory()->create();

    $this->seed(PricingConfigurationSeeder::class);
    SystemSetting::query()->findOrFail('pricing.rounding_unit')->update(['value' => 500]);
    PricingRule::query()->where('service_type', 'HOURLY')->firstOrFail()->update(['hourly_rate' => 75_000]);
    $this->seed(PricingConfigurationSeeder::class);

    expect(SystemSetting::query()->count())->toBe(4)
        ->and(PricingRule::query()->where('is_active', true)->whereNull('effective_to')->count())->toBe(5)
        ->and(SystemSetting::query()->find('pricing.rounding_unit')->value)->toBe(500)
        ->and(PricingRule::query()->where('service_type', 'HOURLY')->where('hourly_rate', 75_000)->exists())->toBeTrue();
});
