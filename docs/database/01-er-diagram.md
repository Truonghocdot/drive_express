# ERD Triển Khai

> Nguồn chuẩn: `worker/database/migrations/`. Sơ đồ này mô tả schema hiện hành, gồm commerce/loyalty và dịch vụ `HOURLY`.

## Tổng quan domain

```mermaid
flowchart LR
  I[Identity & Access] --> D[Driver & Catalog]
  D --> B[Quote, Booking & Matching]
  B --> F[Finance & Commerce]
  B --> S[Support & Realtime]
  I --> F
  I --> S
```

Khóa chính nội bộ dùng `id BIGINT`; resource public có `public_id UUID` khi cần lộ qua API. Các diagram chỉ nêu cột khóa/foreign key và các cột nghiệp vụ quyết định quan hệ.

## Identity, Driver Và Catalog

```mermaid
erDiagram
  USERS {
    bigint id PK
    uuid public_id UK
    string phone UK
    string status
  }
  ROLES { bigint id PK string key UK }
  USER_ROLES { bigint user_id FK bigint role_id FK bigint granted_by FK }
  USER_DEVICES { bigint id PK bigint user_id FK string app_type string push_token }
  PHONE_VERIFICATIONS { bigint id PK bigint user_id FK string purpose }
  PHONE_PASSWORD_RESET_TOKENS { bigint id PK bigint user_id FK string token_hash UK }
  DRIVER_PROFILES { bigint id PK uuid public_id UK bigint user_id FK bigint reviewed_by FK string review_status }
  DRIVER_DOCUMENTS { bigint id PK bigint driver_profile_id FK bigint vehicle_id FK bigint reviewed_by FK }
  DRIVER_BANK_ACCOUNTS { bigint id PK bigint driver_profile_id FK bigint reviewed_by FK }
  VEHICLE_TYPES { bigint id PK uuid public_id UK string unique_key UK }
  VEHICLES { bigint id PK uuid public_id UK bigint driver_profile_id FK bigint vehicle_type_id FK }
  DRIVER_SERVICE_CAPABILITIES { bigint id PK bigint driver_profile_id FK bigint vehicle_type_id FK bigint approved_by FK }
  DRIVER_LAST_LOCATIONS { bigint driver_profile_id PK jsonb last_location }
  PRICING_RULES { bigint id PK uuid public_id UK string service_type bigint vehicle_type_id FK bigint created_by FK }
  SERVICE_AREAS { bigint id PK string service_type bool is_active }
  SYSTEM_SETTINGS { string key PK bigint updated_by FK jsonb value }

  USERS ||--o{ USER_ROLES : has
  ROLES ||--o{ USER_ROLES : grants
  USERS ||--o{ USER_ROLES : grants_role
  USERS ||--o{ USER_DEVICES : owns
  USERS ||--o{ PHONE_VERIFICATIONS : verifies
  USERS ||--o{ PHONE_PASSWORD_RESET_TOKENS : resets
  USERS ||--o| DRIVER_PROFILES : owns
  USERS ||--o{ DRIVER_PROFILES : reviews
  DRIVER_PROFILES ||--o{ DRIVER_DOCUMENTS : submits
  VEHICLES o|--o{ DRIVER_DOCUMENTS : documents
  USERS ||--o{ DRIVER_DOCUMENTS : reviews
  DRIVER_PROFILES ||--o{ DRIVER_BANK_ACCOUNTS : receives
  USERS ||--o{ DRIVER_BANK_ACCOUNTS : reviews
  DRIVER_PROFILES ||--o{ VEHICLES : owns
  VEHICLE_TYPES ||--o{ VEHICLES : classifies
  DRIVER_PROFILES ||--o{ DRIVER_SERVICE_CAPABILITIES : enables
  VEHICLE_TYPES ||--o{ DRIVER_SERVICE_CAPABILITIES : supports
  USERS ||--o{ DRIVER_SERVICE_CAPABILITIES : approves
  DRIVER_PROFILES ||--o| DRIVER_LAST_LOCATIONS : snapshots
  VEHICLE_TYPES ||--o{ PRICING_RULES : prices
  USERS ||--o{ PRICING_RULES : creates
  USERS ||--o{ SYSTEM_SETTINGS : updates
```

## Quote, Booking Và Matching

