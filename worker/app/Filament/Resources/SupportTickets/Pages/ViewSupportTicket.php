<?php

namespace App\Filament\Resources\SupportTickets\Pages;

use App\Enums\RoleKey;
use App\Enums\SupportTicketStatus;
use App\Filament\Resources\SupportTickets\SupportTicketResource;
use App\Models\SupportTicket;
use App\Models\User;
use App\Services\Support\SupportTicketService;
use Filament\Actions\Action;
use Filament\Forms\Components\Textarea;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ViewRecord;

class ViewSupportTicket extends ViewRecord
{
    protected static string $resource = SupportTicketResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Action::make('reply')
                ->label('Phản hồi khách hàng')
                ->icon('heroicon-o-chat-bubble-left-right')
                ->form([
                    Textarea::make('body')
                        ->label('Nội dung')
                        ->required()
                        ->maxLength(5000)
                        ->rows(5),
                ])
                ->visible(function (SupportTicket $record): bool {
                    $user = auth()->user();

                    return $record->status !== SupportTicketStatus::Closed
                        && $user instanceof User
                        && ($user->hasRole(RoleKey::Admin)
                            || ($user->hasRole(RoleKey::Support) && $record->assigned_to === $user->id));
                })
                ->action(function (SupportTicket $record, array $data, SupportTicketService $service): void {
                    $user = auth()->user();
                    abort_unless($user instanceof User, 403);
                    $service->message($user, $record, trim($data['body']));

                    Notification::make()
                        ->title('Đã gửi phản hồi cho khách hàng')
                        ->success()
                        ->send();
                }),
        ];
    }
}
