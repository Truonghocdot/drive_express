<?php

use App\Enums\DriverAvailabilityStatus;
use App\Enums\DriverReviewStatus;
use App\Enums\RoleKey;
use App\Models\DriverProfile;
use App\Models\Role;
use App\Models\User;
use App\Models\UserDevice;
use App\Models\UserNotification;
use Database\Seeders\RoleSeeder;
use Laravel\Sanctum\Sanctum;

beforeEach(function () {
    $this->seed(RoleSeeder::class);
});

test('returns active push tokens for the realtime service', function () {
    config()->set('services.realtime.internal_token', 'test-realtime-secret');
    $user = User::factory()->create();
    $notification = UserNotification::query()->create([
        'user_id' => $user->id,
        'type' => 'CHAT_MESSAGE_RECEIVED',
        'channel' => 'IN_APP',
        'data' => ['conversation_id' => 'conversation-1'],
        'status' => 'SENT',
        'sent_at' => now(),
    ]);
    $activeDevice = UserDevice::query()->create([
        'user_id' => $user->id,
        'device_id' => 'active-device',
        'app_type' => 'CUSTOMER_APP',
        'platform' => 'ANDROID',
        'push_token' => 'active-token',
        'last_seen_at' => now(),
    ]);
    UserDevice::query()->create([
        'user_id' => $user->id,
        'device_id' => 'revoked-device',
        'app_type' => 'CUSTOMER_APP',
        'platform' => 'ANDROID',
        'push_token' => 'revoked-token',
        'revoked_at' => now(),
    ]);

    $this->withHeader('X-Internal-Service-Token', 'test-realtime-secret')
        ->getJson('/api/v1/internal/notifications/'.$notification->id.'/dispatch')
        ->assertOk()
        ->assertJsonPath('data.id', $notification->id)
        ->assertJsonPath('data.user_id', $user->public_id)
        ->assertJsonPath('data.devices.0.app_type', 'CUSTOMER_APP')
        ->assertJsonPath('data.devices.0.tokens', ['active-token']);

    expect($activeDevice->fresh()->revoked_at)->toBeNull();
});

test('limits a targeted notification to its selected app type', function () {
    config()->set('services.realtime.internal_token', 'test-realtime-secret');
    $user = User::factory()->create();
    $notification = UserNotification::query()->create([
        'user_id' => $user->id,
        'type' => 'MARKETING_BROADCAST',
        'channel' => 'IN_APP',
        'data' => [
            'title' => 'Customer offer',
            'body' => 'A customer-only offer.',
            'target_app_type' => 'CUSTOMER_APP',
        ],
        'status' => 'SENT',
        'sent_at' => now(),
    ]);
    UserDevice::query()->create([
        'user_id' => $user->id,
        'device_id' => 'customer-device',
        'app_type' => 'CUSTOMER_APP',
        'platform' => 'ANDROID',
        'push_token' => 'customer-token',
    ]);
    UserDevice::query()->create([
        'user_id' => $user->id,
        'device_id' => 'driver-device',
        'app_type' => 'DRIVER_APP',
        'platform' => 'ANDROID',
        'push_token' => 'driver-token',
    ]);

    $this->withHeader('X-Internal-Service-Token', 'test-realtime-secret')
        ->getJson('/api/v1/internal/notifications/'.$notification->id.'/dispatch')
        ->assertOk()
        ->assertJsonPath('data.devices.0.app_type', 'CUSTOMER_APP')
        ->assertJsonPath('data.devices.0.tokens', ['customer-token']);
});

test('rejects notification dispatch without the internal service secret', function () {
    config()->set('services.realtime.internal_token', 'test-realtime-secret');
    $notification = UserNotification::query()->create([
        'user_id' => User::factory()->create()->id,
        'type' => 'TEST',
        'channel' => 'IN_APP',
        'data' => [],
        'status' => 'SENT',
        'sent_at' => now(),
    ]);

    $this->getJson('/api/v1/internal/notifications/'.$notification->id.'/dispatch')
        ->assertUnauthorized();
});

test('revokes an invalid push token', function () {
    config()->set('services.realtime.internal_token', 'test-realtime-secret');
    $device = UserDevice::query()->create([
        'user_id' => User::factory()->create()->id,
        'device_id' => 'device-1',
        'app_type' => 'DRIVER_APP',
        'platform' => 'ANDROID',
        'push_token' => 'invalid-token',
    ]);

    $this->withHeader('X-Internal-Service-Token', 'test-realtime-secret')
        ->postJson('/api/v1/internal/devices/revoke-push-token', ['push_token' => 'invalid-token'])
        ->assertOk()
        ->assertJsonPath('data.revoked', true);

    expect($device->fresh()->revoked_at)->not->toBeNull();
});

test('moves an approved driver token from the onboarding app type', function () {
    $driver = User::factory()->create();
    $driver->roles()->attach(
        Role::query()->where('key', RoleKey::Driver->value)->value('id'),
        ['granted_at' => now()],
    );
    DriverProfile::query()->create([
        'user_id' => $driver->id,
        'review_status' => DriverReviewStatus::Approved,
        'availability_status' => DriverAvailabilityStatus::Offline,
    ]);
    $oldDevice = UserDevice::query()->create([
        'user_id' => $driver->id,
        'device_id' => 'driver-device',
        'app_type' => 'CUSTOMER_APP',
        'platform' => 'ANDROID',
        'push_token' => 'old-driver-token',
    ]);
    Sanctum::actingAs($driver, ['customer:*']);

    $this->postJson('/api/v1/devices/push-token', [
        'device_id' => 'driver-device',
        'app_type' => 'DRIVER_APP',
        'platform' => 'ANDROID',
        'push_token' => 'driver-token',
    ])->assertOk()
        ->assertJsonPath('data.synced', true);

    $this->assertDatabaseHas('user_devices', [
        'user_id' => $driver->id,
        'device_id' => 'driver-device',
        'app_type' => 'DRIVER_APP',
        'push_token' => 'driver-token',
        'revoked_at' => null,
    ]);
    expect($oldDevice->fresh()->revoked_at)->not->toBeNull();
});
