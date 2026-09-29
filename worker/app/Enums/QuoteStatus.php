<?php

namespace App\Enums;

enum QuoteStatus: string
{
    case Active = 'ACTIVE';
    case Used = 'USED';
    case Expired = 'EXPIRED';
    case Cancelled = 'CANCELLED';

    public function getLabel(): string
    {
        return match ($this) {
            self::Active => 'Đang sử dụng',
            self::Used => 'Đã sử dụng',
            self::Expired => 'Đã hết hạn',
            self::Cancelled => 'Đã hủy',
        };
    }
}
