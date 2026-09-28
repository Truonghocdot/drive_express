<?php

namespace App\Http\Controllers\Api\V1\Driver;

use App\Enums\AssignmentStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ServiceRequestResource;
use App\Models\DriverProfile;
use App\Models\ServiceRequest;
use App\Models\Settlement;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class JobHistoryController extends Controller
{
    public function __invoke(Request $request): AnonymousResourceCollection
    {
        $user = $request->user();
        abort_unless($user instanceof User, 401);

        $filters = $request->validate([
            'from' => ['nullable', 'date_format:Y-m-d'],
            'to' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:from'],
            'status' => ['nullable', 'in:COMPLETED,CANCELLED'],
            'service_type' => ['nullable', 'in:DELIVERY,DRIVE'],
            'q' => ['nullable', 'string', 'max:100'],
        ]);
        $profile = DriverProfile::query()->where('user_id', $user->id)->firstOrFail();
        $query = $this->query($user, $filters);

        $summaryQuery = clone $query;
        $summary = [
            'completed_count' => (clone $summaryQuery)
                ->whereHas('assignments', fn (Builder $builder) => $builder->where('status', AssignmentStatus::Completed->value))
                ->count(),
            'cancelled_count' => (clone $summaryQuery)
                ->whereHas('assignments', fn (Builder $builder) => $builder->where('status', AssignmentStatus::Cancelled->value))
                ->count(),
            'net_earning' => (float) Settlement::query()
                ->where('driver_profile_id', $profile->id)
                ->whereHas('payment.serviceRequest', function (Builder $builder) use ($filters, $user): void {
                    $this->applyFilters($builder, $user, $filters);
                })
                ->sum('driver_net_earning'),
        ];

        return ServiceRequestResource::collection(
            $query
                ->with([
                    'vehicleType',
                    'quote',
                    'stops',
                    'deliveryOrder',
                    'rideBooking',
                    'payment.settlement',
                    'assignments' => fn ($query) => $query
                        ->whereHas('driverProfile', fn ($query) => $query->where('user_id', $user->id))
                        ->latest('id'),
                    'assignments.driverProfile.user',
                    'assignments.vehicle',
                    'evidences',
                ])
                ->latest('id')
                ->paginate(20),
        )->additional([
            'meta' => [
                'summary' => $summary,
                'filters' => [
                    'from' => $filters['from'] ?? null,
                    'to' => $filters['to'] ?? null,
                    'status' => $filters['status'] ?? null,
                    'service_type' => $filters['service_type'] ?? null,
                    'q' => $filters['q'] ?? null,
                ],
            ],
        ]);
    }

    /** @param array<string, mixed> $filters */
    private function query(User $user, array $filters): Builder
    {
        $query = ServiceRequest::query()->whereHas('assignments', function ($query) use ($user): void {
            $query->whereIn('status', [
                AssignmentStatus::Completed->value,
                AssignmentStatus::Cancelled->value,
            ])->whereHas(
                'driverProfile',
                fn ($query) => $query->where('user_id', $user->id),
            );
        });

        return $this->applyFilters($query, $user, $filters);
    }

    /** @param array<string, mixed> $filters */
    private function applyFilters(Builder $query, User $user, array $filters): Builder
    {
        return $query
            ->when($filters['from'] ?? null, fn (Builder $builder, string $from) => $builder->whereDate('created_at', '>=', $from))
            ->when($filters['to'] ?? null, fn (Builder $builder, string $to) => $builder->whereDate('created_at', '<=', $to))
            ->when($filters['status'] ?? null, fn (Builder $builder, string $status) => $builder->where('status', $status))
            ->when($filters['service_type'] ?? null, fn (Builder $builder, string $type) => $builder->where('service_type', $type))
            ->when($filters['q'] ?? null, function (Builder $builder, string $search): void {
                $builder->where(function (Builder $nested) use ($search): void {
                    $nested->where('public_id', 'like', "%{$search}%")
                        ->orWhereHas('stops', fn (Builder $stops) => $stops->where('address', 'like', "%{$search}%"));
                });
            });
    }
}
