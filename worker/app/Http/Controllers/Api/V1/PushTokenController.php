<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\AppType;
use App\Enums\DriverReviewStatus;
use App\Enums\RoleKey;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserDevice;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class PushTokenController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $data = $request->validate([
            'device_id' => ['required', 'string', 'max:191'],
            'app_type' => ['required', Rule::enum(AppType::class)],
            'platform' => ['required', Rule::in(['ANDROID', 'IOS', 'WEB'])],
            'push_token' => ['required', 'string', 'max:4096'],
        ]);
        $user = $request->user();
        assert($user instanceof User);
        $appType = AppType::from($data['app_type']);

        if ($appType === AppType::Driver
            && (! $user->hasRole(RoleKey::Driver)
                || $user->driverProfile?->review_status !== DriverReviewStatus::Approved)) {
            throw ValidationException::withMessages([
                'app_type' => ['Tài khoản này chưa được phê duyệt để dùng ứng dụng tài xế.'],
            ]);
        }

        UserDevice::query()->updateOrCreate(
            [
                'user_id' => $user->id,
                'device_id' => $data['device_id'],
                'app_type' => $appType->value,
            ],
            [
                'platform' => $data['platform'],
                'push_token' => $data['push_token'],
                'last_seen_at' => now(),
                'revoked_at' => null,
            ],
        );
        UserDevice::query()
            ->where('user_id', $user->id)
            ->where('device_id', $data['device_id'])
            ->where('app_type', '<>', $appType->value)
            ->update(['revoked_at' => now()]);

        return response()->json(['data' => ['synced' => true]]);
    }
}
