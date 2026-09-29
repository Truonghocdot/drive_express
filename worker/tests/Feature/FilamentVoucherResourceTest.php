<?php

use App\Enums\DiscountType;
use App\Enums\RoleKey;
use App\Filament\Resources\Vouchers\Pages\CreateVoucher;
use App\Models\Role;
use App\Models\User;
use App\Models\Voucher;
use Database\Seeders\RoleSeeder;
use Filament\Facades\Filament;
use Livewire\Livewire;

function actingAsVoucherAdmin(): User
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

test('generates a unique customer-entered code when creating a campaign voucher', function () {
    actingAsVoucherAdmin();

    Livewire::test(CreateVoucher::class)
        ->fillForm([
            'name' => 'Weekend campaign',
            'discount_type' => DiscountType::Percent->value,
            'discount_value' => 15,
            'minimum_order_amount' => 100_000,
            'max_restore_count' => 1,
            'starts_at' => now(),
            'ends_at' => now()->addDays(7),
            'is_active' => true,
        ])
        ->call('create')
        ->assertHasNoFormErrors();

    $voucher = Voucher::query()->where('name', 'Weekend campaign')->firstOrFail();

    expect($voucher->code)->toMatch('/^DRIVE-[A-Z0-9]{8}$/')
        ->and(Voucher::query()->where('code', $voucher->code)->count())->toBe(1);
});
