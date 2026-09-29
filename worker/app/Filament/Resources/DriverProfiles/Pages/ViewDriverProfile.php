<?php

namespace App\Filament\Resources\DriverProfiles\Pages;

use App\Enums\DriverReviewStatus;
use App\Enums\ServiceType;
use App\Filament\Resources\DriverProfiles\DriverProfileResource;
use App\Models\DriverProfile;
use App\Models\User;
use App\Services\Driver\DriverReviewService;
use Filament\Actions\Action;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ViewRecord;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;
use Throwable;

class ViewDriverProfile extends ViewRecord
{
    protected static string $resource = DriverProfileResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Action::make('approve')
                ->label('Phê duyệt')
                ->color('success')
                ->form([
                    TextInput::make('daily_cod_limit')
                        ->label('Hạn mức ứng COD mỗi ngày (VND)')
                        ->numeric()
                        ->default((float) config('finance.driver_daily_cod_limit', 8_000_000))
                        ->minValue(0)
                        ->required()
                        ->helperText('Tổng tiền COD đã ứng được tính lại từ 0 vào đầu mỗi ngày.'),
                ])
                ->requiresConfirmation()
                ->visible(fn (): bool => $this->driver()->review_status === DriverReviewStatus::PendingReview)
                ->successNotificationTitle('Đã phê duyệt tài xế')
                ->successRedirectUrl(fn (): string => DriverProfileResource::getUrl('view', ['record' => $this->driver()]))
                ->action(function (array $data, Action $action, DriverReviewService $review): void {
                    try {
                        $review->approve(
                            $this->driver(),
                            $this->admin(),
                            (float) $data['daily_cod_limit'],
                        );
                    } catch (ValidationException $exception) {
                        $action->failure();
                        Notification::make()
                            ->title('Không thể phê duyệt tài xế')
                            ->body(collect($exception->errors())->flatten()->first() ?? 'Hồ sơ chưa đáp ứng điều kiện phê duyệt.')
                            ->danger()
                            ->persistent()
                            ->send();
                    } catch (Throwable $exception) {
                        Log::error('Filament driver approval action failed.', [
                            'source' => 'driver_profile_view',
                            'driver_profile_id' => $this->driver()->id,
                            'driver_profile_public_id' => $this->driver()->public_id,
                            'admin_user_id' => $this->admin()->id,
                            'exception' => $exception,
                        ]);
                        $action->failure();
                        Notification::make()
                            ->title('Không thể phê duyệt tài xế')
                            ->body('Đã xảy ra lỗi hệ thống. Vui lòng kiểm tra nhật ký hệ thống và thử lại.')
                            ->danger()
                            ->persistent()
                            ->send();
                    }
                }),
            Action::make('addCapability')
                ->label('Thêm dịch vụ')
                ->form([
                    Select::make('service_type')
                        ->label('Dịch vụ')
                        ->options(collect(ServiceType::cases())->mapWithKeys(
                            fn (ServiceType $type): array => [$type->value => $type->getLabel()],
                        )->all())
                        ->required(),
                    Select::make('vehicle_type_id')
                        ->label('Loại xe đã duyệt')
                        ->options(fn (): array => $this->driver()->vehicles()
                            ->with('vehicleType')
                            ->get()
                            ->mapWithKeys(fn ($vehicle): array => [
                                $vehicle->vehicle_type_id => $vehicle->vehicleType->name,
                            ])
                            ->all())
                        ->required(),
                ])
                ->visible(fn (): bool => $this->driver()->review_status === DriverReviewStatus::Approved)
                ->action(function (array $data, DriverReviewService $review): void {
                    $review->addCapability(
                        $this->driver(),
                        $this->admin(),
                        (int) $data['vehicle_type_id'],
                        ServiceType::from((string) $data['service_type']),
                    );
                    Notification::make()->title('Đã thêm dịch vụ cho tài xế')->success()->send();
                }),
            Action::make('reject')
                ->label('Từ chối')
                ->color('danger')
                ->form([
                    TextInput::make('reason_code')->required()->maxLength(50),
                ])
                ->visible(fn (): bool => $this->driver()->review_status === DriverReviewStatus::PendingReview)
                ->action(function (array $data, DriverReviewService $review): void {
                    $review->reject($this->driver(), $this->admin(), $data['reason_code']);
                    $this->refreshFormData(['review_status', 'review_reason_code', 'reviewed_at']);
                    Notification::make()->title('Đã từ chối hồ sơ tài xế')->success()->send();
                }),
            Action::make('suspend')
                ->label('Tạm ngưng')
                ->color('danger')
                ->form([
                    TextInput::make('reason_code')->required()->maxLength(50),
                ])
                ->visible(fn (): bool => $this->driver()->review_status === DriverReviewStatus::Approved)
                ->action(function (array $data, DriverReviewService $review): void {
                    $review->suspend($this->driver(), $this->admin(), $data['reason_code']);
                    $this->refreshFormData(['review_status', 'availability_status', 'review_reason_code']);
                    Notification::make()->title('Đã tạm ngưng tài xế')->success()->send();
                }),
        ];
    }

    private function driver(): DriverProfile
    {
        /** @var DriverProfile $record */
        $record = $this->getRecord();

        return $record;
    }

    private function admin(): User
    {
        $user = auth()->user();
        abort_unless($user instanceof User, 403);

        return $user;
    }
}
