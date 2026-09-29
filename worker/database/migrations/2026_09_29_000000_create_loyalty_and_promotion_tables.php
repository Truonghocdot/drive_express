<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('vouchers', function (Blueprint $table): void {
            $table->foreignId('owner_user_id')
                ->nullable()
                ->after('created_by')
                ->constrained('users')
                ->nullOnDelete();
            $table->index(['owner_user_id', 'is_active', 'ends_at']);
        });

        Schema::create('loyalty_accounts', function (Blueprint $table): void {
            $table->id();
            $table->uuid('public_id')->unique();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('points_balance')->default(0);
            $table->unsignedBigInteger('lifetime_earned')->default(0);
            $table->unsignedBigInteger('lifetime_redeemed')->default(0);
            $table->string('tier', 30)->default('BRONZE');
            $table->timestampsTz();
        });

        Schema::create('loyalty_rewards', function (Blueprint $table): void {
            $table->id();
            $table->uuid('public_id')->unique();
            $table->string('name', 150);
            $table->unsignedInteger('points_cost');
            $table->string('discount_type', 20);
            $table->double('discount_value');
            $table->double('max_discount_amount')->nullable();
            $table->string('service_scope', 20)->nullable();
            $table->double('minimum_order_amount')->default(0);
            $table->unsignedInteger('valid_days')->default(30);
            $table->unsignedInteger('stock')->nullable();
            $table->boolean('is_active')->default(true)->index();
            $table->foreignId('created_by')->constrained('users')->restrictOnDelete();
            $table->timestampsTz();
        });

        Schema::create('loyalty_transactions', function (Blueprint $table): void {
            $table->id();
            $table->uuid('public_id')->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type', 20);
            $table->bigInteger('points');
            $table->unsignedBigInteger('balance_after');
            $table->string('idempotency_key', 191)->unique();
            $table->string('reference_type', 80)->nullable();
            $table->unsignedBigInteger('reference_id')->nullable();
            $table->jsonb('metadata')->nullable();
            $table->timestampTz('created_at');
            $table->index(['user_id', 'created_at']);
            $table->index(['reference_type', 'reference_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('loyalty_transactions');
        Schema::dropIfExists('loyalty_rewards');
        Schema::dropIfExists('loyalty_accounts');
        Schema::table('vouchers', function (Blueprint $table): void {
            $table->dropForeign(['owner_user_id']);
            $table->dropIndex(['owner_user_id', 'is_active', 'ends_at']);
            $table->dropColumn('owner_user_id');
        });
    }
};
