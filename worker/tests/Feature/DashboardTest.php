<?php

use App\Enums\RoleKey;
use App\Models\Role;
use App\Models\User;
use Database\Seeders\RoleSeeder;

test('the removed starter dashboard is not exposed to guests', function () {
    $this->get('/dashboard')->assertNotFound();
});

test('the removed starter dashboard is not exposed to authenticated users', function () {
    $user = User::factory()->create();
    $this->actingAs($user);

    $this->get('/dashboard')->assertNotFound();
});

test('admins can open the operations dashboard', function () {
    $this->seed(RoleSeeder::class);
    $admin = User::factory()->create();
    $admin->roles()->attach(Role::query()->where('key', RoleKey::Admin->value)->value('id'), [
        'granted_at' => now(),
    ]);

    $this->actingAs($admin)
        ->get('/admin/dashboard')
        ->assertOk()
        ->assertSee('Đơn gần đây');
});
