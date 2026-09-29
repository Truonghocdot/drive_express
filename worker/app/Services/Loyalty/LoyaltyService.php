<?php

namespace App\Services\Loyalty;

use App\Models\LoyaltyAccount;
use App\Models\LoyaltyReward;
use App\Models\LoyaltyTransaction;
use App\Models\Payment;
use App\Models\ServiceRequest;
use App\Models\SystemSetting;
use App\Models\User;
use App\Models\Voucher;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class LoyaltyService
{
    public function account(User $user): LoyaltyAccount
    {
        return LoyaltyAccount::query()->firstOrCreate(
            ['user_id' => $user->id],
            ['tier' => 'BRONZE'],
        );
    }

    public function earnForSettlement(ServiceRequest $request): ?LoyaltyTransaction
    {
        $payment = $request->payment;
        if ($payment === null || $payment->customer_payable <= 0) {
            return null;
        }

        $points = $this->pointsFor((float) $payment->customer_payable);
        if ($points <= 0) {
            return null;
        }

        return DB::transaction(function () use ($request, $points): LoyaltyTransaction {
            return $this->record(
                $request->creator,
                'EARN',
                $points,
                'service_request',
                $request->id,
                'earn:service-request:'.$request->id,
                ['customer_payable' => $request->payment?->customer_payable],
            );
        });
    }

    /** @return array{account: LoyaltyAccount, voucher: Voucher, transaction: LoyaltyTransaction} */
    public function redeem(User $user, LoyaltyReward $reward, string $idempotencyKey): array
    {
        return DB::transaction(function () use ($user, $reward, $idempotencyKey): array {
            $existing = LoyaltyTransaction::query()
                ->where('idempotency_key', $idempotencyKey)
                ->first();
            if ($existing !== null) {
                $voucher = Voucher::query()
                    ->where('owner_user_id', $user->id)
                    ->where('code', data_get($existing->metadata, 'voucher_code'))
                    ->firstOrFail();

                return [
                    'account' => $this->account($user),
                    'voucher' => $voucher,
                    'transaction' => $existing,
                ];
            }

            $account = $this->account($user);
            $account = LoyaltyAccount::query()->lockForUpdate()->findOrFail($account->id);
            if (! $reward->is_active || ($reward->stock !== null && $reward->stock <= 0)) {
                throw ValidationException::withMessages(['reward' => ['Phần thưởng không còn khả dụng.']]);
            }
            if ($account->points_balance < $reward->points_cost) {
                throw ValidationException::withMessages(['points' => ['Bạn không đủ điểm để đổi phần thưởng này.']]);
            }

            $voucher = Voucher::query()->create([
                'code' => Voucher::generateCode('LOYALTY'),
                'name' => $reward->name,
                'discount_type' => $reward->discount_type,
                'discount_value' => $reward->discount_value,
                'max_discount_amount' => $reward->max_discount_amount,
                'service_scope' => $reward->service_scope,
                'minimum_order_amount' => $reward->minimum_order_amount,
                'per_user_usage_limit' => 1,
                'max_restore_count' => 1,
                'starts_at' => now(),
                'ends_at' => now()->addDays($reward->valid_days),
                'is_active' => true,
                'created_by' => $reward->created_by,
                'owner_user_id' => $user->id,
            ]);

            $account->forceFill([
                'points_balance' => $account->points_balance - $reward->points_cost,
                'lifetime_redeemed' => $account->lifetime_redeemed + $reward->points_cost,
            ])->save();
            $transaction = LoyaltyTransaction::query()->create([
                'user_id' => $user->id,
                'type' => 'REDEEM',
                'points' => -$reward->points_cost,
                'balance_after' => $account->points_balance,
                'idempotency_key' => $idempotencyKey,
                'reference_type' => LoyaltyReward::class,
                'reference_id' => $reward->id,
                'metadata' => ['voucher_code' => $voucher->code],
            ]);

            if ($reward->stock !== null) {
                $reward->decrement('stock');
            }

            return compact('account', 'voucher', 'transaction');
        });
    }

    public function pointsFor(float $customerPayable): int
    {
        $setting = SystemSetting::query()->find('loyalty.points_per_1000_vnd');
        $multiplier = is_numeric($setting?->value) ? (float) $setting->value : 1;

        return max(0, (int) floor(max(0, $customerPayable) / 1_000 * $multiplier));
    }

    public function reverseForRefund(Payment $payment, float $amount, int $refundId): ?LoyaltyTransaction
    {
        $earned = LoyaltyTransaction::query()
            ->where('user_id', $payment->payer_user_id)
            ->where('type', 'EARN')
            ->where('reference_type', 'service_request')
            ->where('reference_id', $payment->service_request_id)
            ->first();
        if ($earned === null) return null;

        $points = min((int) $earned->points, $this->pointsFor($amount));
        if ($points <= 0) return null;

        return $this->record(
            $payment->payer,
            'REVERSE',
            -$points,
            'refund',
            $refundId,
            'reverse:refund:'.$refundId,
            ['refund_amount' => $amount],
        );
    }

    public function tierFor(int $lifetimeEarned): string
    {
        $setting = SystemSetting::query()->find('loyalty.tier_thresholds');
        $thresholds = is_array($setting?->value) ? $setting->value : [];
        $silver = (int) ($thresholds['SILVER'] ?? 1_000);
        $gold = (int) ($thresholds['GOLD'] ?? 5_000);

        return $lifetimeEarned >= $gold ? 'GOLD' : ($lifetimeEarned >= $silver ? 'SILVER' : 'BRONZE');
    }

    private function record(
        User $user,
        string $type,
        int $points,
        ?string $referenceType,
        ?int $referenceId,
        string $idempotencyKey,
        array $metadata = [],
    ): LoyaltyTransaction {
        $existing = LoyaltyTransaction::query()->where('idempotency_key', $idempotencyKey)->first();
        if ($existing !== null) {
            return $existing;
        }

        $account = LoyaltyAccount::query()->firstOrCreate(
            ['user_id' => $user->id],
            ['tier' => 'BRONZE'],
        );
        $account = LoyaltyAccount::query()->lockForUpdate()->findOrFail($account->id);
        $balance = $account->points_balance + $points;
        if ($balance < 0) {
            throw ValidationException::withMessages(['points' => ['Số dư điểm không hợp lệ.']]);
        }
        $account->forceFill([
            'points_balance' => $balance,
            'lifetime_earned' => $account->lifetime_earned + max(0, $points),
            'tier' => $this->tierFor($account->lifetime_earned + max(0, $points)),
        ])->save();

        return LoyaltyTransaction::query()->create([
            'user_id' => $user->id,
            'type' => $type,
            'points' => $points,
            'balance_after' => $balance,
            'idempotency_key' => $idempotencyKey,
            'reference_type' => $referenceType,
            'reference_id' => $referenceId,
            'metadata' => $metadata,
        ]);
    }
}
