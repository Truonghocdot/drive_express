<?php

namespace App\Filament\Resources\LoyaltyRewards\Schemas;

use App\Enums\DiscountType;
use App\Enums\ServiceType;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class LoyaltyRewardForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->components([
            Section::make('Phần thưởng')->schema([
                TextInput::make('name')->label('Tên')->required()->maxLength(150),
                TextInput::make('points_cost')->label('Điểm cần đổi')->numeric()->minValue(1)->required(),
                Select::make('discount_type')->label('Loại giảm')->options(collect(DiscountType::cases())->mapWithKeys(fn (DiscountType $type) => [$type->value => $type->getLabel()])->all())->required(),
                TextInput::make('discount_value')->label('Giá trị giảm')->numeric()->minValue(1)->required(),
                TextInput::make('max_discount_amount')->label('Giảm tối đa')->numeric()->minValue(0),
                Select::make('service_scope')->label('Dịch vụ')->options(collect(ServiceType::cases())->mapWithKeys(fn (ServiceType $type) => [$type->value => $type->getLabel()])->all()),
                TextInput::make('minimum_order_amount')->label('Đơn tối thiểu')->numeric()->minValue(0)->default(0)->required(),
                TextInput::make('valid_days')->label('Số ngày hiệu lực')->numeric()->minValue(1)->default(30)->required(),
                TextInput::make('stock')->label('Số lượng')->numeric()->minValue(1),
                Toggle::make('is_active')->label('Đang bán')->default(true),
            ])->columns(2),
        ]);
    }
}
