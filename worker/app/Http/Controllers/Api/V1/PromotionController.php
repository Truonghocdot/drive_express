<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\VoucherResource;
use App\Models\User;
use App\Models\Voucher;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Request;

class PromotionController extends Controller
{
    public function vouchers(Request $request): AnonymousResourceCollection
    {
        $user = $request->user();
        assert($user instanceof User);

        $vouchers = Voucher::query()
            ->where('is_active', true)
            ->where('starts_at', '<=', now())
            ->where('ends_at', '>', now())
            ->where(function ($query) use ($user): void {
                $query->whereNull('owner_user_id')->orWhere('owner_user_id', $user->id);
            })
            ->where(function ($query): void {
                $query->whereNull('total_usage_limit')
                    ->orWhereColumn('used_count', '<', 'total_usage_limit');
            })
            ->orderBy('ends_at')
            ->get()
            ->filter(function (Voucher $voucher) use ($user): bool {
                if ($voucher->per_user_usage_limit === null) return true;

                return $voucher->redemptions()
                    ->where('user_id', $user->id)
                    ->where('status', 'USED')
                    ->count() < $voucher->per_user_usage_limit;
            });

        return VoucherResource::collection($vouchers);
    }
}
