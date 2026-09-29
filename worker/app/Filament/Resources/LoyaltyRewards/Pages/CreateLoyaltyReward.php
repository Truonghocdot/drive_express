<?php
namespace App\Filament\Resources\LoyaltyRewards\Pages;
use App\Filament\Resources\LoyaltyRewards\LoyaltyRewardResource;
use Filament\Resources\Pages\CreateRecord;
class CreateLoyaltyReward extends CreateRecord
{
    protected static string $resource = LoyaltyRewardResource::class;
    protected function mutateFormDataBeforeCreate(array $data): array { $data['created_by'] = auth()->id(); return $data; }
}
