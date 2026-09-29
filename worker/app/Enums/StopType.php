<?php

namespace App\Enums;

enum StopType: string
{
    case Pickup = 'PICKUP';
    case Dropoff = 'DROPOFF';

    public function getLabel(): string
    {
        return match ($this) {
            self::Pickup => 'Điểm đón',
            self::Dropoff => 'Điểm trả',
        };
    }
}
