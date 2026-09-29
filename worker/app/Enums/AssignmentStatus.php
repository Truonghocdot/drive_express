<?php

namespace App\Enums;

enum AssignmentStatus: string
{
    case Active = 'ACTIVE';
    case Completed = 'COMPLETED';
    case Cancelled = 'CANCELLED';

    public function getLabel(): string
    {
        return match ($this) {
            self::Active => 'Đang thực hiện',
            self::Completed => 'Hoàn thành',
            self::Cancelled => 'Đã hủy',
        };
    }
}
