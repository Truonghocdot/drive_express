<?php

namespace App\Filament\Resources\Vouchers\Schemas;

use Filament\Infolists\Components\IconEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class VoucherInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->components([
            Section::make('Mã giảm giá')->schema([
                TextEntry::make('code')->label('Mã nhập')->copyable(),
                TextEntry::make('name'),
                TextEntry::make('discount_type')->badge(),
                TextEntry::make('discount_value'),
                TextEntry::make('max_discount_amount')->placeholder('Không giới hạn'),
                TextEntry::make('service_scope')->badge()->placeholder('Mọi dịch vụ'),
                TextEntry::make('minimum_order_amount'),
                TextEntry::make('total_usage_limit')->placeholder('Không giới hạn'),
                TextEntry::make('per_user_usage_limit')->placeholder('Không giới hạn'),
                TextEntry::make('used_count')->label('Đã sử dụng'),
                TextEntry::make('starts_at')->dateTime(),
                TextEntry::make('ends_at')->dateTime(),
                IconEntry::make('is_active')->boolean(),
            ])->columns(2),
        ]);
    }
}
