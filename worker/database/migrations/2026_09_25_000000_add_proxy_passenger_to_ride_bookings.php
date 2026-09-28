<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('ride_bookings', function (Blueprint $table): void {
            $table->string('passenger_name', 120)->nullable()->after('passenger_count');
            $table->string('passenger_phone', 30)->nullable()->after('passenger_name');
        });
    }

    public function down(): void
    {
        Schema::table('ride_bookings', function (Blueprint $table): void {
            $table->dropColumn(['passenger_name', 'passenger_phone']);
        });
    }
};
