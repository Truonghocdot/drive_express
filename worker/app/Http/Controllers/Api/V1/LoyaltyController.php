<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\LoyaltyAccountResource;
use App\Http\Resources\Api\V1\LoyaltyRewardResource;
use App\Http\Resources\Api\V1\LoyaltyTransactionResource;
use App\Http\Resources\Api\V1\VoucherResource;
use App\Models\LoyaltyReward;
use App\Models\User;
use App\Services\Loyalty\LoyaltyService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\ValidationException;

class LoyaltyController extends Controller
{
    public function account(Request $request, LoyaltyService $loyalty): LoyaltyAccountResource
    {
        $user = $request->user();
        assert($user instanceof User);

        return new LoyaltyAccountResource($loyalty->account($user));
    }

    public function rewards(): AnonymousResourceCollection
    {
        return LoyaltyRewardResource::collection(
            LoyaltyReward::query()
                ->where('is_active', true)
                ->where(fn ($query) => $query->whereNull('stock')->orWhere('stock', '>', 0))
                ->orderBy('points_cost')
                ->get(),
        );
    }

    public function transactions(Request $request): AnonymousResourceCollection
    {
        $user = $request->user();
        assert($user instanceof User);

        return LoyaltyTransactionResource::collection(
            $user->loyaltyAccount?->transactions()->latest('created_at')->get() ?? collect(),
        );
    }

    public function redeem(
        Request $request,
        LoyaltyReward $reward,
        LoyaltyService $loyalty,
    ): array {
        $user = $request->user();
        assert($user instanceof User);
        $key = trim((string) $request->header('Idempotency-Key'));
        if ($key === '' || mb_strlen($key) > 191) {
            throw ValidationException::withMessages([
                'idempotency_key' => ['Header Idempotency-Key hợp lệ là bắt buộc.'],
            ]);
        }

        $result = $loyalty->redeem($user, $reward, $key);

        return [
            'data' => [
                'account' => new LoyaltyAccountResource($result['account']),
                'voucher' => new VoucherResource($result['voucher']),
                'transaction' => new LoyaltyTransactionResource($result['transaction']),
            ],
        ];
    }
}
