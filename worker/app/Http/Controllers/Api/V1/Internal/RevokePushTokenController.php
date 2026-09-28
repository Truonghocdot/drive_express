<?php

namespace App\Http\Controllers\Api\V1\Internal;

use App\Http\Controllers\Controller;
use App\Models\UserDevice;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RevokePushTokenController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'push_token' => ['required', 'string', 'max:4096'],
        ]);

        UserDevice::query()
            ->where('push_token', $validated['push_token'])
            ->update(['revoked_at' => now()]);

        return response()->json(['data' => ['revoked' => true]]);
    }
}
