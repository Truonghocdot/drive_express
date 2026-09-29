# Hướng Dẫn Cài Đặt Local

Tài liệu này chạy đủ worker Laravel, realtime service, mobile khách và mobile tài xế trên máy local hoặc điện thoại trong cùng mạng LAN.

## 1. Yêu Cầu

- PHP 8.3+ với `pdo_pgsql`, `mbstring`, `openssl`, `redis` hoặc dùng Predis.
- Composer 2, Node.js 20+ và npm.
- PostgreSQL 15+; Redis 7+ đang chạy trên máy local.
- Flutter SDK tương thích Dart `^3.13.3`; Android Studio/SDK cho Android emulator hoặc điện thoại thật.
- Tài khoản/key Goong cho autocomplete, directions và map tiles.
- Firebase project customer/driver khi cần nhận push notification trên thiết bị thật.

## 2. Chuẩn Bị Worker

Tạo database PostgreSQL trước, ví dụ:

```sql
CREATE DATABASE drive;
```

Thiết lập backend:

```powershell
cd worker
composer install
Copy-Item .env.example .env
```

Trong `worker/.env`, cấu hình tối thiểu:

```env
APP_URL=http://127.0.0.1:8000
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=drive
DB_USERNAME=postgres
DB_PASSWORD=

REDIS_CLIENT=phpredis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379

GOONG_API_KEY=<worker_goong_rest_key>
REALTIME_INTERNAL_TOKEN=<random_shared_secret>
```

Nếu PHP không có extension `phpredis`, đặt `REDIS_CLIENT=predis` vì package đã có trong Composer dependencies.

Khởi tạo schema và admin:

```powershell
php artisan key:generate
php artisan migrate
php artisan db:seed --class=RoleSeeder
php artisan db:seed --class=VehicleTypeSeeder
php artisan app:create-admin-user 0901234567 --name="Administrator"
php artisan db:seed --class=PricingConfigurationSeeder
```

`PricingConfigurationSeeder` tạo cấu hình mặc định (TTL báo giá, làm tròn tiền, sai số) và bảng giá giao hàng, đặt xe, thuê giờ. Tính năng thuê giờ vẫn tắt mặc định; bật tại **Admin → Cấu hình hệ thống** sau khi kiểm tra bảng giá.

> `php artisan migrate:fresh --seed` chỉ dùng khi được phép xóa toàn bộ dữ liệu database local.

## 3. Chuẩn Bị Realtime Service

```powershell
cd service
npm install
Copy-Item .env.example .env
```

Trong `service/.env`:

```env
SERVICE_PORT=3000
SERVICE_HOST=0.0.0.0
WORKER_API_URL=http://127.0.0.1:8000/api/v1
REDIS_URL=redis://127.0.0.1:6379
MATCHING_OUTBOX_CHANNEL=worker.outbox
DRIVER_LOCATION_CHANNEL=worker.location
REALTIME_INTERNAL_TOKEN=<same_value_as_worker>
```

Push FCM là tùy chọn cho local, nhưng bắt buộc để test notification trên thiết bị thật:

```env
FIREBASE_CUSTOMER_PROJECT_ID=client-app-7fd27
FIREBASE_CUSTOMER_CLIENT_EMAIL=<service_account_client_email>
FIREBASE_CUSTOMER_PRIVATE_KEY="<service_account_private_key_with_escaped_newlines>"

FIREBASE_DRIVER_PROJECT_ID=drive-app-a31f9
FIREBASE_DRIVER_CLIENT_EMAIL=<service_account_client_email>
FIREBASE_DRIVER_PRIVATE_KEY="<service_account_private_key_with_escaped_newlines>"
```

Không commit `.env`, Firebase service-account JSON hoặc private key.

## 4. Chạy Backend Và Realtime

Mở hai terminal riêng:

```powershell
cd worker
composer run dev
```

Lệnh này chạy Laravel API tại `0.0.0.0:8000`, scheduler/outbox và Vite cho admin panel.

```powershell
cd service
npm run dev
```

Kiểm tra realtime service:

