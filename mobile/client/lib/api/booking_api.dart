import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_transport.dart';
import 'push_token_provider.dart';
import 'request_id.dart';

enum ServiceKind {
  delivery('DELIVERY'),
  drive('DRIVE'),
  hourly('HOURLY');

  const ServiceKind(this.apiValue);
  final String apiValue;
}

enum PaymentChoice {
  wallet('WALLET'),
  cash('CASH');

  const PaymentChoice(this.apiValue);
  final String apiValue;
}

enum PayerChoice {
  orderer('ORDERER'),
  recipient('RECIPIENT');

  const PayerChoice(this.apiValue);
  final String apiValue;
}

class BookingSession {
  const BookingSession({
    required this.baseUrl,
    required this.token,
    required this.vehicleTypeId,
  });

  final String baseUrl;
  final String token;
  final String vehicleTypeId;

  BookingSession copyWith({
    String? baseUrl,
    String? token,
    String? vehicleTypeId,
  }) {
    return BookingSession(
      baseUrl: baseUrl ?? this.baseUrl,
      token: token ?? this.token,
      vehicleTypeId: vehicleTypeId ?? this.vehicleTypeId,
    );
  }
}

class VehicleOption {
  const VehicleOption({
    required this.id,
    required this.key,
    required this.name,
  });

  final String id;
  final String key;
  final String name;

  factory VehicleOption.fromJson(Map<String, dynamic> json) {
    return VehicleOption(
      id: json['id'] as String,
      key: json['key'] as String,
      name: json['name'] as String,
    );
  }
}

