<?php

namespace App\Http\Resources\Api\V1;

use App\Models\Wallet;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Wallet */
class WalletResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->public_id,
            'currency' => $this->currency,
            'balance' => $this->balance,
            'reserved_withdrawal_amount' => $this->reserved_withdrawal_amount,
            'available_balance' => $this->balance - $this->reserved_withdrawal_amount,
            'status' => $this->status,
            'version' => $this->version,
            'entries' => $this->when(
                $this->relationLoaded('ledgerAccount')
                    && $this->ledgerAccount->relationLoaded('entries'),
                fn () => $this->ledgerAccount->entries->map(fn ($entry): array => [
                    'id' => $entry->id,
                    'direction' => $entry->direction,
                    'amount' => $entry->amount,
                    'balance_after' => $entry->balance_after,
                    'transaction_type' => $entry->transaction?->transaction_type,
                    'transaction_status' => $entry->transaction?->status,
                    'reference_type' => $entry->transaction?->reference_type,
                    'reference_id' => $entry->transaction?->reference_id,
                    'metadata' => $entry->transaction?->metadata,
                    'posted_at' => $entry->transaction?->posted_at,
                    'created_at' => $entry->created_at,
                ])->values(),
            ),
        ];
    }
}
