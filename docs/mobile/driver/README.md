# Driver Mobile

Ứng dụng Flutter cho tài xế: đăng ký/KYC, availability, GPS, offer, chuyến đang chạy, ví, thông báo và hỗ trợ.

## Trạng thái triển khai

Driver app hiện đã có:

- Shell 4 tab: `Hoạt động`, `Lịch sử`, `Thu nhập`, `Hồ sơ`.
- Dark-first Apex Driver Transit theme, vẫn giữ light fallback trong `DriverTheme`.
- Home map full-screen bằng Goong MapLibre với status rail, floating map controls và bottom panel.
- Incoming offer bằng modal bottom sheet, countdown, accept/decline có idempotency.
- History search/filter theo ngày, status, service type và mã chuyến/địa chỉ.
- History summary: completed, cancelled, net earning.
- Wallet balance hero, ẩn/hiện số dư, bank accounts, topup/withdraw và ledger entries gần đây.
- Profile KPI: rating, acceptance rate, completion rate, completed count, capabilities và support/settings.
- Active job map, route refresh, chat, evidence, SOS và slide-to-confirm cho terminal transition.

## Kiến trúc runtime

```text
main.dart
  -> DriverApp
    -> DriverAppController
      -> DriverApi / DriverRealtime / DriverLocationSource / GoongNavigationApi
    -> MainDriverNavigationPage
      -> DriverHomePage
      -> DriverHistoryPage
      -> WalletPage
      -> DriverProfilePage
```

`DriverAppController` là nguồn state UI. Worker API là nguồn trạng thái nghiệp vụ; Socket.IO chỉ báo thay đổi và controller luôn reload offer/notification/snapshot qua HTTPS khi reconnect hoặc nhận event.

## Bản đồ và điều hướng

`DriverGoongMap` dùng `maplibre_gl`. Map luôn là bản đồ thật, không dùng SVG/mock map cho production.

- `GOONG_MAP_KEY`: tile/style mặc định.
- `GOONG_MAP_STYLE_URL`: style URL tùy chọn, dùng để bật dark map style vận hành.
- `GOONG_API_KEY`: Directions/polyline.
- Delivery dùng vehicle `bike`; Drive dùng `car`.

Điểm đích:

```text
DRIVER_ARRIVING / DRIVER_ARRIVING_PICKUP / AT_PICKUP -> điểm đón
PICKED_UP / IN_DELIVERY / IN_TRIP                  -> điểm trả
```

Map không cung cấp turn-by-turn voice navigation. Nút refresh route lấy GPS mới và gọi Directions lại.

## Cấu hình local

Tạo `mobile/driver/.env` từ `.env.example`:

```env
API_BASE_URL=http://10.0.2.2:8000/api/v1
REALTIME_URL=http://10.0.2.2:3000
GOONG_API_KEY=your_goong_rest_api_key
GOONG_MAP_KEY=your_goong_map_tile_key
GOONG_MAP_STYLE_URL=
```

Chạy emulator:

```powershell
flutter run -d emulator-5556 --dart-define-from-file=.env
```

Không commit `.env` hoặc Firebase Admin credentials. `google-services.json` và `firebase_options.dart` là cấu hình client của Firebase driver project; credential Admin được cấu hình riêng ở `service/.env`.

## Firebase và push notification

Driver dùng Firebase project riêng với customer app. Khi login/verify phone, `firebase_messaging` lấy FCM token và gửi vào `push_token`; token refresh được cập nhật trong `PushTokenProvider`.

Backend định tuyến theo `user_devices.app_type = DRIVER_APP`:

```env
FIREBASE_DRIVER_PROJECT_ID=drive-app-a31f9
FIREBASE_DRIVER_CLIENT_EMAIL=...
FIREBASE_DRIVER_PRIVATE_KEY=...
```

Push không thay thế HTTPS snapshot. Khi socket/push lỗi, app vẫn đọc offer, notification và trạng thái chuẩn qua API.

## API driver read-model

Các endpoint nghiệp vụ chính:

| Endpoint | Mục đích |
|---|---|
| `GET /driver/application` | KYC, vehicle, capabilities, availability, performance |
| `GET /driver/offers` | Offer pending và assignment active |
| `GET /driver/history` | Lịch sử assignment đã đóng |
| `GET /wallet` | Balance, reserved amount và ledger entries |
| `GET /driver/bank-accounts` | Tài khoản rút tiền |
| `PUT /driver/availability/online` | Bật online và gửi GPS đầu tiên |
| `PUT /driver/availability/offline` | Tắt nhận offer |
| `PUT /driver/location` | Heartbeat/location snapshot |
| `POST /driver/offers/{offer}/respond` | Accept/decline offer |
| `POST /driver/service-requests/{request}/transition` | Transition active job |

### History filters

`GET /driver/history` hỗ trợ:

```text
from=YYYY-MM-DD
to=YYYY-MM-DD
status=COMPLETED|CANCELLED
service_type=DELIVERY|DRIVE
q=<public-id-or-address>
page=1
```

`meta.summary` gồm `completed_count`, `cancelled_count`, `net_earning`. UI không dựng history giả từ local state.

### Profile performance

`GET /driver/application` trả thêm:

```json
{
  "performance": {
    "rating": 4.98,
    "acceptance_rate": 96.5,
    "completion_rate": 99.1,
    "completed_count": 14,
    "updated_at": "..."
  }
}
```

Metric chưa đủ dữ liệu trả `null`, không dùng số demo.

## GPS và realtime

- Driver gửi location mỗi 5 giây khi online hoặc có active offer.
- Khi có active assignment, location được gửi qua `/driver/location`.
- Khi online nhưng chưa có assignment, heartbeat gia hạn availability/presence.
- Khi offline hoặc GPS bị từ chối, UI hiển thị error/retry và không tự giả lập tọa độ.
- Socket room chỉ được join sau khi realtime service xác minh Sanctum token và quyền booking.

## Testing

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Các test hiện bao phủ onboarding, upload, availability, permission denied, offer, reconnect, history filter parsing, wallet entries, performance parsing và active job UI.

iOS cần được build/smoke test trên macOS với signing, Keychain và Firebase native configuration tương ứng.
