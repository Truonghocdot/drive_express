<?php

namespace App\Http\Resources\Api\V1;

use App\Models\LoyaltyAccount;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin LoyaltyAccount */
class LoyaltyAccountResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->public_id,
            'points_balance' => $this->points_balance,
            'lifetime_earned' => $this->lifetime_earned,
            'lifetime_redeemed' => $this->lifetime_redeemed,
            'tier' => $this->tier,
        ];
    }
}