```mermaid
erDiagram
  USERS { bigint id PK }
  VEHICLE_TYPES { bigint id PK }
  PRICING_RULES { bigint id PK }
  QUOTES {
    bigint id PK
    uuid public_id UK
    bigint requested_by FK
    bigint vehicle_type_id FK
    bigint pricing_rule_id FK
    string service_type
    jsonb pickup_snapshot
    jsonb dropoff_snapshot
  }
  SERVICE_REQUESTS {
    bigint id PK
    uuid public_id UK
    bigint created_by FK
    bigint vehicle_type_id FK
    bigint quote_id FK
    string service_type
    string status
  }
  SERVICE_STOPS { bigint id PK bigint service_request_id FK string stop_type }
  DELIVERY_ORDERS { bigint service_request_id PK bigint sender_user_id FK bigint recipient_user_id FK }
  RIDE_BOOKINGS { bigint service_request_id PK int passenger_count int duration_hours }
  DRIVER_OFFERS { bigint id PK uuid public_id UK bigint service_request_id FK bigint driver_profile_id FK }
  ASSIGNMENTS { bigint id PK uuid public_id UK bigint service_request_id FK bigint driver_profile_id FK bigint vehicle_id FK bigint accepted_offer_id FK }
  SERVICE_STATUS_HISTORIES { bigint id PK bigint service_request_id FK bigint actor_user_id FK int version }
  DELIVERY_RETURN_REVISIONS { bigint id PK bigint delivery_order_id FK bigint requested_by FK }

  USERS ||--o{ QUOTES : requests
  VEHICLE_TYPES ||--o{ QUOTES : quoted_for
  PRICING_RULES ||--o{ QUOTES : snapshots
  QUOTES ||--o| SERVICE_REQUESTS : becomes
  USERS ||--o{ SERVICE_REQUESTS : creates
  VEHICLE_TYPES ||--o{ SERVICE_REQUESTS : requires
  SERVICE_REQUESTS ||--|{ SERVICE_STOPS : contains
  SERVICE_REQUESTS ||--o| DELIVERY_ORDERS : delivery_detail
  SERVICE_REQUESTS ||--o| RIDE_BOOKINGS : ride_or_hourly_detail
  USERS ||--o{ DELIVERY_ORDERS : sends
  USERS ||--o{ DELIVERY_ORDERS : receives
  SERVICE_REQUESTS ||--o{ DRIVER_OFFERS : broadcasts
  DRIVER_PROFILES ||--o{ DRIVER_OFFERS : receives
  SERVICE_REQUESTS ||--o{ ASSIGNMENTS : assigns
  DRIVER_PROFILES ||--o{ ASSIGNMENTS : performs
  VEHICLES ||--o{ ASSIGNMENTS : uses
  DRIVER_OFFERS o|--o| ASSIGNMENTS : accepted_by
  SERVICE_REQUESTS ||--o{ SERVICE_STATUS_HISTORIES : transitions
  USERS ||--o{ SERVICE_STATUS_HISTORIES : acts
  DELIVERY_ORDERS ||--o{ DELIVERY_RETURN_REVISIONS : revises
  USERS ||--o{ DELIVERY_RETURN_REVISIONS : requests
```

`DELIVERY` có `DELIVERY_ORDERS`; `DRIVE` và `HOURLY` dùng `RIDE_BOOKINGS`. `HOURLY` chỉ bắt buộc pickup, `duration_hours` từ 1 đến 12 và quote có `dropoff_snapshot = NULL`.

## Finance, Voucher Và Loyalty

