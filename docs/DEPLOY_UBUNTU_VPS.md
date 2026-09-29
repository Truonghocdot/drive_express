# Deploy Ubuntu VPS Không Docker

Tài liệu này triển khai `worker/` Laravel và `service/` realtime trên Ubuntu VPS. Laravel chạy qua Nginx + PHP-FPM, realtime chạy Node.js và các tiến trình dài hạn được Supervisor quản lý. Tất cả lệnh được chạy trong SSH dưới quyền `root`.

> Cảnh báo: chạy PHP/Node bằng `root` tăng rủi ro bảo mật. Chỉ dùng mô hình này cho VPS đồ án/được cô lập; production thực tế nên dùng user dịch vụ riêng.

## Kiến trúc

```text
api.example.com       -> Nginx -> PHP-FPM -> worker/public
realtime.example.com  -> Nginx -> Node service 127.0.0.1:3000
worker schedule:work  -> matching:dispatch / expire-offers / outbox:publish
PostgreSQL + Redis    -> localhost hoặc private network
```

Mobile production dùng `https://api.example.com/api/v1` và `https://realtime.example.com`.

## 1. Chuẩn bị VPS

Ví dụ dùng Ubuntu 24.04, mã nguồn tại `/var/www/html/drive`.

```bash
apt update && apt upgrade -y
apt install -y git unzip nginx supervisor postgresql redis-server \
  php8.3-fpm php8.3-cli php8.3-pgsql php8.3-mbstring php8.3-curl \
  php8.3-xml php8.3-zip php8.3-bcmath php8.3-redis

mkdir -p /var/www/html/drive
chown -R root:www-data /var/www/html/drive
```

Node.js phải là bản 20 trở lên. Kiểm tra bằng `node --version`, `npm --version` và `command -v node`.

## 2. PostgreSQL và Redis

```bash
runuser -u postgres -- psql
```

```sql
CREATE USER drive_app WITH PASSWORD 'CHANGE_THIS_DB_PASSWORD';
CREATE DATABASE drive OWNER drive_app;
\q
```

```bash
redis-cli ping
```

Kết quả Redis phải là `PONG`. Không mở cổng `5432` và `6379` ra Internet.

## 3. Cài worker Laravel

```bash
git clone <REPOSITORY_URL> /var/www/html/drive
cd /var/www/html/drive/worker
composer install --no-dev --prefer-dist --optimize-autoloader
npm ci
npm run build
cp .env.example .env
php artisan key:generate --force
```
Sửa `/var/www/html/drive/worker/.env`:

```env
APP_NAME=Drive
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.example.com
APP_LOCALE=vi
APP_FALLBACK_LOCALE=vi
CORS_ALLOWED_ORIGINS=https://api.example.com
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=drive
DB_USERNAME=drive_app
DB_PASSWORD=CHANGE_THIS_DB_PASSWORD
REDIS_CLIENT=phpredis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=null
CACHE_STORE=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
GOONG_API_KEY=CHANGE_THIS_GOONG_REST_KEY
VIETQR_BANK_CODE=MB
VIETQR_ACCOUNT_NUMBER=CHANGE_THIS_ACCOUNT
VIETQR_ACCOUNT_NAME=CHANGE_THIS_ACCOUNT_NAME
REALTIME_INTERNAL_TOKEN=CHANGE_THIS_LONG_RANDOM_TOKEN
LOG_CHANNEL=stack
LOG_STACK=single
LOG_LEVEL=warning
```

Khởi tạo production schema:

```bash
php artisan migrate --force
php artisan db:seed --class=RoleSeeder --force
php artisan db:seed --class=VehicleTypeSeeder --force
php artisan storage:link
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan app:create-admin-user 0901234567 --name="Administrator"
chown -R root:www-data /var/www/html/drive/worker
chmod -R ug+rwx /var/www/html/drive/worker/storage /var/www/html/drive/worker/bootstrap/cache
```

## 4. Cài realtime service

```bash
cd /var/www/html/drive/service
npm ci
cp .env.example .env
```

Sửa `/var/www/html/drive/service/.env`:

```env
SERVICE_HOST=127.0.0.1
SERVICE_PORT=3000
WORKER_API_URL=http://127.0.0.1/api/v1
REDIS_URL=redis://127.0.0.1:6379
MATCHING_OUTBOX_CHANNEL=worker.outbox
DRIVER_LOCATION_CHANNEL=worker.location
CORS_ALLOWED_ORIGINS=https://api.example.com
SERVICE_DEBUG=false
REALTIME_INTERNAL_TOKEN=CHANGE_THIS_LONG_RANDOM_TOKEN
```

