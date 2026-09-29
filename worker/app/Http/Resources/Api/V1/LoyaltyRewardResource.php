<?php

namespace App\Http\Resources\Api\V1;

use App\Models\LoyaltyReward;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin LoyaltyReward */
class LoyaltyRewardResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->public_id,
            'name' => $this->name,
            'points_cost' => $this->points_cost,
            'discount_type' => $this->discount_type->value,
            'discount_value' => $this->discount_value,
            'max_discount_amount' => $this->max_discount_amount,
            'service_scope' => $this->service_scope?->value,
            'minimum_order_amount' => $this->minimum_order_amount,
            'valid_days' => $this->valid_days,
            'stock' => $this->stock,
        ];
    }
}
