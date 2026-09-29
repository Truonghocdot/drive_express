<?php

namespace App\Filament\Pages;

use App\Enums\DriverAvailabilityStatus;
use App\Enums\DriverReviewStatus;
use App\Enums\RoleKey;
use App\Enums\ServiceRequestStatus;
use App\Enums\ServiceType;
use App\Models\DriverProfile;
use App\Models\PricingRule;
use App\Models\ServiceRequest;
use App\Models\SystemSetting;
use App\Models\User;
use Filament\Pages\Page;
use Illuminate\Support\Collection;
use UnitEnum;

class Dashboard extends Page
{
    protected static string|UnitEnum|null $navigationGroup = null;

    protected static ?string $navigationLabel = 'Tổng quan';

    protected static ?int $navigationSort = -1;

    protected string $view = 'filament.pages.dashboard';

    public static function canAccess(): bool
    {
        $user = auth()->user();

        return $user instanceof User && $user->hasRole(RoleKey::Admin);
    }

    /** @return array<string, mixed> */
    protected function getViewData(): array
    {
        $today = now()->startOfDay();
        $terminalStatuses = [
            ServiceRequestStatus::Completed->value,
            ServiceRequestStatus::Cancelled->value,
            ServiceRequestStatus::DeliveryFailed->value,
            ServiceRequestStatus::Returned->value,
        ];

        /** @var Collection<int, ServiceRequest> $recentRequests */
        $recentRequests = ServiceRequest::query()
            ->with(['creator', 'vehicleType'])
            ->latest('created_at')
            ->limit(8)
            ->get();

        return [
            'stats' => [
                ['label' => 'Đơn hôm nay', 'value' => ServiceRequest::query()->where('created_at', '>=', $today)->count()],
                ['label' => 'Đang xử lý', 'value' => ServiceRequest::query()->whereNotIn('status', $terminalStatuses)->count()],
                ['label' => 'Hoàn thành hôm nay', 'value' => ServiceRequest::query()->where('status', ServiceRequestStatus::Completed->value)->where('completed_at', '>=', $today)->count()],
                ['label' => 'Tài xế đang trực', 'value' => DriverProfile::query()->where('review_status', DriverReviewStatus::Approved->value)->where('availability_status', DriverAvailabilityStatus::Online->value)->count()],
            ],
            'hourlyEnabled' => SystemSetting::query()->find('features.hourly_enabled')?->value === true,
            'hourlyRules' => PricingRule::query()
                ->with('vehicleType')
                ->where('service_type', ServiceType::Hourly->value)
                ->where('is_active', true)
                ->whereNotNull('hourly_rate')
                ->where('effective_from', '<=', now())
                ->where(fn ($query) => $query->whereNull('effective_to')->orWhere('effective_to', '>', now()))
                ->orderBy('vehicle_type_id')
                ->get(),
            'recentRequests' => $recentRequests,
        ];
    }
}
