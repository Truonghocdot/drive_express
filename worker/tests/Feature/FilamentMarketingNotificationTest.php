<?php

use App\Enums\RoleKey;
use App\Filament\Pages\MarketingNotification;
use App\Models\Role;
use App\Models\User;
use App\Models\UserDevice;
use App\Models\UserNotification;
use Database\Seeders\RoleSeeder;
use Filament\Facades\Filament;
use Livewire\Livewire;

function actingAsMarketingAdmin(): User
{
    test()->seed(RoleSeeder::class);
    Filament::setCurrentPanel(Filament::getPanel('admin'));
    $admin = User::factory()->create();
    $admin->roles()->attach(
        Role::query()->where('key', RoleKey::Admin->value)->value('id'),
        ['granted_at' => now()],
    );
    test()->actingAs($admin);

    return $admin;
}

test('sends marketing notifications to the selected app audience', function () {
    actingAsMarketingAdmin();
    $customer = User::factory()->create();
    $driver = User::factory()->create();

    UserDevice::query()->create([
        'user_id' => $customer->id,
        'device_id' => 'customer-device',
        'app_type' => 'CUSTOMER_APP',
        'platform' => 'ANDROID',
        'push_token' => 'customer-token',
        'last_seen_at' => now(),
    ]);
    UserDevice::query()->create([
        'user_id' => $driver->id,
        'device_id' => 'driver-device',
        'app_type' => 'DRIVER_APP',
        'platform' => 'ANDROID',
        'push_token' => 'driver-token',
        'last_seen_at' => now(),
    ]);

    Livewire::test(MarketingNotification::class)
        ->fillForm([
            'audience' => 'customers',
            'title' => 'Ưu đãi cuối tuần',
            'body' => 'Giảm giá cho chuyến đi tiếp theo của bạn.',
        ])
        ->call('send')
        ->assertHasNoFormErrors();

    $notification = UserNotification::query()->where('user_id', $customer->id)->firstOrFail();

    expect(UserNotification::query()->where('type', 'MARKETING_BROADCAST')->count())->toBe(1)
        ->and($notification->data)->toMatchArray([
            'title' => 'Ưu đãi cuối tuần',
            'body' => 'Giảm giá cho chuyến đi tiếp theo của bạn.',
            'target_app_type' => 'CUSTOMER_APP',
        ]);
});