class LocationDraft {
  const LocationDraft({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() => {
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class BookingDraft {
  const BookingDraft({
    required this.service,
    required this.pickup,
    this.dropoff,
    required this.goodsType,
    required this.weightKg,
    required this.passengerCount,
    this.voucherCode,
    this.scheduledAt,
    this.vehicleTypeId,
    this.vehicleTypeIds,
    this.passengerName,
    this.passengerPhone,
    this.durationHours,
  });

  final ServiceKind service;
  final LocationDraft pickup;
  final LocationDraft? dropoff;
  final String goodsType;
  final double weightKg;
  final int passengerCount;
  final String? voucherCode;
  final DateTime? scheduledAt;
  final String? vehicleTypeId;
  final List<String>? vehicleTypeIds;
  final String? passengerName;
  final String? passengerPhone;
  final int? durationHours;
}

class QuoteSummary {
  const QuoteSummary({
    required this.id,
    required this.service,
    required this.grossFare,
    required this.voucherDiscount,
    required this.customerPayable,
    required this.currency,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.expiresAt,
    this.vehicleTypeId,
    this.vehicleKey,
    this.vehicleName,
  });

  final String id;
  final ServiceKind service;
  final double grossFare;
  final double voucherDiscount;
  final double customerPayable;
  final String currency;
  final double distanceMeters;
  final int durationSeconds;
  final DateTime expiresAt;
  final String? vehicleTypeId;
  final String? vehicleKey;
  final String? vehicleName;

  factory QuoteSummary.fromJson(Map<String, dynamic> json) {
    final pricing = json['pricing'] as Map<String, dynamic>;
    final route = json['route'] as Map<String, dynamic>;
    final vehicle = json['vehicle_type'] as Map<String, dynamic>?;

    return QuoteSummary(
      id: json['id'] as String,
      service: _serviceKind(json['service_type']),
      grossFare: _doubleValue(pricing['gross_fare']),
      voucherDiscount: _doubleValue(pricing['voucher_discount']),
      customerPayable: _doubleValue(pricing['customer_payable']),
      currency: pricing['currency'] as String,
      distanceMeters: _doubleValue(route['distance_meters']),
      durationSeconds: _intValue(route['duration_seconds']),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      vehicleTypeId: vehicle?['id']?.toString(),
      vehicleKey: vehicle?['key']?.toString(),
      vehicleName: vehicle?['name']?.toString(),
    );
  }
}

class ServiceRequestSummary {
  const ServiceRequestSummary({
    required this.id,
    required this.service,
    required this.status,
    required this.paymentMethod,
    required this.customerPayable,
    this.driverNetEarning,
    this.bookingType = 'NOW',
    this.pickupAddress,
    this.dropoffAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.createdAt,
  });

  final String id;
  final ServiceKind service;
  final String status;
  final PaymentChoice paymentMethod;
  final double customerPayable;
  final double? driverNetEarning;
  final String bookingType;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final DateTime? createdAt;

  factory ServiceRequestSummary.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>;
    final settlement = payment['settlement'];
    final stops = (json['stops'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final pickup = stops.where((stop) => stop['type'] == 'PICKUP').firstOrNull;
    final dropoff = stops
        .where((stop) => stop['type'] == 'DROPOFF')
        .firstOrNull;

    return ServiceRequestSummary(
      id: json['id'] as String,
      service: _serviceKind(json['service_type']),
      status: json['status'] as String,
      paymentMethod: payment['method'] == PaymentChoice.wallet.apiValue
          ? PaymentChoice.wallet
          : PaymentChoice.cash,
      customerPayable: _doubleValue(payment['customer_payable']),
      driverNetEarning: settlement is Map<String, dynamic>
          ? (settlement['driver_net_earning'] as num?)?.toDouble()
          : null,
      bookingType: json['booking_type']?.toString() ?? 'NOW',
      pickupAddress: pickup?['address']?.toString(),
      dropoffAddress: dropoff?['address']?.toString(),
      pickupLatitude: (pickup?['latitude'] as num?)?.toDouble(),
      pickupLongitude: (pickup?['longitude'] as num?)?.toDouble(),
      dropoffLatitude: (dropoff?['latitude'] as num?)?.toDouble(),
      dropoffLongitude: (dropoff?['longitude'] as num?)?.toDouble(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'].toString()),
    );
  }
}

class LiveLocationSummary {
  const LiveLocationSummary({
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.accuracy,
    this.heading,
    this.speed,
  });

  final double latitude;
  final double longitude;
  final DateTime capturedAt;
  final double? accuracy;
  final double? heading;
  final double? speed;

  factory LiveLocationSummary.fromJson(Map<String, dynamic> json) {
    return LiveLocationSummary(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      capturedAt: DateTime.parse(json['captured_at'].toString()),
    );
  }
}

class TrackingSummary {
  const TrackingSummary({
    required this.requestId,
    required this.status,
    required this.statusMeta,
    required this.stops,
    required this.locationStale,
    this.driverName,
    this.vehiclePlate,
    this.vehicleType,
    this.liveLocation,
  });

  final String requestId;
  final String status;
  final Map<String, dynamic> statusMeta;
  final List<Map<String, dynamic>> stops;
  final bool locationStale;
  final String? driverName;
  final String? vehiclePlate;
  final String? vehicleType;
  final LiveLocationSummary? liveLocation;

  factory TrackingSummary.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>?;
    final vehicle = driver?['vehicle'] as Map<String, dynamic>?;
    final location = json['live_location'] as Map<String, dynamic>?;
    return TrackingSummary(
      requestId: json['id'] as String,
      status: json['status'] as String,
      statusMeta:
          (json['status_meta'] as Map?)?.cast<String, dynamic>() ?? const {},
      stops: (json['stops'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false),
      locationStale: json['location_stale'] == true,
      driverName: driver?['name']?.toString(),
      vehiclePlate: vehicle?['plate_number']?.toString(),
      vehicleType: vehicle?['type']?.toString(),
      liveLocation: location == null
          ? null
          : LiveLocationSummary.fromJson(location),
    );
  }
}

class WalletSummary {
  const WalletSummary({
    required this.id,
    required this.balance,
    required this.reserved,
    required this.available,
    required this.currency,
  });

  final String id;
  final double balance;
  final double reserved;
  final double available;
  final String currency;

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      id: json['id'] as String,
      balance: (json['balance'] as num).toDouble(),
      reserved: (json['reserved_withdrawal_amount'] as num).toDouble(),
      available: (json['available_balance'] as num).toDouble(),
      currency: json['currency'] as String,
    );
  }
}

class WalletTopupSummary {
  const WalletTopupSummary({
    required this.id,
    required this.amount,
    required this.status,
    required this.reference,
    required this.vietQrPayload,
    this.vietQrImageUrl,
  });

  final String id;
  final double amount;
  final String status;
  final String reference;
  final String vietQrPayload;
  final String? vietQrImageUrl;

  factory WalletTopupSummary.fromJson(Map<String, dynamic> json) {
    return WalletTopupSummary(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      reference: json['vietqr_reference'] as String,
      vietQrPayload: json['vietqr_payload'] as String,
      vietQrImageUrl: json['vietqr_image_url']?.toString(),
    );
  }
}

class SupportChatMessage {
  const SupportChatMessage({required this.senderName, required this.body});

  final String senderName;
  final String body;

  factory SupportChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    return SupportChatMessage(
      senderName: sender?['name']?.toString() ?? 'Người dùng',
      body: json['body']?.toString() ?? '',
    );
  }
}

class AppNotificationSummary {
  const AppNotificationSummary({
    required this.id,
    required this.type,
    required this.isRead,
    this.title,
    this.body,
  });

  final String id;
  final String type;
  final bool isRead;
  final String? title;
  final String? body;

  factory AppNotificationSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return AppNotificationSummary(
      id: json['id'] as String,
      type: json['type'] as String,
      isRead: json['read_at'] != null,
      title: data?['title']?.toString(),
      body: data?['body']?.toString(),
    );
  }
}

class CustomerProfileSummary {
  const CustomerProfileSummary({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;

  factory CustomerProfileSummary.fromJson(Map<String, dynamic> json) {
    return CustomerProfileSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email']?.toString(),
    );
  }
}

double _doubleValue(Object? value) => (value as num?)?.toDouble() ?? 0;

int _intValue(Object? value) => (value as num?)?.toInt() ?? 0;

ServiceKind _serviceKind(Object? value) => switch (value?.toString()) {
  'DELIVERY' => ServiceKind.delivery,
  'HOURLY' => ServiceKind.hourly,
  _ => ServiceKind.drive,
};

class VoucherSummary {
  const VoucherSummary({
    required this.id,
    required this.code,
    required this.name,
    required this.discountType,
    required this.discountValue,
    required this.endsAt,
    this.maxDiscountAmount,
    this.serviceScope,
    this.minimumOrderAmount = 0,
    this.isOwned = false,
  });

  final String id;
  final String code;
  final String name;
  final String discountType;
  final double discountValue;
  final double? maxDiscountAmount;
  final String? serviceScope;
  final double minimumOrderAmount;
  final DateTime endsAt;
  final bool isOwned;

  factory VoucherSummary.fromJson(Map<String, dynamic> json) => VoucherSummary(
    id: json['id'].toString(),
    code: json['code'].toString(),
    name: json['name'].toString(),
    discountType: json['discount_type'].toString(),
    discountValue: _doubleValue(json['discount_value']),
    maxDiscountAmount: (json['max_discount_amount'] as num?)?.toDouble(),
    serviceScope: json['service_scope']?.toString(),
    minimumOrderAmount: (json['minimum_order_amount'] as num?)?.toDouble() ?? 0,
    endsAt: DateTime.parse(json['ends_at'].toString()),
    isOwned: json['is_owned'] == true,
  );
}

class LoyaltyAccountSummary {
  const LoyaltyAccountSummary({
    required this.id,
    required this.pointsBalance,
    required this.lifetimeEarned,
    required this.lifetimeRedeemed,
    required this.tier,
  });

  final String id;
  final int pointsBalance;
  final int lifetimeEarned;
  final int lifetimeRedeemed;
  final String tier;

  factory LoyaltyAccountSummary.fromJson(Map<String, dynamic> json) =>
      LoyaltyAccountSummary(
        id: json['id'].toString(),
        pointsBalance: _intValue(json['points_balance']),
        lifetimeEarned: _intValue(json['lifetime_earned']),
        lifetimeRedeemed: _intValue(json['lifetime_redeemed']),
        tier: json['tier'].toString(),
      );
}

class LoyaltyRewardSummary {
  const LoyaltyRewardSummary({
    required this.id,
    required this.name,
    required this.pointsCost,
    required this.discountType,
    required this.discountValue,
    this.serviceScope,
    this.stock,
  });

  final String id;
  final String name;
  final int pointsCost;
  final String discountType;
  final double discountValue;
  final String? serviceScope;
  final int? stock;

  factory LoyaltyRewardSummary.fromJson(Map<String, dynamic> json) =>
      LoyaltyRewardSummary(
        id: json['id'].toString(),
        name: json['name'].toString(),
        pointsCost: _intValue(json['points_cost']),
        discountType: json['discount_type'].toString(),
        discountValue: _doubleValue(json['discount_value']),
        serviceScope: json['service_scope']?.toString(),
        stock: (json['stock'] as num?)?.toInt(),
      );
}

class LoyaltyTransactionSummary {
  const LoyaltyTransactionSummary({
    required this.id,
    required this.type,
    required this.points,
    required this.balanceAfter,
    required this.createdAt,
  });

  final String id;
  final String type;
  final int points;
  final int balanceAfter;
  final DateTime createdAt;

  factory LoyaltyTransactionSummary.fromJson(Map<String, dynamic> json) =>
      LoyaltyTransactionSummary(
        id: json['id'].toString(),
        type: json['type'].toString(),
        points: _intValue(json['points']),
        balanceAfter: _intValue(json['balance_after']),
        createdAt: DateTime.parse(json['created_at'].toString()),
      );
}

class LoyaltyRedeemSummary {
  const LoyaltyRedeemSummary({
    required this.account,
    required this.voucher,
    required this.transaction,
  });

  final LoyaltyAccountSummary account;
  final VoucherSummary voucher;
  final LoyaltyTransactionSummary transaction;
}

class SupportTicketSummary {
  const SupportTicketSummary({
    required this.id,
    required this.subject,
    required this.status,
    required this.messages,
  });

  final String id;
  final String subject;
  final String status;
  final List<SupportChatMessage> messages;

  factory SupportTicketSummary.fromJson(Map<String, dynamic> json) {
    return SupportTicketSummary(
      id: json['id'] as String,
      subject: json['subject'] as String,
      status: json['status'] as String,
      messages: (json['messages'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SupportChatMessage.fromJson)
          .toList(growable: false),
    );
  }
}

abstract interface class CustomerAccountGateway {
  Future<void> register({
    required String baseUrl,
    required String name,
    required String phone,
    required String password,
  });
  Future<String> verifyPhone({
    required String baseUrl,
    required String phone,
    required String code,
  });
  Future<void> resendPhone({required String baseUrl, required String phone});
  Future<void> forgotPassword({required String baseUrl, required String phone});
  Future<String> verifyReset({
    required String baseUrl,
    required String phone,
    required String code,
  });
  Future<void> resetPassword({
    required String baseUrl,
    required String phone,
    required String resetToken,
    required String password,
  });
  Future<CustomerProfileSummary> validateSession(BookingSession session);
  Future<void> logout(BookingSession session);
}

abstract interface class BookingSupportGateway {
  Future<List<SupportChatMessage>> loadChat(
    BookingSession session,
    String serviceRequestId,
  );

  Future<void> sendChat({
    required BookingSession session,
    required String serviceRequestId,
    required String body,
  });

  Future<void> createSupportTicket({
    required BookingSession session,
    required String serviceRequestId,
    required String subject,
    required String description,
  });

  Future<void> reportIncident({
    required BookingSession session,
    required String serviceRequestId,
    required String incidentType,
    String? description,
  });

  Future<void> submitRating({
    required BookingSession session,
    required String serviceRequestId,
    required int score,
    String? comment,
  });

  Future<List<AppNotificationSummary>> loadNotifications(
    BookingSession session,
  );
  Future<int> loadUnreadNotificationCount(BookingSession session);

  Future<void> markNotificationRead(
    BookingSession session,
    String notificationId,
  );

  Future<List<SupportTicketSummary>> loadTickets(BookingSession session);
  Future<SupportTicketSummary> loadTicket(BookingSession session, String id);
  Future<void> replyToTicket({
    required BookingSession session,
    required String id,
    required String body,
  });
}

abstract interface class BookingGateway {
  Future<String> login({
    required String baseUrl,
    required String phone,
    required String password,
  });

  Future<List<VehicleOption>> loadVehicleTypes(BookingSession session);

  Future<QuoteSummary> createQuote(BookingSession session, BookingDraft draft);

  Future<List<QuoteSummary>> createQuoteBatch(
    BookingSession session,
    BookingDraft draft,
  );

  Future<ServiceRequestSummary> createServiceRequest({
    required BookingSession session,
    required QuoteSummary quote,
    required PaymentChoice payment,
    required PayerChoice payer,
    required String idempotencyKey,
    String? recipientUserId,
    String? passengerName,
    String? passengerPhone,
  });

  Future<ServiceRequestSummary> cancelServiceRequest({
    required BookingSession session,
    required ServiceRequestSummary serviceRequest,
    required String idempotencyKey,
    required String reasonCode,
  });

  Future<ServiceRequestSummary> loadServiceRequest(
    BookingSession session,
    String serviceRequestId,
  );

  Future<WalletSummary> loadWallet(BookingSession session);

  Future<WalletTopupSummary> createTopup({
    required BookingSession session,
    required double amount,
    required String idempotencyKey,
  });
}

abstract interface class BookingCommerceGateway {
  Future<List<VoucherSummary>> loadVouchers(BookingSession session);
  Future<LoyaltyAccountSummary> loadLoyaltyAccount(BookingSession session);
  Future<List<LoyaltyRewardSummary>> loadLoyaltyRewards(BookingSession session);
  Future<List<LoyaltyTransactionSummary>> loadLoyaltyTransactions(
    BookingSession session,
  );
  Future<LoyaltyRedeemSummary> redeemLoyaltyReward({
    required BookingSession session,
    required String rewardId,
    required String idempotencyKey,
  });
}

abstract interface class BookingHistoryGateway {
  Future<List<ServiceRequestSummary>> loadServiceRequests(
    BookingSession session,
  );
}

abstract interface class BookingTrackingGateway {
  Future<TrackingSummary> loadTracking(
    BookingSession session,
    String serviceRequestId,
  );
}

class BookingApi
    implements
        BookingGateway,
        BookingSupportGateway,
        CustomerAccountGateway,
        BookingHistoryGateway,
        BookingTrackingGateway,
        BookingCommerceGateway {
  BookingApi({
    ApiTransport? transport,
    this.deviceId = 'customer-app-session',
    this.pushTokenProvider,
  }) : _transport = transport ?? createApiTransport();

  final ApiTransport _transport;
  final String deviceId;
  final PushTokenProvider? pushTokenProvider;
  final _pendingOperations = <String, String>{};

  Future<void> _sendRetryable({
    required BookingSession session,
    required String path,
    required Map<String, dynamic> body,
    bool chat = false,
  }) async {
    final key = '${session.token}:$path:${jsonEncode(body)}';
    final id = _pendingOperations.putIfAbsent(key, newRequestId);
    final response = await _transport.send(
      method: 'POST',
      uri: _uri(session, path),
      token: session.token,
      headers: chat ? const {} : {'Idempotency-Key': id},
      body: chat ? {'client_message_id': id, ...body} : body,
    );
    _data(response);
    _pendingOperations.remove(key);
  }

  Uri _authUri(String baseUrl, String path) =>
      Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path');

  Future<ApiResponse> _authPost(
    String baseUrl,
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _transport.send(
      method: 'POST',
      uri: _authUri(baseUrl, path),
      token: '',
      body: body,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BookingApiException.fromResponse(response);
    }
    return response;
  }

  Future<Map<String, dynamic>> _deviceContext() async {
    final pushToken = await pushTokenProvider?.token();

    return {
      'device_id': deviceId,
      'app_type': 'CUSTOMER_APP',
      'platform': kIsWeb
          ? 'WEB'
          : defaultTargetPlatform == TargetPlatform.iOS
          ? 'IOS'
          : 'ANDROID',
      if (pushToken != null && pushToken.isNotEmpty) 'push_token': pushToken,
    };
  }

  @override
  Future<void> register({
    required String baseUrl,
    required String name,
    required String phone,
    required String password,
  }) async {
    await _authPost(baseUrl, '/auth/register', {
      'name': name,
      'phone': phone,
      'password': password,
      'password_confirmation': password,
    });
  }

  @override
  Future<String> verifyPhone({
    required String baseUrl,
    required String phone,
    required String code,
  }) async {
    final response = await _authPost(baseUrl, '/auth/phone/verify', {
      'phone': phone,
      'code': code,
      ...await _deviceContext(),
    });
    return _token(response);
  }

  @override
  Future<void> resendPhone({
    required String baseUrl,
    required String phone,
  }) async {
    await _authPost(baseUrl, '/auth/phone/resend', {'phone': phone});
  }

  @override
  Future<void> forgotPassword({
    required String baseUrl,
    required String phone,
  }) async {
    await _authPost(baseUrl, '/auth/password/forgot', {'phone': phone});
  }

  @override
  Future<String> verifyReset({
    required String baseUrl,
    required String phone,
    required String code,
  }) async {
    final response = await _authPost(baseUrl, '/auth/password/verify', {
      'phone': phone,
      'code': code,
    });
    final token = response.body['reset_token'];
    if (token is! String) {
      throw const BookingApiException('Mã đặt lại mật khẩu không hợp lệ.');
    }
    return token;
  }

  @override
  Future<void> resetPassword({
    required String baseUrl,
    required String phone,
    required String resetToken,
    required String password,
  }) async {
    await _authPost(baseUrl, '/auth/password/reset', {
      'phone': phone,
      'token': resetToken,
      'password': password,
      'password_confirmation': password,
    });
  }

  @override
  Future<CustomerProfileSummary> validateSession(BookingSession session) async {
    return CustomerProfileSummary.fromJson(
      _data(
        await _transport.send(
          method: 'GET',
          uri: _uri(session, '/me'),
          token: session.token,
        ),
      ),
    );
  }

  @override
  Future<void> logout(BookingSession session) async {
    final response = await _transport.send(
      method: 'POST',
      uri: _uri(session, '/auth/logout'),
      token: session.token,
    );
    if (response.statusCode != 204) {
      throw BookingApiException.fromResponse(response);
    }
  }

  String _token(ApiResponse response) {
    final token = response.body['token'];
    if (token is! String || token.isEmpty) {
      throw const BookingApiException('Phiên đăng nhập không hợp lệ.');
    }
    return token;
  }

  @override
  Future<String> login({
    required String baseUrl,
    required String phone,
    required String password,
  }) async {
    final response = await _transport.send(
      method: 'POST',
      uri: Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}/auth/login'),
      token: '',
      body: {'phone': phone, 'password': password, ...await _deviceContext()},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BookingApiException.fromResponse(response);
    }

    return _token(response);
  }

  @override
  Future<List<VehicleOption>> loadVehicleTypes(BookingSession session) async {
    final response = await _transport.send(
      method: 'GET',
      uri: _uri(session, '/catalog/vehicle-types'),
      token: session.token,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BookingApiException.fromResponse(response);
    }

    final data = response.body['data'];
    if (data is! List) {
      throw const BookingApiException('Danh sách phương tiện không hợp lệ.');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(VehicleOption.fromJson)
        .toList(growable: false);
  }

  @override
  Future<QuoteSummary> createQuote(
    BookingSession session,
    BookingDraft draft,
  ) async {
    final response = await _transport.send(
      method: 'POST',
      uri: _uri(session, '/quotes'),
      token: session.token,
      body: {
        'service_type': draft.service.apiValue,
        'vehicle_type_id': draft.vehicleTypeId ?? session.vehicleTypeId,
        'booking_type': draft.scheduledAt == null ? 'NOW' : 'SCHEDULED',
        'scheduled_at': ?draft.scheduledAt?.toUtc().toIso8601String(),
        'pickup': draft.pickup.toJson(),
        if (draft.dropoff case final dropoff?) 'dropoff': dropoff.toJson(),
        'service_payload': switch (draft.service) {
          ServiceKind.delivery => {
            'goods_type': draft.goodsType,
            'weight_kg': draft.weightKg,
          },
          ServiceKind.hourly => {'duration_hours': draft.durationHours},
          ServiceKind.drive => {'passenger_count': draft.passengerCount},
        },
        'voucher_code': ?draft.voucherCode,
      },
    );

    return QuoteSummary.fromJson(_data(response));
  }

  @override
  Future<List<QuoteSummary>> createQuoteBatch(
    BookingSession session,
    BookingDraft draft,
  ) async {
    final vehicleTypeIds = draft.vehicleTypeIds;
    if (vehicleTypeIds == null || vehicleTypeIds.length != 2) {
      throw const BookingApiException('Thiếu hai loại phương tiện để báo giá.');
    }
    final response = await _transport.send(
      method: 'POST',
      uri: _uri(session, '/quotes/batch'),
      token: session.token,
      body: {
        'service_type': draft.service.apiValue,
        'vehicle_type_ids': vehicleTypeIds,
        'booking_type': draft.scheduledAt == null ? 'NOW' : 'SCHEDULED',
        'scheduled_at': ?draft.scheduledAt?.toUtc().toIso8601String(),
        'pickup': draft.pickup.toJson(),
        'dropoff': draft.dropoff?.toJson(),
        'service_payload': {'passenger_count': draft.passengerCount},
        'voucher_code': ?draft.voucherCode,
      },
    );
    return _listData(response)
        .map(QuoteSummary.fromJson)
        .toList(growable: false);
  }

  @override
  Future<ServiceRequestSummary> createServiceRequest({
    required BookingSession session,
    required QuoteSummary quote,
    required PaymentChoice payment,
    required PayerChoice payer,
    required String idempotencyKey,
    String? recipientUserId,
    String? passengerName,
    String? passengerPhone,
  }) async {
    final path = quote.service == ServiceKind.delivery
        ? '/delivery/orders'
        : '/rides/bookings';
    final response = await _transport.send(
      method: 'POST',
      uri: _uri(session, path),
      token: session.token,
      headers: {'Idempotency-Key': idempotencyKey},
      body: {
        'quote_id': quote.id,
        'payment_method': payment.apiValue,
        if (quote.service == ServiceKind.delivery) 'payer_type': payer.apiValue,
        'recipient_user_id': ?recipientUserId,
        'passenger_name': ?passengerName,
        'passenger_phone': ?passengerPhone,
      },
    );

    return ServiceRequestSummary.fromJson(_data(response));
  }

  @override
  Future<ServiceRequestSummary> cancelServiceRequest({
    required BookingSession session,
    required ServiceRequestSummary serviceRequest,
    required String idempotencyKey,
    required String reasonCode,
  }) async {
    final response = await _transport.send(
      method: 'POST',
      uri: _uri(session, '/service-requests/${serviceRequest.id}/cancel'),
      token: session.token,
      headers: {'Idempotency-Key': idempotencyKey},
      body: {'reason_code': reasonCode},
    );

    return ServiceRequestSummary.fromJson(_data(response));
  }

  @override
  Future<ServiceRequestSummary> loadServiceRequest(
    BookingSession session,
    String serviceRequestId,
  ) async {
    final response = await _transport.send(
      method: 'GET',
      uri: _uri(session, '/service-requests/$serviceRequestId'),
      token: session.token,
    );

    return ServiceRequestSummary.fromJson(_data(response));
  }

  @override
  Future<TrackingSummary> loadTracking(
    BookingSession session,
    String serviceRequestId,
  ) async {
    final response = await _transport.send(
      method: 'GET',
      uri: _uri(session, '/service-requests/$serviceRequestId/tracking'),
      token: session.token,
    );

    return TrackingSummary.fromJson(_data(response));
  }

  @override
  Future<List<ServiceRequestSummary>> loadServiceRequests(
    BookingSession session,
  ) async {
    final response = await _transport.send(
      method: 'GET',
      uri: _uri(session, '/service-requests'),
      token: session.token,
    );

    return _listData(response)
        .map(ServiceRequestSummary.fromJson)
        .toList(growable: false);
  }

  @override
  Future<WalletSummary> loadWallet(BookingSession session) async {
    final response = await _transport.send(
      method: 'GET',
      uri: _uri(session, '/wallet'),
      token: session.token,
    );

    return WalletSummary.fromJson(_data(response));
  }

  @override
  Future<WalletTopupSummary> createTopup({
    required BookingSession session,
    required double amount,
    required String idempotencyKey,
  }) async {
    final response = await _transport.send(
      method: 'POST',
      uri: _uri(session, '/wallet/topups'),
      token: session.token,
      headers: {'Idempotency-Key': idempotencyKey},
      body: {'amount': amount},
    );

    return WalletTopupSummary.fromJson(_data(response));
  }

  @override
  Future<List<SupportChatMessage>> loadChat(
    BookingSession session,
    String serviceRequestId,
  ) async {
    final response = await _transport.send(
      method: 'GET',
      uri: _uri(session, '/service-requests/$serviceRequestId/chat'),
      token: session.token,
    );

    return _listData(response)
        .map(SupportChatMessage.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> sendChat({
    required BookingSession session,
    required String serviceRequestId,
    required String body,
  }) async {
    await _sendRetryable(
      session: session,
      path: '/service-requests/$serviceRequestId/chat',
      body: {'body': body},
      chat: true,
    );
  }

  @override
  Future<void> createSupportTicket({
    required BookingSession session,
    required String serviceRequestId,
    required String subject,
    required String description,
  }) async {
    await _sendRetryable(
      session: session,
      path: '/support/tickets',
      body: {
        'service_request_id': serviceRequestId,
        'category': 'OTHER',
        'subject': subject,
        'description': description,
      },
    );
  }

  @override
  Future<void> reportIncident({
    required BookingSession session,
    required String serviceRequestId,
    required String incidentType,
    String? description,
  }) async {
    await _sendRetryable(
      session: session,
      path: '/service-requests/$serviceRequestId/incidents',
      body: {
        'incident_type': incidentType,
        if (description?.trim().isNotEmpty ?? false)
          'description': description!.trim(),
      },
    );
  }

  @override
  Future<void> submitRating({
    required BookingSession session,
    required String serviceRequestId,
    required int score,
    String? comment,
  }) async {
    _data(
      await _transport.send(
        method: 'POST',
        uri: _uri(session, '/service-requests/$serviceRequestId/ratings'),
        token: session.token,
        body: {
          'score': score,
          if (comment?.trim().isNotEmpty ?? false) 'comment': comment!.trim(),
        },
      ),
    );
  }

  @override
  Future<List<VoucherSummary>> loadVouchers(BookingSession session) async {
    return _listData(
      await _transport.send(
        method: 'GET',
        uri: _uri(session, '/promotions/vouchers'),
        token: session.token,
      ),
    ).map(VoucherSummary.fromJson).toList(growable: false);
  }

  @override
  Future<LoyaltyAccountSummary> loadLoyaltyAccount(
    BookingSession session,
  ) async {
    return LoyaltyAccountSummary.fromJson(
      _data(
        await _transport.send(
          method: 'GET',
          uri: _uri(session, '/loyalty/account'),
          token: session.token,
        ),
      ),
    );
  }

  @override
  Future<List<LoyaltyRewardSummary>> loadLoyaltyRewards(
    BookingSession session,
  ) async {
    return _listData(
      await _transport.send(
        method: 'GET',
        uri: _uri(session, '/loyalty/rewards'),
        token: session.token,
      ),
    ).map(LoyaltyRewardSummary.fromJson).toList(growable: false);
  }

  @override
  Future<List<LoyaltyTransactionSummary>> loadLoyaltyTransactions(
    BookingSession session,
  ) async {
    return _listData(
      await _transport.send(
        method: 'GET',
        uri: _uri(session, '/loyalty/transactions'),
        token: session.token,
      ),
    ).map(LoyaltyTransactionSummary.fromJson).toList(growable: false);
  }

  @override
  Future<LoyaltyRedeemSummary> redeemLoyaltyReward({
    required BookingSession session,
    required String rewardId,
    required String idempotencyKey,
  }) async {
    final data = _data(
      await _transport.send(
        method: 'POST',
        uri: _uri(session, '/loyalty/rewards/$rewardId/redeem'),
        token: session.token,
        headers: {'Idempotency-Key': idempotencyKey},
      ),
    );
    final account = data['account'] as Map<String, dynamic>;
    final voucher = data['voucher'] as Map<String, dynamic>;
    final transaction = data['transaction'] as Map<String, dynamic>;
    return LoyaltyRedeemSummary(
      account: LoyaltyAccountSummary.fromJson(account),
      voucher: VoucherSummary.fromJson(voucher),
      transaction: LoyaltyTransactionSummary.fromJson(transaction),
    );
  }

  @override
  Future<List<AppNotificationSummary>> loadNotifications(
    BookingSession session,
  ) async {
    final response = await _transport.send(
      method: 'GET',
      uri: _uri(session, '/notifications'),
      token: session.token,
    );

    return _listData(response)
        .map(AppNotificationSummary.fromJson)
        .toList(growable: false);
  }

  @override
  Future<int> loadUnreadNotificationCount(BookingSession session) async {
    final data = _data(
      await _transport.send(
        method: 'GET',
        uri: _uri(session, '/notifications/unread'),
        token: session.token,
      ),
    );
    final count = data['unread_count'];
    if (count is num) return count.toInt();
    throw const BookingApiException(
      'Phản hồi số thông báo chưa đọc không hợp lệ.',
    );
  }

  @override
  Future<void> markNotificationRead(
    BookingSession session,
    String notificationId,
  ) async {
    _data(
      await _transport.send(
        method: 'PUT',
        uri: _uri(session, '/notifications/$notificationId/read'),
        token: session.token,
      ),
    );
  }

  @override
  Future<List<SupportTicketSummary>> loadTickets(BookingSession session) async {
    final response = await _transport.send(
      method: 'GET',
      uri: _uri(session, '/support/tickets'),
      token: session.token,
    );
    return _listData(response)
        .map(SupportTicketSummary.fromJson)
        .toList(growable: false);
  }

  @override
  Future<SupportTicketSummary> loadTicket(
    BookingSession session,
    String id,
  ) async {
    final response = await _transport.send(
      method: 'GET',
      uri: _uri(session, '/support/tickets/$id'),
      token: session.token,
    );
    return SupportTicketSummary.fromJson(_data(response));
  }

  @override
  Future<void> replyToTicket({
    required BookingSession session,
    required String id,
    required String body,
  }) async {
    _data(
      await _transport.send(
        method: 'POST',
        uri: _uri(session, '/support/tickets/$id/messages'),
        token: session.token,
        body: {'body': body},
      ),
    );
  }

  Uri _uri(BookingSession session, String path) {
    return Uri.parse('${session.baseUrl.replaceFirst(RegExp(r'/$'), '')}$path');
  }

  Map<String, dynamic> _data(ApiResponse response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BookingApiException.fromResponse(response);
    }

    final data = response.body['data'];
    if (data is! Map<String, dynamic>) {
      throw const BookingApiException('Phản hồi từ máy chủ không hợp lệ.');
    }

    return data;
  }

  List<Map<String, dynamic>> _listData(ApiResponse response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BookingApiException.fromResponse(response);
    }

    final data = response.body['data'];
    if (data is! List) {
      throw const BookingApiException('Phản hồi từ máy chủ không hợp lệ.');
    }

    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}

class BookingApiException implements Exception {
  const BookingApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory BookingApiException.fromResponse(ApiResponse response) {
    final errors = response.body['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return BookingApiException(
            value.first.toString(),
            statusCode: response.statusCode,
          );
        }
      }
    }

    return BookingApiException(
      response.body['message']?.toString() ??
          'Không thể hoàn tất yêu cầu (${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }

  @override
  String toString() => message;
}
