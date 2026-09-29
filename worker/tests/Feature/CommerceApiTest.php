<?php

use App\Enums\DiscountType;
use App\Enums\ServiceType;
use App\Data\Maps\RouteResult;
use App\Models\LoyaltyAccount;
use App\Models\LoyaltyReward;
use App\Models\PricingRule;
use App\Models\SystemSetting;
use App\Models\User;
use App\Models\VehicleType;
use App\Models\Voucher;
use App\Contracts\Maps\MapProvider;
use Laravel\Sanctum\Sanctum;
use Tests\Support\FakeMapProvider;

test('lists active vouchers and hides expired vouchers', function () {
    $user = User::factory()->create();
    Voucher::factory()->create(['name' => 'Active voucher']);
    Voucher::factory()->create([
        'name' => 'Expired voucher',
        'ends_at' => now()->subMinute(),
    ]);
    Sanctum::actingAs($user, ['customer:*']);

    $this->getJson('/api/v1/promotions/vouchers')
        ->assertOk()
        ->assertJsonPath('data.0.name', 'Active voucher')
        ->assertJsonMissing(['name' => 'Expired voucher']);
});

test('redeems a loyalty reward atomically and returns a customer voucher', function () {
    $user = User::factory()->create();
    $account = LoyaltyAccount::query()->create([
        'user_id' => $user->id,
        'points_balance' => 500,
        'lifetime_earned' => 500,
        'tier' => 'BRONZE',
    ]);
    $reward = LoyaltyReward::query()->create([
        'name' => 'Giảm 10K',
        'points_cost' => 300,
        'discount_type' => DiscountType::Fixed,
        'discount_value' => 10_000,
        'valid_days' => 30,
        'created_by' => $user->id,
        'is_active' => true,
    ]);
    Sanctum::actingAs($user, ['customer:*']);

    $response = $this->postJson(
        '/api/v1/loyalty/rewards/'.$reward->public_id.'/redeem',
        [],
        ['Idempotency-Key' => 'reward-redeem-1'],
    )->assertOk();

    expect($response->json('data.account.points_balance'))->toBe(200)
        ->and($response->json('data.voucher.is_owned'))->toBeTrue();
    $this->assertDatabaseHas('vouchers', [
        'owner_user_id' => $user->id,
        'name' => 'Giảm 10K',
    ]);

    $this->postJson(
        '/api/v1/loyalty/rewards/'.$reward->public_id.'/redeem',
        [],
        ['Idempotency-Key' => 'reward-redeem-1'],
    )->assertOk();
    expect(LoyaltyAccount::query()->findOrFail($account->id)->points_balance)->toBe(200);
});

test('creates an hourly quote from pickup and duration without a route lookup', function () {
    $user = User::factory()->create();
    $vehicle = VehicleType::factory()->create([
        'unique_key' => 'MOTORBIKE',
        'passenger_capacity' => 2,
    ]);
    PricingRule::factory()->create([
        'service_type' => ServiceType::Hourly,
        'vehicle_type_id' => $vehicle->id,
        'hourly_rate' => 40_000,
        'minimum_duration_hours' => 1,
        'maximum_duration_hours' => 12,
    ]);
    SystemSetting::query()->create([
        'key' => 'features.hourly_enabled',
        'value' => true,
        'is_public' => true,
    ]);
    $map = new FakeMapProvider(new RouteResult('fake', 1_000, 300, null));
    $this->app->instance(MapProvider::class, $map);
    Sanctum::actingAs($user, ['customer:*']);

    $response = $this->postJson('/api/v1/quotes', [
        'service_type' => 'HOURLY',
        'vehicle_type_id' => $vehicle->public_id,
        'booking_type' => 'NOW',
        'pickup' => ['address' => 'Pickup', 'latitude' => 10.77, 'longitude' => 106.68],
        'service_payload' => ['duration_hours' => 3],
    ])->assertCreated();

    expect($response->json('data.service_type'))->toBe('HOURLY')
        ->and($response->json('data.route.distance_meters'))->toBe(0)
        ->and($response->json('data.route.duration_seconds'))->toBe(10_800)
        ->and((float) $response->json('data.pricing.gross_fare'))->toBe(120_000.0)
        ->and($map->calls)->toBeEmpty();
});
