<?php

namespace App\Http\Resources\Api\V1;

use App\Models\Voucher;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Voucher */
class VoucherResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->public_id,
            'code' => $this->code,
            'name' => $this->name,
            'discount_type' => $this->discount_type->value,
            'discount_value' => $this->discount_value,
            'max_discount_amount' => $this->max_discount_amount,
            'service_scope' => $this->service_scope?->value,
            'minimum_order_amount' => $this->minimum_order_amount,
            'starts_at' => $this->starts_at,
            'ends_at' => $this->ends_at,
            'is_owned' => $this->owner_user_id !== null,
        ];
    }
}
