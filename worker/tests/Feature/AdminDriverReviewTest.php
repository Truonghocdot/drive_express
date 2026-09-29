<?php

use App\Enums\DriverReviewStatus;
use App\Enums\RoleKey;
use App\Enums\ServiceType;
use App\Models\Role;
use App\Models\User;
use App\Models\VehicleType;
use App\Services\Driver\DriverReviewService;
use Database\Seeders\RoleSeeder;
use Database\Seeders\VehicleTypeSeeder;
use Laravel\Sanctum\Sanctum;
use Tests\Support\DriverApplicationBuilder;

beforeEach(function () {
    $this->seed([RoleSeeder::class, VehicleTypeSeeder::class]);
});

test('approves a submitted driver application through the shared review service', function () {
    $admin = User::factory()->create();
    $adminRoleId = Role::query()->where('key', RoleKey::Admin->value)->value('id');
    $admin->roles()->attach($adminRoleId, ['granted_at' => now()]);
    $driver = User::factory()->create(['password' => 'password123']);
    $vehicleType = VehicleType::query()->where('unique_key', 'MOTORBIKE')->firstOrFail();
    $profile = DriverApplicationBuilder::submitted(
        $driver,
        $vehicleType,
        [ServiceType::Delivery, ServiceType::Drive],
    );

    app(DriverReviewService::class)->approve($profile, $admin);

    expect($profile->fresh()->cod_limit)->toBe((float) config('finance.driver_daily_cod_limit'));

    $driverRoleId = Role::query()->where('key', RoleKey::Driver->value)->value('id');
    $this->assertDatabaseHas('user_roles', [
        'user_id' => $driver->id,
        'role_id' => $driverRoleId,
    ]);
    $this->assertDatabaseHas('wallets', [
        'user_id' => $driver->id,
        'balance' => 0,
    ]);
    $this->assertDatabaseMissing('driver_documents', [
        'driver_profile_id' => $profile->id,
        'status' => 'PENDING',
    ]);
    $this->assertDatabaseMissing('driver_service_capabilities', [
        'driver_profile_id' => $profile->id,
        'is_active' => false,
    ]);

    $this->postJson('/api/v1/auth/login', [
        'phone' => $driver->phone,
        'password' => 'password123',
        'device_id' => 'driver-device-1',
        'app_type' => 'DRIVER_APP',
        'platform' => 'ANDROID',
    ])->assertOk()->assertJsonStructure(['token']);
});

test('repairs the selected vehicle flag before approving a one-vehicle application', function () {
    $admin = User::factory()->create();
    $adminRoleId = Role::query()->where('key', RoleKey::Admin->value)->value('id');
    $admin->roles()->attach($adminRoleId, ['granted_at' => now()]);
    $vehicleType = VehicleType::query()->where('unique_key', 'MOTORBIKE')->firstOrFail();
    $profile = DriverApplicationBuilder::submitted(User::factory()->create(), $vehicleType);
    $profile->vehicles()->update(['is_selected' => false]);

    app(DriverReviewService::class)->approve($profile, $admin);

    expect($profile->fresh()->review_status)->toBe(DriverReviewStatus::Approved)
        ->and($profile->vehicles()->sole()->is_selected)->toBeTrue();
});

test('adds hourly capability to an approved driver with a supported vehicle', function () {
    $admin = User::factory()->create();
    $adminRoleId = Role::query()->where('key', RoleKey::Admin->value)->value('id');
    $admin->roles()->attach($adminRoleId, ['granted_at' => now()]);
    $vehicleType = VehicleType::query()->where('unique_key', 'MOTORBIKE')->firstOrFail();
    $profile = DriverApplicationBuilder::submitted(
        User::factory()->create(),
        $vehicleType,
        [ServiceType::Delivery],
    );
    $review = app(DriverReviewService::class);
    $review->approve($profile, $admin);

    $review->addCapability($profile, $admin, $vehicleType->id, ServiceType::Hourly);

    $this->assertDatabaseHas('driver_service_capabilities', [
        'driver_profile_id' => $profile->id,
        'vehicle_type_id' => $vehicleType->id,
        'service_type' => ServiceType::Hourly->value,
        'is_active' => true,
        'approved_by' => $admin->id,
    ]);
    $this->assertDatabaseHas('audit_logs', ['action' => 'DRIVER_CAPABILITY_ADDED']);
});

test('rejects a submitted application through the shared review service', function () {
    $admin = User::factory()->create();
    $adminRoleId = Role::query()->where('key', RoleKey::Admin->value)->value('id');
    $admin->roles()->attach($adminRoleId, ['granted_at' => now()]);
    $driver = User::factory()->create();
    $profile = DriverApplicationBuilder::submitted(
        $driver,
        VehicleType::query()->where('unique_key', 'MOTORBIKE')->firstOrFail(),
    );

    $reviewed = app(DriverReviewService::class)->reject(
        $profile,
        $admin,
        'DOCUMENT_UNREADABLE',
    );

    expect($reviewed->review_status)->toBe(DriverReviewStatus::Rejected)
        ->and($reviewed->review_reason_code)->toBe('DOCUMENT_UNREADABLE');
});

test('does not expose driver review through REST admin endpoints', function () {
    $admin = User::factory()->create();
    Sanctum::actingAs($admin, ['*']);
    $profile = DriverApplicationBuilder::submitted(
        User::factory()->create(),
        VehicleType::query()->where('unique_key', 'MOTORBIKE')->firstOrFail(),
    );

    $this->getJson('/api/v1/admin/driver-applications')->assertNotFound();
    $this->postJson("/api/v1/admin/driver-applications/{$profile->public_id}/approval")
        ->assertNotFound();
});

test('rejects driver app login before approval', function () {
    $user = User::factory()->create(['password' => 'password123']);

    $this->postJson('/api/v1/auth/login', [
        'phone' => $user->phone,
        'password' => 'password123',
        'device_id' => 'driver-device-1',
        'app_type' => 'DRIVER_APP',
        'platform' => 'ANDROID',
    ])->assertUnprocessable()
        ->assertJsonValidationErrors('app_type');
});

test('suspends an approved driver and blocks driver app login', function () {
    $admin = User::factory()->create();
    $adminRoleId = Role::query()->where('key', RoleKey::Admin->value)->value('id');
    $admin->roles()->attach($adminRoleId, ['granted_at' => now()]);
    $driver = User::factory()->create(['password' => 'password123']);
    $profile = DriverApplicationBuilder::submitted(
        $driver,
        VehicleType::query()->where('unique_key', 'MOTORBIKE')->firstOrFail(),
    );
    $review = app(DriverReviewService::class);
    $review->approve($profile, $admin);
    $review->suspend($profile, $admin, 'SAFETY_REVIEW');

    $this->postJson('/api/v1/auth/login', [
        'phone' => $driver->phone,
        'password' => 'password123',
        'device_id' => 'driver-device-1',
        'app_type' => 'DRIVER_APP',
        'platform' => 'ANDROID',
    ])->assertUnprocessable()
        ->assertJsonValidationErrors('app_type');
});
