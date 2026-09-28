<?php

use App\Models\User;
use App\Models\UserDevice;
use App\Models\UserNotification;

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
