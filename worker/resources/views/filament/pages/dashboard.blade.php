<x-filament-panels::page>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <div class="space-y-6">
        <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            @foreach ($stats as $stat)
                <div class="rounded-xl border border-gray-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-gray-900">
                    <p class="text-sm text-gray-500 dark:text-gray-400">{{ $stat['label'] }}</p>
                    <p class="mt-2 text-3xl font-semibold tracking-tight text-gray-950 dark:text-white">{{ number_format($stat['value']) }}</p>
                </div>
            @endforeach
        </div>

        <div class="grid gap-6 xl:grid-cols-[1.4fr_1fr]">
            <section class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-white/10 dark:bg-gray-900">
                <div class="flex items-center justify-between border-b border-gray-200 px-5 py-4 dark:border-white/10">
                    <div>
                        <h2 class="font-semibold text-gray-950 dark:text-white">Đơn gần đây</h2>
                        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">Các yêu cầu mới nhất trong hệ thống.</p>
                    </div>
                    <a class="text-sm font-medium text-primary-600 hover:underline" href="{{ \App\Filament\Resources\ServiceRequests\ServiceRequestResource::getUrl() }}">Xem tất cả</a>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-left text-sm">
                        <thead class="border-b border-gray-200 bg-gray-50 dark:border-white/10 dark:bg-white/5">
                            <tr>
                                <th class="px-5 py-3 font-medium">Mã đơn</th>
                                <th class="px-5 py-3 font-medium">Dịch vụ</th>
                                <th class="px-5 py-3 font-medium">Khách hàng</th>
                                <th class="px-5 py-3 font-medium">Trạng thái</th>
                                <th class="px-5 py-3 font-medium">Tạo lúc</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-200 dark:divide-white/10">
                            @forelse ($recentRequests as $request)
                                <tr>
                                    <td class="px-5 py-3">
                                        <a class="font-medium text-primary-600 hover:underline" href="{{ \App\Filament\Resources\ServiceRequests\ServiceRequestResource::getUrl('view', ['record' => $request]) }}">
                                            {{ \Illuminate\Support\Str::limit($request->public_id, 12, '...') }}
                                        </a>
                                    </td>
                                    <td class="px-5 py-3">{{ $request->service_type?->getLabel() ?? '—' }}</td>
                                    <td class="px-5 py-3">{{ $request->creator?->name ?? '—' }}</td>
                                    <td class="px-5 py-3">{{ $request->status?->getLabel() ?? '—' }}</td>
                                    <td class="whitespace-nowrap px-5 py-3 text-gray-500">{{ $request->created_at?->format('d/m H:i') }}</td>
                                </tr>
                            @empty
                                <tr>
                                    <td class="px-5 py-8 text-center text-gray-500" colspan="5">Chưa có đơn dịch vụ.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </section>

            <section class="rounded-xl border border-gray-200 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-gray-900">
                <div class="flex items-start justify-between gap-4">
                    <div>
                        <h2 class="font-semibold text-gray-950 dark:text-white">Thuê giờ</h2>
                        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">Trạng thái tính năng và bảng giá đang dùng.</p>
                    </div>
                    <span class="rounded-full px-3 py-1 text-xs font-semibold {{ $hourlyEnabled ? 'bg-success-50 text-success-700 dark:bg-success-500/10 dark:text-success-400' : 'bg-gray-100 text-gray-600 dark:bg-white/10 dark:text-gray-300' }}">
                        {{ $hourlyEnabled ? 'Đang bật' : 'Đang tắt' }}
                    </span>
                </div>
                <div class="mt-5 divide-y divide-gray-200 dark:divide-white/10">
                    @forelse ($hourlyRules as $rule)
                        <div class="flex items-center justify-between gap-4 py-3 first:pt-0 last:pb-0">
                            <span class="text-sm text-gray-700 dark:text-gray-300">{{ $rule->vehicleType?->name ?? 'Loại xe' }}</span>
                            <span class="whitespace-nowrap text-sm font-semibold text-gray-950 dark:text-white">{{ number_format((float) $rule->hourly_rate, 0, ',', '.') }} VND/giờ</span>
                        </div>
                    @empty
                        <p class="py-3 text-sm text-warning-600">Chưa có bảng giá thuê giờ.</p>
                    @endforelse
                </div>
                <a class="mt-5 inline-flex text-sm font-medium text-primary-600 hover:underline" href="{{ \App\Filament\Pages\SystemConfiguration::getUrl() }}">Mở cấu hình hệ thống</a>
            </section>
        </div>
    </div>
</x-filament-panels::page>
