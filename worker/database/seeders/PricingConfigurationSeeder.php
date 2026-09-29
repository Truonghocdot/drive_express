<?php

namespace Database\Seeders;

use App\Enums\RoleKey;
use App\Enums\ServiceType;
use App\Models\PricingRule;
use App\Models\SystemSetting;
use App\Models\User;
use App\Models\VehicleType;
use Illuminate\Database\Seeder;

class PricingConfigurationSeeder extends Seeder
{
    public function run(): void
    {
        $actor = User::query()
            ->whereHas('roles', fn ($query) => $query->where('key', RoleKey::Admin->value))
            ->first() ?? User::query()->firstOrFail();

        foreach ([
            'pricing.quote_ttl_seconds' => 300,
            'pricing.rounding_unit' => 1_000,
            'pricing.float_tolerance' => 0.01,
            'features.hourly_enabled' => false,
        ] as $key => $value) {
            SystemSetting::query()->firstOrCreate(
                ['key' => $key],
                ['value' => $value, 'is_public' => false, 'updated_by' => $actor->id],
            );
        }

        $vehicles = VehicleType::query()
            ->whereIn('unique_key', ['MOTORBIKE', 'CAR_4_SEAT'])
            ->get()
            ->keyBy('unique_key');

        $rules = [
            [ServiceType::Delivery, 'MOTORBIKE', 18_000, 5_000, null],
            [ServiceType::Drive, 'MOTORBIKE', 12_000, 5_000, null],
            [ServiceType::Drive, 'CAR_4_SEAT', 30_000, 8_000, null],
            [ServiceType::Hourly, 'MOTORBIKE', 60_000, 0, 60_000],
            [ServiceType::Hourly, 'CAR_4_SEAT', 120_000, 0, 120_000],
        ];

        foreach ($rules as [$serviceType, $vehicleKey, $baseFare, $extraKmFare, $hourlyRate]) {
            $vehicle = $vehicles->get($vehicleKey);

            if ($vehicle === null) {
                continue;
            }

            $rule = PricingRule::query()
                ->where('service_type', $serviceType->value)
                ->where('vehicle_type_id', $vehicle->id)
                ->where('is_active', true)
                ->whereNull('effective_to')
                ->first();

            if ($rule !== null) {
                continue;
            }

            PricingRule::query()->create([
                'service_type' => $serviceType,
                'vehicle_type_id' => $vehicle->id,
                'base_distance_km' => $serviceType === ServiceType::Hourly ? 0 : 3,
                'base_fare' => $baseFare,
                'price_per_extra_km' => $extraKmFare,
                'driver_rate' => 0.88,
                'hourly_rate' => $hourlyRate,
                'minimum_duration_hours' => $serviceType === ServiceType::Hourly ? 1 : null,
                'maximum_duration_hours' => $serviceType === ServiceType::Hourly ? 12 : null,
                'currency' => 'VND',
                'is_active' => true,
                'effective_from' => now(),
                'effective_to' => null,
                'created_by' => $actor->id,
            ]);
        }
    }
}
