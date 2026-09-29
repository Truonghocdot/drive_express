# Flow 12 - Realtime, vị trí và thông báo

> Implementation status: `COMPLETED` in Phase 8. Personal notification rooms, authenticated identity and HTTPS fallback are implemented.

## Mục tiêu

Đồng bộ trạng thái/ETA/vị trí giữa khách và tài xế với độ trễ thấp, nhưng vẫn giữ API và database là nguồn dữ liệu chuẩn.

## Phân vai kênh

| Kênh | Dùng cho | Không dùng làm |
|---|---|---|
| HTTPS API | Command nghiệp vụ, query trạng thái chuẩn, upload evidence | Luồng vị trí tần suất cao |
| Socket.IO | Trạng thái tức thời, vị trí, ETA, presence | Nguồn quyết định transition cuối cùng |
| In-app chat | Tin nhắn giữa khách và tài xế trong đơn/chuyến active | Kênh quyết định trạng thái hoặc lưu thông tin thanh toán nhạy cảm |
| Push notification | Đánh thức app/thông báo khi background hoặc mất socket | Bảo đảm thứ tự event |
| Redis Pub/Sub | Chuyển event giữa backend và realtime worker | Database nghiệp vụ |
| Redis queue/cache | Queue job, presence, room metadata, vị trí gần nhất, geo search, lock/cache ngắn | Lịch sử chuẩn dài hạn |

## Xác thực và room

1. Client mở socket bằng access token ngắn hạn/đang hiệu lực.
2. Realtime service xác minh token và trạng thái user.
3. Server tự động đưa socket vào room cá nhân `user:{public_user_id}` sau khi worker xác thực `/me`.
4. Room `service-request:{service_request_public_id}` chỉ được join khi user là customer hoặc assigned driver được worker xác nhận.
5. Khi assignment đóng, token bị thu hồi hoặc quyền thay đổi, server phải remove socket khỏi room.
6. Không nhận `user_id`, `driver_id` hoặc room id do client tự khai mà chưa kiểm tra quyền.

Chat chỉ mở cho hai bên của assignment liên quan. Gọi điện dùng số điện thoại trực tiếp trong giai đoạn hiện tại; hệ thống chưa tích hợp nhà cung cấp gọi hoặc số ảo.

Thông báo in-app được lưu trong `notifications`; Socket.IO phát `notification:event` vào đúng `user:{public_user_id}`. Payload chỉ gồm id/type công khai, không gồm body chat, số tiền hoặc dữ liệu ledger. Khi socket/push lỗi, app đọc lại `/notifications` và `/notifications/unread` qua HTTPS.

Mobile đăng ký FCM token trong `user_devices.push_token` lúc login/verify phone. `CUSTOMER_APP` dùng Firebase project customer, `DRIVER_APP` dùng Firebase project driver; `service` lấy token theo `app_type` rồi gửi bằng Firebase Admin credential tương ứng. Token lỗi được worker đánh dấu `revoked_at`.

Để push chạy trên thiết bị thật, `service/.env` phải có `FIREBASE_CUSTOMER_PROJECT_ID`, `FIREBASE_CUSTOMER_CLIENT_EMAIL`, `FIREBASE_CUSTOMER_PRIVATE_KEY` của Firebase project customer và `REALTIME_INTERNAL_TOKEN` giống `worker/.env`. Worker scheduler phải chạy `outbox:publish`, đồng thời realtime service phải chạy để nhận Redis channel `worker.outbox`.

## Luồng A - Phát trạng thái

1. Laravel commit transition và outbox record.
2. Publisher gửi domain event vào Redis Pub/Sub với `event_id`, `aggregate_id`, `aggregate_version`, `occurred_at`.
3. Realtime service consume và deduplicate event.
4. Service phát event vào room liên quan.
5. `service` deduplicate/guard `aggregate_version`; mobile driver hiện dùng event làm signal rồi reload offers/notifications/snapshot qua HTTPS, không tự mutate state nghiệp vụ từ payload event.
6. Nếu socket mất hoặc reconnect, driver client authenticate lại và gọi worker API lấy snapshot mới nhất.

## Luồng A1 - Khách nhận thông báo tài xế đã nhận đơn

1. Tài xế accept offer qua `POST /driver/offers/{id}/respond`.
2. Worker commit assignment, chuyển request sang trạng thái đang đến điểm đón và tạo notification `SERVICE_DRIVER_ASSIGNED` cho customer trong cùng transaction.
3. `NotificationService` ghi `NOTIFICATION_CREATED` vào outbox; scheduler publish event lên Redis.
4. Realtime service gọi internal dispatch endpoint, lấy FCM token active của `CUSTOMER_APP` và gửi notification Firebase Admin SDK.
5. Khi app foreground, customer app refresh notification list và hiện snackbar. Khi chạm push từ background/terminated, app tải request chuẩn qua HTTPS rồi mở tracking screen.

