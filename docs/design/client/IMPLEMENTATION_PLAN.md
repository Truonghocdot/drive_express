# Đối chiếu thiết kế và kế hoạch phát triển Client

## 1. Kết luận nhanh

Thiết kế trong thư mục này đã định hình một app mobility/express có 4 luồng chính:

- **Trang chủ:** tìm điểm đến, đặt xe/giao hàng, đơn đang theo dõi, điểm đến gần đây.
- **Hoạt động:** đơn đang diễn ra và lịch sử.
- **Ưu đãi:** voucher, điểm thành viên, đối tác đổi điểm.
- **Tài khoản:** hồ sơ, ví, tiện ích, hỗ trợ và đăng xuất.

Ứng dụng Flutter hiện tại đã có nghiệp vụ đặt xe, giao hàng, tracking, lịch sử, ví, thông báo và hỗ trợ nhưng shell chỉ có 3 tab. UI cũ phụ thuộc nhiều vào `Card`/`ListTile` mặc định, màu xanh nâu chưa khớp design token và chưa có trang Ưu đãi.

## 2. So sánh hiện trạng

| Khu vực | Thiết kế | Hiện trạng trước thay đổi | Xử lý trong đợt này |
| --- | --- | --- | --- |
| Brand | Emerald `#054A3E`, mint, nền xanh lạnh, radius 12–20 | Xanh `#146B52`, accent cam, radius nhỏ | Đã cập nhật `ClientTheme` và token Material 3 |
| Navigation | 4 tab: Trang chủ / Hoạt động / Ưu đãi / Tài khoản | 3 tab: Trang chủ / Đơn hàng / Tài khoản | Đã thêm tab Ưu đãi và đổi nhãn Hoạt động |
| Header | Eyebrow vị trí, chuông, avatar, safe area | AppBar tiêu đề đơn giản | Đã thay bằng header có trạng thái thông báo và avatar |
| Trang chủ | Search hub, 4 service tiles, promo, recent destinations | Banner CTA, 3 service tiles | Đã triển khai; Thuê giờ hiển thị trạng thái đang phát triển |
| Hoạt động | Segmented tabs, active route card, history cards | TabBar và ListTile phẳng | Đã triển khai route card và thẻ lịch sử mới |
| Tài khoản | Profile, wallet card, grouped settings, logout | Danh sách card rời | Đã nhóm lại theo section và thêm wallet surface |
| Ưu đãi | Member card, voucher, partner points | Chưa có | Đã nối voucher catalog, loyalty account/reward và redeem voucher |
| Typography | Plus Jakarta Sans + Inter | Font mặc định Flutter | Đã chuẩn hóa cấp chữ; font brand cần bổ sung asset nếu cần pixel-match |

## 3. Kế hoạch phát triển tiếp theo

### P0 — Hoàn thiện nghiệp vụ hiện có

1. Đã nối `PromotionsPage` với voucher catalog, loyalty account/reward và truyền voucher vào `BookingDraft`.
2. Đã thêm địa chỉ yêu thích local-only, tối đa 10 mục/account, dùng lại trong Home/Profile.
3. Nối active card với dữ liệu tài xế/ảnh/avatar, gọi điện và chat từ tracking snapshot.
4. Bổ sung trạng thái loading/skeleton và retry inline cho Home, Activity, Profile.

### P1 — Đồng bộ thiết kế sản phẩm

1. Thêm font Plus Jakarta Sans và Inter dạng asset, kiểm tra fallback tiếng Việt.
2. Chuẩn hóa icon theo một bộ icon duy nhất thay cho các icon Material còn lại.
3. Thêm dark theme tương ứng với semantic token của design system.
4. Chụp kiểm thử UI ở 320px, 375px, 430px và tablet; kiểm tra không che bởi navigation bar/safe area.

### P2 — Tính năng mở rộng

1. Đã thêm `ServiceKind.hourly`, pricing/quote/booking và driver transition; bật bằng `features.hourly_enabled` sau khi tạo pricing rule.
2. Thêm phương thức thanh toán và deep link từ notification đến active order, voucher hoặc ticket.
3. Reward đối tác Cafe/CGV vẫn để sau; phase hiện tại đổi điểm lấy voucher admin tạo.

## 4. Tiêu chí nghiệm thu UI

- Tất cả tap target chính đạt tối thiểu 44–48dp và có pressed state.
- Màu chữ chính đạt tương phản tối thiểu WCAG AA trên surface tương ứng.
- Không overflow ở màn hình rộng 320px và khi text tiếng Việt dài.
- Nội dung cuộn có khoảng đệm dưới navigation bar; modal có đường thoát rõ ràng.
- Nghiệp vụ cũ (đăng nhập, đặt xe, giao hàng, quote, tracking, logout) không thay đổi contract API.

## 5. Phạm vi đã apply

- `mobile/client/lib/presentation/theme/app_theme.dart`
- `mobile/client/lib/presentation/pages/main_navigation_page.dart`
- `mobile/client/lib/presentation/pages/home/home_page.dart`
- `mobile/client/lib/presentation/pages/order/order_history_page.dart`
- `mobile/client/lib/presentation/pages/profile/profile_page.dart`
- `mobile/client/lib/presentation/pages/promotion/promotions_page.dart`
- `worker/routes/api.php` và các resource/service loyalty, promotion, hourly booking
- `mobile/driver/lib/presentation/pages/auth/driver_kyc_page.dart`
