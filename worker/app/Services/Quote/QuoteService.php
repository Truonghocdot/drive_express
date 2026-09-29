<?php

namespace App\Services\Quote;

use App\Contracts\Maps\MapProvider;
use App\Data\Maps\Coordinates;
use App\Data\Maps\RouteResult;
use App\Enums\BookingType;
use App\Enums\QuoteStatus;
use App\Enums\ServiceType;
use App\Models\Quote;
use App\Models\SystemSetting;
use App\Models\User;
use App\Models\VehicleType;
use App\Services\Pricing\PricingService;
use App\Services\Pricing\VoucherPreviewService;
use Carbon\CarbonImmutable;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class QuoteService
{
    public function __construct(
        private readonly MapProvider $mapProvider,
        private readonly PricingService $pricingService,
        private readonly VoucherPreviewService $voucherPreviewService,
    ) {}

    /** @param array<string, mixed> $data */
    public function create(User $user, array $data): Quote
    {
        $serviceType = ServiceType::from((string) $data['service_type']);
        $bookingType = BookingType::from((string) $data['booking_type']);
        $vehicleType = VehicleType::query()
            ->where('public_id', $data['vehicle_type_id'])
            ->where('is_active', true)
            ->firstOrFail();
        $this->validateServiceVehicle($serviceType, $bookingType, $vehicleType);
        $pickup = $this->coordinates($data['pickup']);
        $dropoff = isset($data['dropoff']) ? $this->coordinates($data['dropoff']) : null;
        /** @var array<string, mixed> $servicePayload */
        $servicePayload = $data['service_payload'];

        $this->validateVehicleCapacity($serviceType, $vehicleType, $servicePayload);
        $durationHours = $serviceType === ServiceType::Hourly
            ? (int) ($servicePayload['duration_hours'] ?? 0)
            : null;
        $route = $serviceType === ServiceType::Hourly
            ? new RouteResult('hourly', 0, ($durationHours ?? 0) * 3_600, null)
            : $this->mapProvider->route($pickup, $dropoff, $vehicleType->unique_key);
        $pricingRule = $this->pricingService->currentRule($serviceType, $vehicleType);
        if ($serviceType === ServiceType::Hourly) {
            $minimum = $pricingRule->minimum_duration_hours ?? 1;
            $maximum = $pricingRule->maximum_duration_hours ?? 12;
            if (($durationHours ?? 0) < $minimum || ($durationHours ?? 0) > $maximum) {
                throw ValidationException::withMessages([
                    'service_payload.duration_hours' => ["Thời lượng phải từ {$minimum} đến {$maximum} giờ."],
                ]);
            }
            if ($pricingRule->hourly_rate === null) {
                throw ValidationException::withMessages([
                    'vehicle_type_id' => ['Chưa cấu hình giá thuê theo giờ cho loại xe này.'],
                ]);
            }
        }
        $subtotal = $serviceType === ServiceType::Hourly
            ? $this->pricingService->calculateHourly($pricingRule, $durationHours ?? 0)
            : $this->pricingService->calculate($pricingRule, $route->distanceMeters);
        $voucherPreview = $this->voucherPreviewService->preview(
            isset($data['voucher_code']) ? (string) $data['voucher_code'] : null,
            $user,
            $serviceType,
            $subtotal->grossFare,
        );
        $pricing = $serviceType === ServiceType::Hourly
            ? $this->pricingService->calculateHourly(
                $pricingRule,
                $durationHours ?? 0,
                $voucherPreview['discount'],
            )
            : $this->pricingService->calculate(
                $pricingRule,
                $route->distanceMeters,
                $voucherPreview['discount'],
            );

        if ($voucherPreview['voucher'] !== null) {
            $servicePayload['voucher'] = [
                'id' => $voucherPreview['voucher']->public_id,
                'code' => $voucherPreview['voucher']->code,
            ];
        }

        $routeSnapshot = $route->toArray();

        $quote = Quote::query()->create([
            'requested_by' => $user->id,
            'service_type' => $serviceType,
            'vehicle_type_id' => $vehicleType->id,
            'pricing_rule_id' => $pricingRule->id,
            'booking_type' => $bookingType,
            'scheduled_at' => $bookingType === BookingType::Scheduled
                ? CarbonImmutable::parse((string) $data['scheduled_at'])
                : null,
            'pickup_snapshot' => $this->locationSnapshot($data['pickup']),
            'dropoff_snapshot' => isset($data['dropoff']) ? $this->locationSnapshot($data['dropoff']) : null,
            'service_payload' => $servicePayload,
            'route_snapshot' => $routeSnapshot,
            'distance_meters' => $route->distanceMeters,
            'duration_seconds' => $route->durationSeconds,
            ...$pricing->toArray(),
            'status' => QuoteStatus::Active,
            'expires_at' => now()->addSeconds($this->quoteTtlSeconds()),
        ]);

        return $quote->load(['vehicleType', 'pricingRule']);
    }

    /** @return Collection<int, Quote> */
    public function createBatch(User $user, array $data): Collection
    {
        $vehicleTypes = VehicleType::query()
            ->whereIn('public_id', $data['vehicle_type_ids'])
            ->where('is_active', true)
            ->get();

        if ($vehicleTypes->count() !== 2
            || $vehicleTypes->pluck('unique_key')->sort()->values()->all() !== ['CAR_4_SEAT', 'MOTORBIKE']) {
            throw ValidationException::withMessages([
                'vehicle_type_ids' => ['Báo giá chuyến xe phải gồm xe máy và ô tô 4 chỗ.'],
            ]);
        }

        return DB::transaction(function () use ($user, $data, $vehicleTypes): Collection {
            return $vehicleTypes->map(function (VehicleType $vehicleType) use ($user, $data): Quote {
                return $this->create($user, [
                    ...$data,
                    'vehicle_type_id' => $vehicleType->public_id,
                    'service_type' => ServiceType::Drive->value,
                ]);
            })->values();
        });
    }

    private function coordinates(mixed $location): Coordinates
    {
        /** @var array<string, mixed> $location */
        return new Coordinates(
            latitude: (float) $location['latitude'],
            longitude: (float) $location['longitude'],
        );
    }

    private function validateServiceVehicle(
        ServiceType $serviceType,
        BookingType $bookingType,
        VehicleType $vehicleType,
    ): void {
        if ($serviceType === ServiceType::Delivery && $vehicleType->unique_key !== 'MOTORBIKE') {
            throw ValidationException::withMessages([
                'vehicle_type_id' => ['Giao hàng chỉ hỗ trợ xe máy.'],
            ]);
        }

        if ($serviceType === ServiceType::Delivery && $bookingType === BookingType::Scheduled) {
            throw ValidationException::withMessages([
                'booking_type' => ['Giao hàng hiện chỉ hỗ trợ đặt ngay.'],
            ]);
        }

        if (in_array($serviceType, [ServiceType::Drive, ServiceType::Hourly], true)
            && ! in_array($vehicleType->unique_key, ['MOTORBIKE', 'CAR_4_SEAT'], true)) {
            throw ValidationException::withMessages([
                'vehicle_type_id' => ['Chuyến xe chỉ hỗ trợ xe máy hoặc ô tô 4 chỗ.'],
            ]);
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function locationSnapshot(mixed $location): ?array
    {
        if ($location === null) return null;
        /** @var array<string, mixed> $location */
        return array_filter([
            'address' => (string) $location['address'],
            'latitude' => (float) $location['latitude'],
            'longitude' => (float) $location['longitude'],
            'note' => isset($location['note']) ? (string) $location['note'] : null,
        ], fn (mixed $value): bool => $value !== null);
    }

    /** @param array<string, mixed> $payload */
    private function validateVehicleCapacity(
        ServiceType $serviceType,
        VehicleType $vehicleType,
        array $payload,
    ): void {
        $errors = [];

        if ($serviceType === ServiceType::Drive
            && $vehicleType->passenger_capacity !== null
            && (int) $payload['passenger_count'] > $vehicleType->passenger_capacity) {
            $errors['service_payload.passenger_count'][] = 'Số hành khách vượt quá sức chứa của loại xe.';
        }

        if ($serviceType === ServiceType::Delivery) {
            $limits = [
                'weight_kg' => $vehicleType->max_weight_kg,
                'length_cm' => $vehicleType->max_length_cm,
                'width_cm' => $vehicleType->max_width_cm,
                'height_cm' => $vehicleType->max_height_cm,
            ];

            foreach ($limits as $field => $limit) {
                if ($limit !== null && isset($payload[$field]) && (float) $payload[$field] > $limit) {
                    $errors["service_payload.{$field}"][] = 'Giá trị vượt quá giới hạn của loại xe này.';
                }
            }
        }

        if ($errors !== []) {
            throw ValidationException::withMessages($errors);
        }
    }

    private function quoteTtlSeconds(): int
    {
        $setting = SystemSetting::query()
            ->where('key', 'pricing.quote_ttl_seconds')
            ->first();
        $configuredTtl = $setting !== null
            ? $setting->value
            : config('pricing.quote_ttl_seconds', 300);
        $ttl = is_numeric($configuredTtl) ? (int) $configuredTtl : 300;

        return max(60, min($ttl, 3_600));
    }
}
