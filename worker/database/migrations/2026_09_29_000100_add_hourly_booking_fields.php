<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('pricing_rules', function (Blueprint $table): void {
            $table->double('hourly_rate')->nullable()->after('driver_rate');
            $table->unsignedSmallInteger('minimum_duration_hours')->nullable()->after('hourly_rate');
            $table->unsignedSmallInteger('maximum_duration_hours')->nullable()->after('minimum_duration_hours');
        });
        Schema::table('ride_bookings', function (Blueprint $table): void {
            $table->unsignedSmallInteger('duration_hours')->nullable()->after('passenger_count');
        });
        Schema::table('quotes', function (Blueprint $table): void {
            $table->jsonb('dropoff_snapshot')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('ride_bookings', fn (Blueprint $table) => $table->dropColumn('duration_hours'));
        Schema::table('pricing_rules', function (Blueprint $table): void {
            $table->dropColumn(['hourly_rate', 'minimum_duration_hours', 'maximum_duration_hours']);
        });
    }
};
