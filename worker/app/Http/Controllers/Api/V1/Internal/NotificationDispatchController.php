<?php

namespace App\Http\Controllers\Api\V1\Internal;

use App\Http\Controllers\Controller;
use App\Models\UserNotification;
use Illuminate\Http\JsonResponse;

class NotificationDispatchController extends Controller
{
    public function __invoke(string $notification): JsonResponse
    {
        $record = UserNotification::query()
            ->with('user')
            ->findOrFail($notification);

        $devices = $record->user
            ->devices()
            ->select(['app_type', 'push_token'])
            ->whereNotNull('push_token')
            ->whereNull('revoked_at')
            ->get()
            ->groupBy('app_type')
            ->map(static fn ($devices, string $appType): array => [
                'app_type' => $appType,
                'tokens' => $devices
                    ->pluck('push_token')
                    ->filter(static fn (mixed $token): bool => is_string($token) && $token !== '')
                    ->unique()
                    ->values()
                    ->all(),
            ])
            ->filter(static fn (array $device): bool => $device['tokens'] !== [])
            ->values()
            ->all();

        return response()->json([
            'data' => [
                'id' => $record->id,
                'user_id' => $record->user->public_id,
                'type' => $record->type,
                'data' => $record->data,
                'devices' => $devices,
            ],
        ]);
    }
}
