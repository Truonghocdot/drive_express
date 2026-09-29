<?php

namespace App\Http\Resources\Api\V1;

use App\Models\LoyaltyTransaction;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin LoyaltyTransaction */
class LoyaltyTransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->public_id,
            'type' => $this->type,
            'points' => $this->points,
            'balance_after' => $this->balance_after,
            'metadata' => $this->metadata,
            'created_at' => $this->created_at,
        ];
    }
}
