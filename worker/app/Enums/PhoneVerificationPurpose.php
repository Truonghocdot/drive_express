<?php

namespace App\Enums;

enum PhoneVerificationPurpose: string
{
    case Register = 'REGISTER';
    case ResetPassword = 'RESET_PASSWORD';
    case ChangePhone = 'CHANGE_PHONE';

    public function getLabel(): string
    {
        return match ($this) {
            self::Register => 'Đăng ký',
            self::ResetPassword => 'Đặt lại mật khẩu',
            self::ChangePhone => 'Đổi số điện thoại',
        };
    }
}
