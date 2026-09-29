<?php

namespace App\Enums;

enum DiscountType: string
{
    case Percent = 'PERCENT';
    case Fixed = 'FIXED';

    public function getLabel(): string
    {
        return match ($this) {
            self::Percent => 'Phần trăm',
            self::Fixed => 'Cố định',
        };
    }
}
