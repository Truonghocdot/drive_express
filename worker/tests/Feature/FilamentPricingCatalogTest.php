<?php

use App\Enums\RoleKey;
use App\Enums\ServiceType;
use App\Filament\Pages\SystemConfiguration;
use App\Filament\Resources\PricingRules\Pages\CreatePricingRule;
use App\Filament\Resources\PricingRules\PricingRuleResource;
use App\Filament\Resources\SystemSettings\Pages\CreateSystemSetting;
use App\Models\PricingRule;
use App\Models\Quote;
use App\Models\Role;
use App\Models\SystemSetting;
use App\Models\User;
use App\Models\VehicleType;
use App\Services\Admin\PricingCatalogAdminService;
use Database\Seeders\RoleSeeder;
use Database\Seeders\VehicleTypeSeeder;
use Filament\Facades\Filament;
use Illuminate\Validation\ValidationException;
use Livewire\Livewire;

function actingAsPricingAdmin(): User
{
    test()->seed([RoleSeeder::class, VehicleTypeSeeder::class]);
    Filament::setCurrentPanel(Filament::getPanel('admin'));
    $admin = User::factory()->create();
    $adminRoleId = Role::query()->where('key', RoleKey::Admin->value)->value('id');
    $admin->roles()->attach($adminRoleId, ['granted_at' => now()]);
    test()->actingAs($admin);

    return $admin;
}

/** @return array<string, mixed> */
function pricingRuleFormData(VehicleType $vehicleType, string $effectiveFrom): array
{
    return [
        'service_type' => ServiceType::Delivery->value,
        'vehicle_type_id' => $vehicleType->id,
        'base_distance_km' => 3,
        'base_fare' => 18_000,
        'price_per_extra_km' => 5_000,
        'driver_rate' => 0.88,
        'currency' => 'VND',
        'effective_from' => $effectiveFrom,
        'is_active' => true,
    ];
}

test('creates and versions pricing rules through Filament with audit logs', function () {
    actingAsPricingAdmin();
    $vehicle = VehicleType::query()->where('unique_key', 'MOTORBIKE')->firstOrFail();
    $firstEffectiveFrom = now()->subMinute();

    Livewire::test(CreatePricingRule::class)
        ->fillForm(pricingRuleFormData($vehicle, $firstEffectiveFrom->toDateTimeString()))
        ->call('create')
        ->assertHasNoFormErrors();

    $first = PricingRule::query()->firstOrFail();
    $secondEffectiveFrom = now()->addHour();
    $secondData = pricingRuleFormData($vehicle, $secondEffectiveFrom->toDateTimeString());
    $secondData['base_fare'] = 20_000;

    Livewire::test(CreatePricingRule::class)
        ->fillForm($secondData)
        ->call('create')
        ->assertHasNoFormErrors();

    expect($first->fresh()?->effective_to?->equalTo($secondEffectiveFrom->startOfSecond()))->toBeTrue()
        ->and(PricingRule::query()->whereNull('effective_to')->value('base_fare'))->toBe(20_000.0);
    $this->assertDatabaseCount('pricing_rules', 2);
    $this->assertDatabaseCount('audit_logs', 2);
    $this->assertDatabaseHas('audit_logs', ['action' => 'PRICING_RULE_CREATED']);
});

test('prevents editing a pricing rule after a quote uses it', function () {
    actingAsPricingAdmin();
    $vehicle = VehicleType::query()->where('unique_key', 'MOTORBIKE')->firstOrFail();
    $rule = PricingRule::factory()->create([
        'service_type' => ServiceType::Delivery,
        'vehicle_type_id' => $vehicle->id,
        'effective_from' => now()->subDay(),
    ]);
    Quote::factory()->forPricingRule($rule)->create();

    expect(PricingRuleResource::canEdit($rule))->toBeFalse();
    $this->get(PricingRuleResource::getUrl('edit', ['record' => $rule]))
        ->assertForbidden();
});

test('creates a numeric pricing system setting through its Filament tab', function () {
    actingAsPricingAdmin();

    Livewire::test(CreateSystemSetting::class)
        ->fillForm([
            'key' => 'pricing.rounding_unit',
            'value' => '1000',
            'is_public' => false,
        ])
        ->call('create')
        ->assertHasNoFormErrors();

    $this->assertDatabaseHas('system_settings', [
        'key' => 'pricing.rounding_unit',
        'value' => 1_000,
    ]);
    $this->assertDatabaseHas('audit_logs', ['action' => 'SYSTEM_SETTING_CREATED']);
});

test('saves all pricing settings from the standalone configuration page', function () {
    actingAsPricingAdmin();
    $vehicle = VehicleType::query()->where('unique_key', 'MOTORBIKE')->firstOrFail();
    PricingRule::factory()->create([
        'service_type' => ServiceType::Hourly,
        'vehicle_type_id' => $vehicle->id,
        'hourly_rate' => 60_000,
        'minimum_duration_hours' => 1,
        'maximum_duration_hours' => 12,
    ]);

    Livewire::test(SystemConfiguration::class)
        ->fillForm([
            'quote_ttl_seconds' => 600,
            'rounding_unit' => 500,
            'float_tolerance' => 0.05,
            'vietqr_bank_code' => 'vietinbank',
            'vietqr_account_number' => '113366668888',
            'vietqr_account_name' => 'DRIVE PAYMENTS',
            'hourly_enabled' => true,
        ])
        ->call('save')
        ->assertHasNoFormErrors();

    $this->assertDatabaseHas('system_settings', ['key' => 'pricing.quote_ttl_seconds', 'value' => 600]);
    $this->assertDatabaseHas('system_settings', ['key' => 'pricing.rounding_unit', 'value' => 500]);
    $this->assertDatabaseHas('system_settings', ['key' => 'pricing.float_tolerance', 'value' => 0.05]);
    $this->assertDatabaseHas('system_settings', [
        'key' => 'finance.vietqr.bank_code',
        'value' => '"vietinbank"',
    ]);
    $this->assertDatabaseHas('system_settings', [
        'key' => 'finance.vietqr.account_number',
        'value' => '"113366668888"',
    ]);
    $this->assertDatabaseHas('system_settings', [
        'key' => 'finance.vietqr.account_name',
        'value' => '"DRIVE PAYMENTS"',
    ]);
    expect(SystemSetting::query()->findOrFail('features.hourly_enabled')->value)->toBeTrue();
});

test('requires hourly pricing before enabling hourly service', function () {
    $admin = actingAsPricingAdmin();

    expect(fn () => app(PricingCatalogAdminService::class)->saveSystemSettings([
        'quote_ttl_seconds' => 300,
        'rounding_unit' => 1_000,
        'float_tolerance' => 0.01,
        'vietqr_bank_code' => 'MB',
        'vietqr_account_number' => '0123456789',
        'vietqr_account_name' => 'DRIVE PAYMENTS',
        'hourly_enabled' => true,
    ], $admin))->toThrow(ValidationException::class);
});
