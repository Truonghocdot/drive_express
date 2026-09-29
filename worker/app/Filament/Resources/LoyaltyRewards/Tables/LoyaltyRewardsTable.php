<?php

namespace App\Filament\Resources\LoyaltyRewards\Tables;

use App\Models\LoyaltyReward;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class LoyaltyRewardsTable
{
    public static function configure(Table $table): Table
    {
        return $table->defaultSort('points_cost')->columns([
            TextColumn::make('name')->searchable(),
            TextColumn::make('points_cost')->label('Điểm'),
            TextColumn::make('discount_type')->badge(),
            TextColumn::make('discount_value'),
            TextColumn::make('service_scope')->badge(),
            TextColumn::make('stock'),
            IconColumn::make('is_active')->boolean(),
        ])->recordActions([ViewAction::make(), EditAction::make()])->toolbarActions([]);
    }
}