```mermaid
erDiagram
  USERS { bigint id PK }
  LEDGER_ACCOUNTS { bigint id PK uuid public_id UK bigint owner_user_id FK string code UK }
  WALLETS { bigint id PK uuid public_id UK bigint user_id FK bigint ledger_account_id FK }
  LEDGER_TRANSACTIONS { bigint id PK uuid public_id UK string idempotency_key UK }
  LEDGER_ENTRIES { bigint id PK bigint ledger_transaction_id FK bigint ledger_account_id FK }
  PAYMENTS { bigint id PK uuid public_id UK bigint service_request_id FK bigint payer_user_id FK bigint customer_payment_ledger_id FK }
  VOUCHERS { bigint id PK uuid public_id UK bigint created_by FK bigint owner_user_id FK string code UK }
  VOUCHER_REDEMPTIONS { bigint id PK bigint voucher_id FK bigint user_id FK bigint service_request_id FK }
  DISCOUNT_TRANSACTIONS { bigint id PK uuid public_id UK bigint payment_id FK bigint voucher_redemption_id FK }
  SETTLEMENTS { bigint id PK uuid public_id UK bigint payment_id FK bigint assignment_id FK bigint driver_profile_id FK bigint earning_ledger_id FK bigint platform_fee_ledger_id FK }
  SETTLEMENT_REVISIONS { bigint id PK bigint settlement_id FK bigint ledger_transaction_id FK bigint approved_by FK }
  WALLET_TOPUPS { bigint id PK uuid public_id UK bigint wallet_id FK }
  WITHDRAWAL_REQUESTS { bigint id PK uuid public_id UK bigint wallet_id FK bigint driver_bank_account_id FK bigint handled_by FK bigint ledger_transaction_id FK }
  REFUNDS { bigint id PK uuid public_id UK bigint payment_id FK bigint requested_by FK bigint approved_by FK bigint ledger_transaction_id FK }
  COD_ACCOUNTS { bigint id PK bigint delivery_order_id FK bigint driver_profile_id FK }
  COD_TRANSACTIONS { bigint id PK bigint cod_account_id FK bigint actor_user_id FK }
  LOYALTY_ACCOUNTS { bigint id PK uuid public_id UK bigint user_id FK string tier }
  LOYALTY_REWARDS { bigint id PK uuid public_id UK bigint created_by FK int points_cost }
  LOYALTY_TRANSACTIONS { bigint id PK uuid public_id UK bigint user_id FK string idempotency_key UK }

  USERS ||--o{ LEDGER_ACCOUNTS : owns_optional
  USERS ||--o{ WALLETS : owns
  LEDGER_ACCOUNTS ||--o| WALLETS : backs
  LEDGER_TRANSACTIONS ||--|{ LEDGER_ENTRIES : posts
  LEDGER_ACCOUNTS ||--o{ LEDGER_ENTRIES : receives
  SERVICE_REQUESTS ||--|| PAYMENTS : pays
  USERS ||--o{ PAYMENTS : pays_for
  LEDGER_TRANSACTIONS o|--o{ PAYMENTS : customer_payment
  USERS ||--o{ VOUCHERS : creates
  USERS ||--o{ VOUCHERS : owns_reward
  VOUCHERS ||--o{ VOUCHER_REDEMPTIONS : redeems
  USERS ||--o{ VOUCHER_REDEMPTIONS : uses
  SERVICE_REQUESTS ||--o| VOUCHER_REDEMPTIONS : applies
  PAYMENTS ||--o| DISCOUNT_TRANSACTIONS : discounts
  VOUCHER_REDEMPTIONS ||--o| DISCOUNT_TRANSACTIONS : records
  PAYMENTS ||--o| SETTLEMENTS : settles
  ASSIGNMENTS ||--o| SETTLEMENTS : earns
  DRIVER_PROFILES ||--o{ SETTLEMENTS : receives
  LEDGER_TRANSACTIONS o|--o{ SETTLEMENTS : posts_earning
  SETTLEMENTS ||--o{ SETTLEMENT_REVISIONS : adjusts
  LEDGER_TRANSACTIONS o|--o{ SETTLEMENT_REVISIONS : records
  USERS ||--o{ SETTLEMENT_REVISIONS : approves
  WALLETS ||--o{ WALLET_TOPUPS : tops_up
  WALLETS ||--o{ WITHDRAWAL_REQUESTS : withdraws
  DRIVER_BANK_ACCOUNTS ||--o{ WITHDRAWAL_REQUESTS : receives
  USERS ||--o{ WITHDRAWAL_REQUESTS : handles
  PAYMENTS ||--o{ REFUNDS : refunds
  LEDGER_TRANSACTIONS o|--o{ REFUNDS : posts
  DELIVERY_ORDERS ||--o| COD_ACCOUNTS : tracks
  DRIVER_PROFILES ||--o{ COD_ACCOUNTS : holds
  COD_ACCOUNTS ||--o{ COD_TRANSACTIONS : records
  USERS ||--o{ COD_TRANSACTIONS : acts
  USERS ||--o| LOYALTY_ACCOUNTS : owns
  USERS ||--o{ LOYALTY_REWARDS : creates
  USERS ||--o{ LOYALTY_TRANSACTIONS : earns_or_redeems
```

`LOYALTY_TRANSACTIONS.reference_type/reference_id` là reference đa hình: service request khi earn, reward khi redeem và refund khi reverse. Voucher đổi điểm dùng `VOUCHERS.owner_user_id`, nên chỉ user sở hữu mới preview/redeem được.

## Support, Notification Và Integration

