<?php

namespace App\Filament\Resources\LoyaltyRewards\Schemas;

use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Schema;

class LoyaltyRewardInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->components([
            TextEntry::make('name'),
            TextEntry::make('points_cost'),
            TextEntry::make('discount_type')->badge(),
            TextEntry::make('discount_value'),
            TextEntry::make('service_scope')->badge(),
            TextEntry::make('valid_days'),
            TextEntry::make('stock'),
            TextEntry::make('is_active')->formatStateUsing(fn ($state) => $state ? 'Đang bán' : 'Ngừng bán'),
        ])->columns(2);
    }
}
