<?php

namespace App\Filament\Resources\LoyaltyRewards;

use App\Filament\Concerns\RequiresAdminRole;
use App\Filament\Resources\LoyaltyRewards\Pages\CreateLoyaltyReward;
use App\Filament\Resources\LoyaltyRewards\Pages\EditLoyaltyReward;
use App\Filament\Resources\LoyaltyRewards\Pages\ListLoyaltyRewards;
use App\Filament\Resources\LoyaltyRewards\Pages\ViewLoyaltyReward;
use App\Models\LoyaltyReward;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use UnitEnum;

class LoyaltyRewardResource extends Resource
{
    use RequiresAdminRole;

    protected static ?string $model = LoyaltyReward::class;
    protected static string|UnitEnum|null $navigationGroup = 'Khách hàng';
    protected static ?string $navigationLabel = 'Đổi điểm';
    protected static ?string $modelLabel = 'phần thưởng';
    protected static ?string $pluralModelLabel = 'phần thưởng';
    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedGift;

    public static function form(Schema $schema): Schema
    {
        return \App\Filament\Resources\LoyaltyRewards\Schemas\LoyaltyRewardForm::configure($schema);
    }

    public static function infolist(Schema $schema): Schema
    {
        return \App\Filament\Resources\LoyaltyRewards\Schemas\LoyaltyRewardInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return \App\Filament\Resources\LoyaltyRewards\Tables\LoyaltyRewardsTable::configure($table);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListLoyaltyRewards::route('/'),
            'create' => CreateLoyaltyReward::route('/create'),
            'view' => ViewLoyaltyReward::route('/{record}'),
            'edit' => EditLoyaltyReward::route('/{record}/edit'),
        ];
    }
}
