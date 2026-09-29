<?php

namespace App\Models;

use App\Enums\DiscountType;
use App\Enums\ServiceType;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

#[Fillable([
    'name', 'points_cost', 'discount_type', 'discount_value',
    'max_discount_amount', 'service_scope', 'minimum_order_amount',
    'valid_days', 'stock', 'is_active', 'created_by',
])]
class LoyaltyReward extends Model
{
    protected static function booted(): void
    {
        static::creating(function (LoyaltyReward $reward): void {
            $reward->public_id ??= (string) Str::uuid();
        });
    }

    public function getRouteKeyName(): string
    {
        return 'public_id';
    }

    /** @return BelongsTo<User, $this> */
    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    protected function casts(): array
    {
        return [
            'points_cost' => 'integer',
            'discount_type' => DiscountType::class,
            'discount_value' => 'float',
            'max_discount_amount' => 'float',
            'service_scope' => ServiceType::class,
            'minimum_order_amount' => 'float',
            'valid_days' => 'integer',
            'stock' => 'integer',
            'is_active' => 'boolean',
        ];
    }
}