## Luồng B - Vị trí tài xế

1. Khi online hoặc đang thực hiện dịch vụ, driver app gửi `lat`, `lng`, `accuracy`, `captured_at` mỗi 5 giây. Payload hiện không gửi `heading`/`speed` từ mobile driver.
2. Worker validate quyền, range, timestamp, accuracy và cập nhật heartbeat theo chu kỳ 5 giây; Redis presence vẫn dùng TTL 15 giây.
3. Vị trí gần nhất/presence được cập nhật trong Redis với TTL; database cập nhật một snapshot `last_location` và `last_location_at` cho tài xế.
4. Khi có assignment, vị trí đã làm mờ/đủ dùng được phát vào đúng booking room.
5. Sample mới ghi đè vị trí cũ; không persist timeline hoặc lịch sử hành trình.
6. Khi offline hoặc TTL hết hạn, tài xế bị loại khỏi geo search; snapshot cuối vẫn dùng để hiển thị lần định vị cuối cùng cùng timestamp.

## Event envelope đề xuất

```json
{
  "event_id": "uuid",
  "event_type": "RIDE_DRIVER_ARRIVED",
  "aggregate_type": "SERVICE_REQUEST",
  "aggregate_id": 123,
  "aggregate_version": 7,
  "occurred_at": "2026-09-21T10:00:00Z",
  "payload": {}
}
```

Payload gửi client chỉ chứa dữ liệu cần hiển thị. Event nội bộ có dữ liệu nhạy cảm phải được chuyển thành public event đã lọc trước khi broadcast.

## Reconnect và fallback

1. Client dùng exponential backoff có jitter khi reconnect.
2. Sau reconnect, client authenticate lại và gọi API sync snapshot.
3. Event quan trọng như offer, assigned, arrived, cancelled, completed có push fallback. `service` gửi FCM qua Firebase Admin; customer và driver dùng hai Firebase project riêng.
4. Push chỉ báo có thay đổi; khi mở app client lấy trạng thái chuẩn qua API.
5. Command nghiệp vụ khi socket lỗi luôn đi qua HTTPS, không phụ thuộc socket.

## Tính tin cậy

- Consumer xử lý at-least-once, do đó mọi handler phải idempotent.
- `event_id` có kho dedup/unique phù hợp.
- `aggregate_version` xử lý event đến sai thứ tự.
- Outbox record lỗi được đánh dấu `FAILED`, tăng backoff và replay có kiểm soát từ Redis Pub/Sub.
- Outbox bảo đảm không mất event giữa database commit và publish.
- Correlation id đi xuyên API, outbox, queue và log.

## Sự kiện public tối thiểu

- `OFFER_CREATED`, `OFFER_EXPIRED`
- `DRIVER_ASSIGNED`, `DRIVER_LOCATION_UPDATED`
- `DRIVER_ARRIVED`
- `DELIVERY_PICKED_UP`, `DELIVERY_DELIVERED`, `DELIVERY_COMPLETED`
- `RIDE_STARTED`, `RIDE_COMPLETED`
- `BOOKING_CANCELLED`, `PAYMENT_STATUS_CHANGED`
- `CHAT_MESSAGE_CREATED`, `NOTIFICATION_CREATED`, `SUPPORT_TICKET_CREATED`, `SUPPORT_TICKET_RESOLVED`
- `INCIDENT_REPORTED`, `SAFETY_INCIDENT_REPORTED`, `INCIDENT_RESOLVED`, `LOW_RATING_FLAGGED`

Tên public event có thể thêm namespace/version (`delivery.picked_up.v1`) khi chốt contract.

## Tiêu chí nghiệm thu

- User không liên quan không thể join room hoặc nhận vị trí.
- Event lặp/sai thứ tự không làm UI lùi trạng thái.
- Reconnect luôn đồng bộ lại snapshot chuẩn.
- Vị trí hết TTL loại tài xế khỏi matching.
- Server rate limit và Redis TTL phải tương thích với chu kỳ vị trí 5 giây và TTL presence 15 giây.
- Database chỉ có một snapshot vị trí cuối trên mỗi tài xế; không phát sinh bản ghi lịch sử theo từng sample.
- Redis/realtime tạm ngừng không làm mất transaction nghiệp vụ; event được phát lại từ outbox.