```powershell
Invoke-WebRequest http://127.0.0.1:3000/health
```

Admin panel chạy tại `http://127.0.0.1:8000/admin`.

## 5. Chạy Mobile

Cài dependencies một lần cho mỗi app:

```powershell
cd mobile/client
flutter pub get

cd ../driver
flutter pub get
```

### Android Emulator

`10.0.2.2` trỏ về máy host từ Android emulator:

```powershell
cd mobile/client
flutter run -d emulator-5554 `
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 `
  --dart-define=REALTIME_URL=http://10.0.2.2:3000 `
  --dart-define=GOONG_API_KEY=<goong_rest_key> `
  --dart-define=GOONG_MAP_KEY=<goong_map_key>
```

Chạy app driver với cùng các define, thay device id:

```powershell
cd mobile/driver
flutter run -d emulator-5556 `
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 `
  --dart-define=REALTIME_URL=http://10.0.2.2:3000 `
  --dart-define=GOONG_API_KEY=<goong_rest_key> `
  --dart-define=GOONG_MAP_KEY=<goong_map_key>
```

### Điện Thoại Trong LAN

Điện thoại và máy phát triển phải cùng Wi-Fi. Thay IP bằng địa chỉ IPv4 LAN của máy, ví dụ `192.168.1.6`:

```powershell
cd mobile/client
flutter run `
  --dart-define=API_BASE_URL=http://192.168.1.6:8000/api/v1 `
  --dart-define=REALTIME_URL=http://192.168.1.6:3000 `
  --dart-define=GOONG_API_KEY=<goong_rest_key> `
  --dart-define=GOONG_MAP_KEY=<goong_map_key>
```

Lặp lại lệnh trên trong `mobile/driver`. Build debug Android đã cho phép HTTP cleartext; nếu máy không truy cập được, cho phép inbound TCP port `8000` và `3000` trên Windows Firewall mạng Private.

> `.env` trong hai thư mục mobile chỉ là tài liệu giá trị local; source Flutter dùng `String.fromEnvironment`, nên bắt buộc truyền `--dart-define` khi chạy/build.

## 6. Kiểm Tra Luồng Chính

1. Tạo customer qua app khách và xác minh OTP (local dùng `OTP_TEST_CODE` trong worker env nếu có cấu hình).
2. Tạo/duyệt hồ sơ tài xế trong admin, đảm bảo xe/capability đã `APPROVED`.
3. Driver đăng nhập, cấp GPS và bật online.
4. Customer tạo đơn/chuyến; driver nhận offer và accept.
5. Customer tracking hiển thị điểm đón, điểm đến, route và vị trí tài xế khi driver gửi GPS.
6. Với FCM đã cấu hình: background app khách, accept offer từ app driver, sau đó kiểm tra notification `Tài xế đã nhận đơn`.

## 7. Kiểm Thử

```powershell
cd worker
php artisan test --no-coverage

cd ../service
npm run typecheck
npm test

cd ../mobile/client
flutter analyze
flutter test

cd ../driver
flutter analyze
flutter test
```

## 8. Xử Lý Lỗi Thường Gặp

| Triệu chứng | Kiểm tra |
|---|---|
| Mobile không gọi được API | Worker đang chạy, đúng `API_BASE_URL`, cùng Wi-Fi và firewall mở port `8000`. |
| Socket/realtime không kết nối | Service health trả `200`, đúng `REALTIME_URL`, Redis chạy và `REALTIME_INTERNAL_TOKEN` giống nhau ở worker/service. |
| Map chỉ có card fallback | Truyền `GOONG_MAP_KEY`; key REST và key tile map là hai biến riêng. |
| Driver không có marker GPS | Bật dịch vụ Location, cấp quyền app, kiểm tra status `GPS chính xác...` và truyền `GOONG_MAP_KEY`. |
| Push không gửi | Customer đã login sau khi cấp permission notification; `user_devices.push_token` có token; Firebase credential và internal token ở service đúng. |
| Redis extension không có | Dùng `REDIS_CLIENT=predis` rồi restart worker. |
