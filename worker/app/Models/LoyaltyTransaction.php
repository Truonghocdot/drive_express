<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

#[Fillable([
    'user_id', 'type', 'points', 'balance_after', 'idempotency_key',
    'reference_type', 'reference_id', 'metadata',
])]
class LoyaltyTransaction extends Model
{
    public const UPDATED_AT = null;

    protected static function booted(): void
    {
        static::creating(function (LoyaltyTransaction $transaction): void {
            $transaction->public_id ??= (string) Str::uuid();
            $transaction->created_at ??= now();
        });
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    protected function casts(): array
    {
        return [
            'points' => 'integer',
            'balance_after' => 'integer',
            'reference_id' => 'integer',
            'metadata' => 'array',
            'created_at' => 'immutable_datetime',
        ];
    }
}
