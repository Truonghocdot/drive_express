<?php

namespace App\Filament\Pages;

use App\Enums\AppType;
use App\Enums\RoleKey;
use App\Enums\UserStatus;
use App\Models\User;
use App\Services\Notification\NotificationService;
use BackedEnum;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Illuminate\Database\Eloquent\Builder;
use UnitEnum;

class MarketingNotification extends Page implements HasForms
{
    use InteractsWithForms;

    protected static string|UnitEnum|null $navigationGroup = 'Marketing';

    protected static ?string $navigationLabel = 'Thông báo marketing';

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedMegaphone;

    protected static ?int $navigationSort = 20;

    protected string $view = 'filament.pages.marketing-notification';

    /** @var array<string, mixed> */
    public array $data = [];

    public static function canAccess(): bool
    {
        $user = auth()->user();

        return $user instanceof User && $user->hasRole(RoleKey::Admin);
    }

    public function mount(): void
    {
        $this->form->fill(['audience' => 'all']);
    }

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Đối tượng nhận')
                    ->description('Chỉ tài khoản đang hoạt động có thiết bị còn hiệu lực được chọn.')
                    ->schema([
                        Select::make('audience')
                            ->label('Gửi đến')
                            ->options([
                                'all' => 'Tất cả người dùng',
                                'customers' => 'Khách hàng',
                                'drivers' => 'Tài xế',
                            ])
                            ->native(false)
                            ->required(),
                    ]),
                Section::make('Nội dung thông báo')
                    ->description('Nội dung này hiển thị trong thông báo đẩy và hộp thư ứng dụng.')
                    ->schema([
                        TextInput::make('title')
                            ->label('Tiêu đề')
                            ->placeholder('Ví dụ: Ưu đãi cuối tuần')
                            ->maxLength(80)
                            ->required(),
                        Textarea::make('body')
                            ->label('Nội dung')
                            ->placeholder('Viết lời mời ngắn gọn, rõ ràng cho người nhận.')
                            ->rows(5)
                            ->maxLength(240)
                            ->required(),
                    ]),
            ])
            ->statePath('data');
    }

    public function send(): void
    {
        $state = $this->form->getState();
        $targetAppType = match ($state['audience']) {
            'customers' => AppType::Customer->value,
            'drivers' => AppType::Driver->value,
            default => null,
        };

        $query = User::query()
            ->where('status', UserStatus::Active->value)
            ->whereHas('devices', function (Builder $deviceQuery) use ($targetAppType): void {
                $deviceQuery
                    ->whereNotNull('push_token')
                    ->whereNull('revoked_at')
                    ->when($targetAppType !== null, fn (Builder $query) => $query->where('app_type', $targetAppType));
            });

        $sent = 0;
        $query->orderBy('id')->chunkById(100, function ($users) use ($state, $targetAppType, &$sent): void {
            foreach ($users as $user) {
                $data = [
                    'title' => $state['title'],
                    'body' => $state['body'],
                ];
                if ($targetAppType !== null) {
                    $data['target_app_type'] = $targetAppType;
                }

                app(NotificationService::class)->create($user, 'MARKETING_BROADCAST', $data);
                $sent++;
            }
        });

        Notification::make()
            ->title("Đã tạo {$sent} thông báo marketing")
            ->body('Thông báo đang được phát qua hàng đợi realtime.')
            ->success()
            ->send();

        $this->form->fill([
            'audience' => $state['audience'],
            'title' => '',
            'body' => '',
        ]);
    }
}
