<?php

namespace App\Http\Requests\Api\V1\Quote;

use App\Enums\BookingType;
use App\Enums\ServiceType;
use App\Enums\UserStatus;
use App\Models\User;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreBatchQuoteRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();

        return $user instanceof User && $user->status === UserStatus::Active;
    }

    /** @return array<string, ValidationRule|array<mixed>|string> */
    public function rules(): array
    {
        $scheduled = $this->input('booking_type') === BookingType::Scheduled->value;

        return [
            'service_type' => ['required', Rule::in([ServiceType::Drive->value])],
            'vehicle_type_ids' => ['required', 'array', 'size:2'],
            'vehicle_type_ids.*' => [
                'required',
                'distinct',
                'uuid',
                Rule::exists('vehicle_types', 'public_id')->where('is_active', true),
            ],
            'booking_type' => ['required', Rule::enum(BookingType::class)],
            'scheduled_at' => [
                Rule::requiredIf($scheduled),
                Rule::prohibitedIf(! $scheduled),
                'date',
                'after:now',
            ],
            'pickup' => ['required', 'array:address,latitude,longitude,note'],
            'pickup.address' => ['required', 'string', 'max:500'],
            'pickup.latitude' => ['required', 'numeric', 'between:-90,90'],
            'pickup.longitude' => ['required', 'numeric', 'between:-180,180'],
            'pickup.note' => ['nullable', 'string', 'max:500'],
            'dropoff' => ['required', 'array:address,latitude,longitude,note'],
            'dropoff.address' => ['required', 'string', 'max:500'],
            'dropoff.latitude' => ['required', 'numeric', 'between:-90,90'],
            'dropoff.longitude' => ['required', 'numeric', 'between:-180,180'],
            'dropoff.note' => ['nullable', 'string', 'max:500'],
            'service_payload' => ['required', 'array:passenger_count'],
            'service_payload.passenger_count' => ['required', 'integer', 'min:1'],
            'voucher_code' => ['nullable', 'string', 'max:50'],
        ];
    }
}