```mermaid
erDiagram
  USERS { bigint id PK }
  SERVICE_REQUESTS { bigint id PK }
  ASSIGNMENTS { bigint id PK }
  RATINGS { bigint id PK bigint service_request_id FK bigint assignment_id FK bigint reviewer_id FK bigint reviewee_id FK }
  SUPPORT_TICKETS { bigint id PK uuid public_id UK bigint opened_by FK bigint assigned_to FK bigint service_request_id FK }
  SUPPORT_TICKET_MESSAGES { bigint id PK bigint support_ticket_id FK bigint sender_user_id FK }
  TICKET_ATTACHMENTS { bigint id PK bigint support_ticket_id FK bigint uploaded_by FK }
  INCIDENTS { bigint id PK uuid public_id UK bigint service_request_id FK bigint reported_by FK bigint assigned_to FK }
  SERVICE_EVIDENCES { bigint id PK uuid public_id UK bigint service_request_id FK bigint assignment_id FK bigint uploaded_by FK }
  CHAT_CONVERSATIONS { bigint id PK uuid public_id UK bigint service_request_id FK bigint assignment_id FK }
  CHAT_MESSAGES { bigint id PK uuid public_id UK bigint chat_conversation_id FK bigint sender_user_id FK }
  NOTIFICATIONS { uuid id PK bigint user_id FK }
  AUDIT_LOGS { bigint id PK bigint actor_user_id FK }
  OUTBOX_EVENTS { bigint id PK uuid event_id UK }
  INBOX_MESSAGES { bigint id PK string consumer string message_id }
  IDEMPOTENCY_KEYS { bigint id PK bigint user_id FK string key }
  WEBHOOK_RECEIPTS { bigint id PK string provider string event_id }

  SERVICE_REQUESTS ||--o{ RATINGS : rated_for
  ASSIGNMENTS ||--o{ RATINGS : identifies_driver
  USERS ||--o{ RATINGS : writes_or_receives
  USERS ||--o{ SUPPORT_TICKETS : opens_or_handles
  SERVICE_REQUESTS ||--o{ SUPPORT_TICKETS : concerns
  SUPPORT_TICKETS ||--o{ SUPPORT_TICKET_MESSAGES : contains
  USERS ||--o{ SUPPORT_TICKET_MESSAGES : writes
  SUPPORT_TICKETS ||--o{ TICKET_ATTACHMENTS : contains
  USERS ||--o{ TICKET_ATTACHMENTS : uploads
  SERVICE_REQUESTS ||--o{ INCIDENTS : reports
  USERS ||--o{ INCIDENTS : reports_or_handles
  SERVICE_REQUESTS ||--o{ SERVICE_EVIDENCES : proves
  ASSIGNMENTS ||--o{ SERVICE_EVIDENCES : creates
  USERS ||--o{ SERVICE_EVIDENCES : uploads
  SERVICE_REQUESTS ||--o{ CHAT_CONVERSATIONS : has
  ASSIGNMENTS ||--o| CHAT_CONVERSATIONS : scopes
  CHAT_CONVERSATIONS ||--o{ CHAT_MESSAGES : contains
  USERS ||--o{ CHAT_MESSAGES : sends
  USERS ||--o{ NOTIFICATIONS : receives
  USERS ||--o{ AUDIT_LOGS : acts
  USERS ||--o{ IDEMPOTENCY_KEYS : owns
```

`AUDIT_LOGS`, `OUTBOX_EVENTS`, `INBOX_MESSAGES`, `IDEMPOTENCY_KEYS` và `WEBHOOK_RECEIPTS` là bảng integration/technical. Reference `aggregate_type + aggregate_id`, `subject_type + subject_id`, `resource_type + resource_id` được validation ở application layer nên không có đường FK tổng quát trên ERD.

## Ràng Buộc Không Thể Hiện Chỉ Bằng FK

| Quy tắc | Cơ chế thực thi |
|---|---|
| Một assignment `ACTIVE` cho mỗi request và mỗi driver | Partial unique index PostgreSQL |
| Một pickup; delivery/drive có một dropoff | Unique `(service_request_id, stop_type)` + validation service |
| Quote chỉ tạo một service request | `service_requests.quote_id UNIQUE` |
| Payment/settlement/discount transaction một-một | Unique foreign key tương ứng |
| Ledger debit bằng credit | `LedgerService` + feature test |
| Voucher owner chỉ dùng voucher của chính mình | `VoucherPreviewService` |
| Loyalty không âm và redeem idempotent | Transaction, row lock `loyalty_accounts`, unique idempotency key |
| `HOURLY` chỉ pickup, 1-12 giờ và feature flag | Request validation + pricing/booking service |

## Bảng Framework Ngoài ERD

Laravel/Sanctum tạo thêm `personal_access_tokens`, `jobs`, `job_batches`, `failed_jobs`, `cache` và migration metadata. Chúng là bảng hạ tầng, không phải quan hệ nghiệp vụ chính nên được giữ ngoài sơ đồ.
