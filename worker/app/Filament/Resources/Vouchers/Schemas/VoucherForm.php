<?php

namespace App\Filament\Resources\Vouchers\Schemas;

use App\Enums\DiscountType;
use App\Enums\ServiceType;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class VoucherForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->components([
            Section::make('Thông tin mã giảm giá')->schema([
                TextInput::make('name')
                    ->label('Tên chương trình')
                    ->required()
                    ->maxLength(150),
                TextInput::make('code')
                    ->label('Mã nhập')
                    ->helperText('Để trống để hệ thống tự sinh mã duy nhất dạng DRIVE-XXXXXXXX.')
                    ->alphaDash()
                    ->maxLength(50)
                    ->unique(ignoreRecord: true),
                Select::make('discount_type')
                    ->label('Loại giảm giá')
                    ->options(collect(DiscountType::cases())->mapWithKeys(
                        fn (DiscountType $type): array => [$type->value => $type->getLabel()],
                    )->all())
                    ->required(),
                TextInput::make('discount_value')
                    ->label('Giá trị giảm')
                    ->numeric()
                    ->minValue(1)
                    ->required(),
                TextInput::make('max_discount_amount')
                    ->label('Giảm tối đa')
                    ->numeric()
                    ->minValue(0),
                Select::make('service_scope')
                    ->label('Áp dụng cho dịch vụ')
                    ->options(collect(ServiceType::cases())->mapWithKeys(
                        fn (ServiceType $type): array => [$type->value => $type->getLabel()],
                    )->all())
                    ->placeholder('Mọi dịch vụ'),
            ])->columns(2),
            Section::make('Điều kiện sử dụng')->schema([
                TextInput::make('minimum_order_amount')
                    ->label('Giá trị đơn tối thiểu')
                    ->numeric()
                    ->minValue(0)
                    ->default(0)
                    ->required(),
                TextInput::make('total_usage_limit')
                    ->label('Tổng lượt dùng tối đa')
                    ->numeric()
                    ->minValue(1),
                TextInput::make('per_user_usage_limit')
                    ->label('Lượt dùng tối đa mỗi khách')
                    ->numeric()
                    ->minValue(1),
                TextInput::make('max_restore_count')
                    ->label('Số lần hoàn mã tối đa')
                    ->numeric()
                    ->minValue(0)
                    ->default(1)
                    ->required(),
                DateTimePicker::make('starts_at')
                    ->label('Bắt đầu lúc')
                    ->default(now())
                    ->required(),
                DateTimePicker::make('ends_at')
                    ->label('Kết thúc lúc')
                    ->after('starts_at')
                    ->default(now()->addMonth())
                    ->required(),
                Toggle::make('is_active')
                    ->label('Đang hoạt động')
                    ->default(true),
            ])->columns(2),
        ]);
    }
}
