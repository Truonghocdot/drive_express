<?php

use App\Enums\AssignmentStatus;
use App\Enums\DriverOfferStatus;
use App\Enums\ServiceType;
use App\Models\DriverOffer;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Laravel\Sanctum\Sanctum;
use Tests\Support\ExecutionScenarioBuilder;

beforeEach(function () {
    $this->seed(RoleSeeder::class);
});

test('customer history contains only service requests created by the user', function () {
    $own = ExecutionScenarioBuilder::create(ServiceType::Delivery);
    ExecutionScenarioBuilder::create(ServiceType::Drive);
    Sanctum::actingAs($own['customer'], ['customer:*']);

    $this->getJson('/api/v1/service-requests')
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.id', $own['request']->public_id)
        ->assertJsonFragment(['address' => 'PICKUP'])
        ->assertJsonFragment(['address' => 'DROPOFF']);
});

test('driver history contains only closed assignments belonging to the driver', function () {
    $own = ExecutionScenarioBuilder::create(ServiceType::Drive);
    $other = ExecutionScenarioBuilder::create(ServiceType::Delivery);
    $own['assignment']->forceFill([
        'status' => AssignmentStatus::Completed,
        'closed_at' => now(),
    ])->save();
    $other['assignment']->forceFill([
        'status' => AssignmentStatus::Completed,
        'closed_at' => now(),
    ])->save();
    Sanctum::actingAs($own['driver'], ['driver:*']);

    $this->getJson('/api/v1/driver/history')
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.id', $own['request']->public_id)
        ->assertJsonPath('meta.summary.completed_count', 1)
        ->assertJsonPath('meta.filters.service_type', null);
});

test('driver history supports service type and search filters', function () {
    $scenario = ExecutionScenarioBuilder::create(ServiceType::Drive);
    $scenario['assignment']->forceFill([
        'status' => AssignmentStatus::Completed,
        'closed_at' => now(),
    ])->save();
    Sanctum::actingAs($scenario['driver'], ['driver:*']);

    $this->getJson('/api/v1/driver/history?service_type=DELIVERY&q=missing')
        ->assertOk()
        ->assertJsonCount(0, 'data')
        ->assertJsonPath('meta.filters.service_type', 'DELIVERY');
});

test('driver application exposes performance metrics', function () {
    $scenario = ExecutionScenarioBuilder::create(ServiceType::Drive);
    $scenario['profile']->forceFill([
        'offer_count' => 4,
        'accepted_offer_count' => 3,
        'acceptance_rate' => 0.75,
    ])->save();
    $scenario['assignment']->forceFill([
        'status' => AssignmentStatus::Completed,
        'closed_at' => now(),
    ])->save();
    Sanctum::actingAs($scenario['driver'], ['driver:*']);

    $this->getJson('/api/v1/driver/application')
        ->assertOk()
        ->assertJsonPath('data.performance.acceptance_rate', 75)
        ->assertJsonPath('data.performance.completion_rate', 100)
        ->assertJsonPath('data.performance.completed_count', 1);
});

test('driver history requires the driver role', function () {
    Sanctum::actingAs(User::factory()->create(), ['customer:*']);

    $this->getJson('/api/v1/driver/history')->assertForbidden();
});

test('closed assignments are removed from the active driver offer feed', function () {
    $scenario = ExecutionScenarioBuilder::create(ServiceType::Drive);
    $offer = DriverOffer::factory()->create([
        'service_request_id' => $scenario['request']->id,
        'driver_profile_id' => $scenario['profile']->id,
        'status' => DriverOfferStatus::Accepted,
    ]);
    $scenario['assignment']->forceFill([
        'accepted_offer_id' => $offer->id,
        'status' => AssignmentStatus::Completed,
        'closed_at' => now(),
    ])->save();
    Sanctum::actingAs($scenario['driver'], ['driver:*']);

    $this->getJson('/api/v1/driver/offers')
        ->assertOk()
        ->assertJsonCount(0, 'data');
});