`REALTIME_INTERNAL_TOKEN` phải giống worker. Thêm Firebase credential customer/driver nếu cần push production, không commit private key.

```bash
npm run build
test -f dist/server.js
```

## 5. Nginx và HTTPS

Tạo `/etc/nginx/sites-available/drive`:

```nginx
server {
    listen 80;
    server_name api.example.com;
    root /var/www/html/drive/worker/public;
    index index.php;
    client_max_body_size 20M;

    location / { try_files $uri $uri/ /index.php?$query_string; }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
    location ~ /\.ht { deny all; }
}

server {
    listen 80;
    server_name realtime.example.com;
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 75s;
    }
}
```

```bash
ln -s /etc/nginx/sites-available/drive.conf /etc/nginx/sites-enabled/drive.conf
nginx -t
systemctl reload nginx
apt install -y certbot python3-certbot-nginx
certbot --nginx -d api.apt-gra.site -d realtime.apt-gra.site
```

## 6. Supervisor

Tạo `/etc/supervisor/conf.d/drive.conf`:

```ini
[program:drive-scheduler]
command=/usr/bin/php /var/www/html/drive/worker/artisan schedule:work
directory=/var/www/html/drive/worker
user=root
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
redirect_stderr=true
stdout_logfile=/var/log/drive-scheduler.log
stopwaitsecs=3600

[program:drive-realtime]
command=/usr/bin/node /var/www/html/drive/service/dist/server.js
directory=/var/www/html/drive/service
user=root
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
redirect_stderr=true
stdout_logfile=/var/log/drive-realtime.log
environment=NODE_ENV="production"
stopwaitsecs=30
```

Nếu `command -v node` không phải `/usr/bin/node`, thay đường dẫn trong Supervisor.

```bash
systemctl enable --now supervisor
supervisorctl reread
supervisorctl update
supervisorctl status
```

Hai process phải là `RUNNING`. `schedule:work` đã chạy các lịch matching/expire/outbox trong `worker/routes/console.php`; không chạy thêm các lệnh đó bằng cron.

## 7. Firewall và kiểm tra

```bash
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw enable

curl -fsS https://api.apt-gra.site/up
curl -fsS https://realtime.apt-gra.site/health
redis-cli ping
supervisorctl status
tail -f /var/log/drive-scheduler.log
tail -f /var/log/drive-realtime.log
```

Không mở `3000`, `5432`, `6379` hoặc PHP-FPM ra Internet.

## 8. Cập nhật phiên bản

```bash
cd /var/www/html/drive
git pull --ff-only

cd worker
composer install --no-dev --prefer-dist --optimize-autoloader
npm ci && npm run build
php artisan migrate --force
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

cd ../service
npm ci && npm run build
supervisorctl restart drive-scheduler drive-realtime
systemctl reload php8.3-fpm
systemctl reload nginx
```

Không chạy `migrate:fresh` trên VPS production. Backup trước migration lớn:

```bash
runuser -u postgres -- pg_dump -Fc drive > /var/backups/drive-$(date +%F).dump
```

## 9. Mobile production

```bash
cd mobile/client
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.example.com/api/v1 \
  --dart-define=REALTIME_URL=https://realtime.example.com \
  --dart-define=GOONG_API_KEY=<goong_rest_key> \
  --dart-define=GOONG_MAP_KEY=<goong_map_key>

cd ../driver
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.example.com/api/v1 \
  --dart-define=REALTIME_URL=https://realtime.example.com \
  --dart-define=GOONG_API_KEY=<goong_rest_key> \
  --dart-define=GOONG_MAP_KEY=<goong_map_key>
```

`GOONG_MAP_KEY` dùng tile/map; `GOONG_API_KEY` dùng Directions/route.

## 10. Sự cố thường gặp

| Triệu chứng | Kiểm tra |
|---|---|
| API 502 | `php8.3-fpm`, socket Nginx và quyền `worker/storage`, `bootstrap/cache`. |
| Realtime không kết nối | Supervisor, `/health`, Redis và `REALTIME_INTERNAL_TOKEN`. |
| Không có matching/notification | `drive-scheduler` phải `RUNNING`; không chạy scheduler trùng bằng cron. |
| Map có nền nhưng không có đường | Truyền `GOONG_API_KEY`, không chỉ `GOONG_MAP_KEY`. |
| Supervisor restart liên tục | `supervisorctl tail -f drive-realtime stderr`; chạy thử `node dist/server.js` bằng `root`. |
| Mobile không gọi được VPS | DNS/HTTPS, UFW 80/443 và mobile dùng domain production thay vì localhost. |
