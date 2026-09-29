import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_transport.dart';
import 'push_token_provider.dart';
import 'request_id.dart';

double _doubleValue(Object? value) => (value as num?)?.toDouble() ?? 0;

int _intValue(Object? value) => (value as num?)?.toInt() ?? 0;

class DriverSession {
  const DriverSession({
    required this.baseUrl,
    required this.token,
    this.onboarding = false,
  });

  final String baseUrl;
  final String token;
  final bool onboarding;

  DriverSession copyWith({String? token, bool? onboarding}) {
    return DriverSession(
      baseUrl: baseUrl,
      token: token ?? this.token,
      onboarding: onboarding ?? this.onboarding,
    );
  }
}

class DriverLoginResult {
  const DriverLoginResult(this.token, {required this.onboarding});
  final String token;
  final bool onboarding;
}

class DriverProfileSummary {
  const DriverProfileSummary({
    required this.reviewStatus,
    required this.availabilityStatus,
    required this.vehicles,
    required this.documents,
    required this.capabilities,
    this.reviewReason,
    this.performance,
    this.userName,
  });
  final String reviewStatus;
  final String availabilityStatus;
  final String? reviewReason;
  final List<Map<String, dynamic>> vehicles;
  final List<Map<String, dynamic>> documents;
  final List<String> capabilities;
  final DriverPerformance? performance;
  final String? userName;

  factory DriverProfileSummary.fromJson(Map<String, dynamic> json) =>
      DriverProfileSummary(
        reviewStatus: json['review_status'] as String,
        availabilityStatus: json['availability_status'] as String,
        reviewReason: json['review_reason_code'] as String?,
        vehicles: (json['vehicles'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false),
        documents: (json['documents'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false),
        capabilities: (json['capabilities'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .where((item) => item['is_active'] == true)
            .map((item) => item['service_type'].toString())
            .toList(growable: false),
        performance: json['performance'] is Map<String, dynamic>
            ? DriverPerformance.fromJson(
                json['performance'] as Map<String, dynamic>,
              )
            : null,
        userName: (json['user'] as Map<String, dynamic>?)?['name']?.toString(),
      );
}

class DriverPerformance {
  const DriverPerformance({
    this.rating,
    this.acceptanceRate,
    this.completionRate,
    required this.completedCount,
    this.updatedAt,
  });

  final double? rating;
  final double? acceptanceRate;
  final double? completionRate;
  final int completedCount;
  final DateTime? updatedAt;

  factory DriverPerformance.fromJson(Map<String, dynamic> json) {
    return DriverPerformance(
      rating: (json['rating'] as num?)?.toDouble(),
      acceptanceRate: (json['acceptance_rate'] as num?)?.toDouble(),
      completionRate: (json['completion_rate'] as num?)?.toDouble(),
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'].toString()),
    );
  }
}

abstract interface class DriverOperationsGateway {
  Future<DriverLoginResult> authenticate({
    required String baseUrl,
    required String phone,
    required String password,
  });
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
  Future<void> validateSession(DriverSession session);
  Future<void> logout(DriverSession session);
  Future<DriverProfileSummary?> loadApplication(DriverSession session);
  Future<DriverProfileSummary> saveApplication(DriverSession session);
  Future<List<Map<String, dynamic>>> loadVehicleTypes(DriverSession session);
  Future<void> createVehicle({
    required DriverSession session,
    required String vehicleTypeId,
    required String plateNumber,
  });
  Future<void> updateVehicle({
    required DriverSession session,
    required String vehicleId,
    required String vehicleTypeId,
    required String plateNumber,
  });
  Future<void> uploadDocument({
    required DriverSession session,
    required String documentType,
    required String name,
    required Uint8List bytes,
    String? documentNumber,
    String? vehicleId,
  });
  Future<void> submitApplication({
    required DriverSession session,
    required String vehicleId,
    required List<String> serviceTypes,
  });
  Future<DriverProfileSummary> setAvailability({
    required DriverSession session,
    required bool online,
    required double latitude,
    required double longitude,
    required double accuracy,
    required List<String> serviceTypes,
  });
  Future<void> updateLocation({
    required DriverSession session,
    required double latitude,
    required double longitude,
    required double accuracy,
  });
  Future<String> uploadEvidence({
    required DriverSession session,
    required String serviceRequestId,
    required String evidenceType,
    required String name,
    required Uint8List bytes,
    required double latitude,
    required double longitude,
  });
  Future<void> createBankAccount({
    required DriverSession session,
    required String bankCode,
    required String accountNumber,
    required String accountName,
  });
}

class DriverOfferSummary {
  const DriverOfferSummary({
    required this.id,
    required this.status,
    required this.serviceType,
    required this.serviceRequestId,
    required this.serviceStatus,
    required this.paymentMethod,
    required this.customerPayable,
    required this.pickupDistanceMeters,
    required this.estimatedEarning,
    required this.expiresAt,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    this.passengerName,
    this.passengerPhone,
  });

  final String id;
  final String status;
  final String serviceType;
  final String serviceRequestId;
  final String serviceStatus;
  final String paymentMethod;
  final double customerPayable;
  final double pickupDistanceMeters;
  final double estimatedEarning;
  final DateTime expiresAt;
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String? passengerName;
  final String? passengerPhone;

  factory DriverOfferSummary.fromJson(Map<String, dynamic> json) {
    final serviceRequest = json['service_request'] as Map<String, dynamic>;
    final stops = (serviceRequest['stops'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final pickup = stops.where((stop) => stop['type'] == 'PICKUP').firstOrNull;
    if (pickup == null) {
      throw const DriverApiException('Đề nghị không có điểm đón hợp lệ.');
    }
    final dropoff = stops
        .where((stop) => stop['type'] == 'DROPOFF')
        .firstOrNull;
    final passenger = json['passenger'] as Map<String, dynamic>?;
    final rideBooking = serviceRequest['ride_booking'] as Map<String, dynamic>?;
    return DriverOfferSummary(
      id: json['id'] as String,
      status: json['status'] as String,
      serviceType: serviceRequest['service_type'] as String,
      serviceRequestId: serviceRequest['id'] as String,
      serviceStatus: serviceRequest['status'] as String,
      paymentMethod:
          (serviceRequest['payment'] as Map<String, dynamic>)['method']
              as String,
      customerPayable: _doubleValue(
        (serviceRequest['payment'] as Map<String, dynamic>)['customer_payable'],
      ),
      pickupDistanceMeters: _doubleValue(
        json['estimated_pickup_distance_meters'],
      ),
      estimatedEarning: _doubleValue(json['estimated_driver_earning']),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      pickupLatitude: _doubleValue(pickup['latitude']),
      pickupLongitude: _doubleValue(pickup['longitude']),
      dropoffLatitude: _doubleValue(dropoff?['latitude'] ?? pickup['latitude']),
      dropoffLongitude: _doubleValue(
        dropoff?['longitude'] ?? pickup['longitude'],
      ),
      passengerName:
          passenger?['name']?.toString() ??
          rideBooking?['passenger_name']?.toString(),
      passengerPhone:
          passenger?['phone']?.toString() ??
          rideBooking?['passenger_phone']?.toString(),
    );
  }

  DriverOfferSummary withServiceStatus(String value) {
    return DriverOfferSummary(
      id: id,
      status: status,
      serviceType: serviceType,
      serviceRequestId: serviceRequestId,
      serviceStatus: value,
      paymentMethod: paymentMethod,
      customerPayable: customerPayable,
      pickupDistanceMeters: pickupDistanceMeters,
      estimatedEarning: estimatedEarning,
      expiresAt: expiresAt,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      dropoffLatitude: dropoffLatitude,
      dropoffLongitude: dropoffLongitude,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
    );
  }
}

class DriverWalletSummary {
  const DriverWalletSummary({
    required this.balance,
    required this.reserved,
    required this.available,
    this.entries = const [],
  });

  final double balance;
  final double reserved;
  final double available;
  final List<DriverWalletEntry> entries;

  factory DriverWalletSummary.fromJson(Map<String, dynamic> json) {
    return DriverWalletSummary(
      balance: _doubleValue(json['balance']),
      reserved: _doubleValue(json['reserved_withdrawal_amount']),
      available: _doubleValue(json['available_balance']),
      entries: (json['entries'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DriverWalletEntry.fromJson)
          .toList(growable: false),
    );
  }
}

class DriverWalletEntry {
  const DriverWalletEntry({
    required this.id,
    required this.direction,
    required this.amount,
    this.balanceAfter,
    this.transactionType,
    this.transactionStatus,
    this.referenceType,
    this.referenceId,
    this.postedAt,
    this.createdAt,
  });

  final int id;
  final String direction;
  final double amount;
  final double? balanceAfter;
  final String? transactionType;
  final String? transactionStatus;
  final String? referenceType;
  final int? referenceId;
  final DateTime? postedAt;
  final DateTime? createdAt;

  factory DriverWalletEntry.fromJson(Map<String, dynamic> json) {
    return DriverWalletEntry(
      id: _intValue(json['id']),
      direction: json['direction'].toString(),
      amount: _doubleValue(json['amount']),
      balanceAfter: (json['balance_after'] as num?)?.toDouble(),
      transactionType: json['transaction_type']?.toString(),
      transactionStatus: json['transaction_status']?.toString(),
      referenceType: json['reference_type']?.toString(),
      referenceId: (json['reference_id'] as num?)?.toInt(),
      postedAt: json['posted_at'] == null
          ? null
          : DateTime.tryParse(json['posted_at'].toString()),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }
}

class DriverWalletTopupSummary {
  const DriverWalletTopupSummary({
    required this.id,
    required this.amount,
    required this.status,
    required this.reference,
    required this.vietQrPayload,
    required this.expiresAt,
    this.vietQrImageUrl,
  });

  final String id;
  final double amount;
  final String status;
  final String reference;
  final String vietQrPayload;
  final DateTime expiresAt;
  final String? vietQrImageUrl;

  factory DriverWalletTopupSummary.fromJson(Map<String, dynamic> json) {
    return DriverWalletTopupSummary(
      id: json['id'] as String,
      amount: _doubleValue(json['amount']),
      status: json['status'] as String,
      reference: json['vietqr_reference'] as String,
      vietQrPayload: json['vietqr_payload'] as String,
      expiresAt: DateTime.parse(json['expires_at'].toString()),
      vietQrImageUrl: json['vietqr_image_url']?.toString(),
    );
  }
}

class DriverJobSummary {
  const DriverJobSummary({
    required this.id,
    required this.serviceType,
    required this.status,
    required this.customerPayable,
    required this.paymentMethod,
    this.driverNetEarning,
    this.pickupAddress,
    this.dropoffAddress,
    this.createdAt,
  });

  final String id;
  final String serviceType;
  final String status;
  final double customerPayable;
  final String paymentMethod;
  final double? driverNetEarning;
  final String? pickupAddress;
  final String? dropoffAddress;
  final DateTime? createdAt;

  factory DriverJobSummary.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>;
    final settlement = payment['settlement'];
    final stops = (json['stops'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final pickup = stops.where((stop) => stop['type'] == 'PICKUP').firstOrNull;
    final dropoff = stops
        .where((stop) => stop['type'] == 'DROPOFF')
        .firstOrNull;
    return DriverJobSummary(
      id: json['id'] as String,
      serviceType: json['service_type'] as String,
      status: json['status'] as String,
      customerPayable: _doubleValue(payment['customer_payable']),
      paymentMethod: payment['method'] as String,
      driverNetEarning: settlement is Map<String, dynamic>
          ? (settlement['driver_net_earning'] as num?)?.toDouble()
          : null,
      pickupAddress: pickup?['address']?.toString(),
      dropoffAddress: dropoff?['address']?.toString(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'].toString()),
    );
  }
}

class DriverHistoryFilter {
  const DriverHistoryFilter({
    this.from,
    this.to,
    this.status,
    this.serviceType,
    this.query,
    this.page = 1,
  });

  final DateTime? from;
  final DateTime? to;
  final String? status;
  final String? serviceType;
  final String? query;
  final int page;

  DriverHistoryFilter copyWith({
    DateTime? from,
    DateTime? to,
    String? status,
    String? serviceType,
    String? query,
    int? page,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearStatus = false,
    bool clearServiceType = false,
    bool clearQuery = false,
  }) {
    return DriverHistoryFilter(
      from: clearFrom ? null : from ?? this.from,
      to: clearTo ? null : to ?? this.to,
      status: clearStatus ? null : status ?? this.status,
      serviceType: clearServiceType ? null : serviceType ?? this.serviceType,
      query: clearQuery ? null : query ?? this.query,
      page: page ?? this.page,
    );
  }

  Map<String, String> toQuery() => {
    if (from != null) 'from': _date(from!),
    if (to != null) 'to': _date(to!),
    if (status != null && status!.isNotEmpty) 'status': status!,
    if (serviceType != null && serviceType!.isNotEmpty)
      'service_type': serviceType!,
    if (query != null && query!.trim().isNotEmpty) 'q': query!.trim(),
    'page': page.toString(),
  };

  String _date(DateTime value) => value.toIso8601String().substring(0, 10);
}

class DriverHistorySummary {
  const DriverHistorySummary({
    required this.completedCount,
    required this.cancelledCount,
    required this.netEarning,
  });

  final int completedCount;
  final int cancelledCount;
  final double netEarning;

  factory DriverHistorySummary.fromJson(Map<String, dynamic> json) {
    return DriverHistorySummary(
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      cancelledCount: (json['cancelled_count'] as num?)?.toInt() ?? 0,
      netEarning: (json['net_earning'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DriverHistoryPage {
  const DriverHistoryPage({
    required this.jobs,
    required this.summary,
    required this.currentPage,
    required this.lastPage,
  });

  final List<DriverJobSummary> jobs;
  final DriverHistorySummary summary;
  final int currentPage;
  final int lastPage;
}

class DriverBankAccountSummary {
  const DriverBankAccountSummary({
    required this.id,
    required this.bankCode,
    required this.accountName,
    required this.verified,
  });

  final String id;
  final String bankCode;
  final String accountName;
  final bool verified;

  factory DriverBankAccountSummary.fromJson(Map<String, dynamic> json) {
    return DriverBankAccountSummary(
      id: json['id'] as String,
      bankCode: json['bank_code'] as String,
      accountName: json['account_name'] as String,
      verified: json['is_verified'] as bool,
    );
  }
}

class DriverChatMessage {
  const DriverChatMessage({required this.senderName, required this.body});

  final String senderName;
  final String body;

  factory DriverChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    return DriverChatMessage(
      senderName: sender?['name']?.toString() ?? 'Người dùng',
      body: json['body']?.toString() ?? '',
    );
  }
}

class DriverNotificationSummary {
  const DriverNotificationSummary({
    required this.id,
    required this.type,
    required this.isRead,
  });

  final String id;
  final String type;
  final bool isRead;

  factory DriverNotificationSummary.fromJson(Map<String, dynamic> json) {
    return DriverNotificationSummary(
      id: json['id'] as String,
      type: json['type'] as String,
      isRead: json['read_at'] != null,
    );
  }
}

class DriverTicketSummary {
  const DriverTicketSummary({
    required this.id,
    required this.subject,
    required this.status,
    required this.messages,
  });
  final String id;
  final String subject;
  final String status;
  final List<DriverChatMessage> messages;

  factory DriverTicketSummary.fromJson(Map<String, dynamic> json) =>
      DriverTicketSummary(
        id: json['id'] as String,
        subject: json['subject'] as String,
        status: json['status'] as String,
        messages: (json['messages'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(DriverChatMessage.fromJson)
            .toList(growable: false),
      );
}

abstract interface class DriverSupportGateway {
  Future<List<DriverTicketSummary>> loadTickets(DriverSession session);
  Future<DriverTicketSummary> loadTicket(DriverSession session, String id);
  Future<void> replyToTicket({
    required DriverSession session,
    required String id,
    required String body,
  });
  Future<List<DriverChatMessage>> loadChat(
    DriverSession session,
    String serviceRequestId,
  );

  Future<void> sendChat({
    required DriverSession session,
    required String serviceRequestId,
    required String body,
  });

  Future<void> createSupportTicket({
    required DriverSession session,
    required String serviceRequestId,
    required String subject,
    required String description,
  });

  Future<void> reportIncident({
    required DriverSession session,
    required String serviceRequestId,
    required String incidentType,
    String? description,
  });

  Future<void> submitRating({
    required DriverSession session,
    required String serviceRequestId,
    required int score,
    String? comment,
  });

  Future<List<DriverNotificationSummary>> loadNotifications(
    DriverSession session,
  );

  Future<void> markNotificationRead(
    DriverSession session,
    String notificationId,
  );
}

abstract interface class DriverGateway {
  Future<String> login({
    required String baseUrl,
    required String phone,
    required String password,
  });

  Future<List<DriverOfferSummary>> loadOffers(DriverSession session);

  Future<DriverOfferSummary> respond({
    required DriverSession session,
    required DriverOfferSummary offer,
    required String action,
    required String idempotencyKey,
  });

  Future<String> transition({
    required DriverSession session,
    required DriverOfferSummary offer,
    required String action,
    required double latitude,
    required double longitude,
    required String idempotencyKey,
    double? cashCollected,
    double? codCollected,
    String? evidenceId,
    String? outOfGeofenceReason,
  });

  Future<DriverWalletSummary> loadWallet(DriverSession session);

  Future<DriverWalletTopupSummary> createTopup({
    required DriverSession session,
    required double amount,
    required String idempotencyKey,
  });

  Future<List<DriverBankAccountSummary>> loadBankAccounts(
    DriverSession session,
  );

  Future<void> requestWithdrawal({
    required DriverSession session,
    required String bankAccountId,
    required double amount,
    required String idempotencyKey,
  });
}

abstract interface class DriverHistoryGateway {
  Future<List<DriverJobSummary>> loadJobHistory(DriverSession session);
  Future<DriverHistoryPage> loadJobHistoryPage(
    DriverSession session, {
    DriverHistoryFilter? filter,
  });
}

class DriverApi
    implements
        DriverGateway,
        DriverSupportGateway,
        DriverOperationsGateway,
        DriverHistoryGateway {
  DriverApi({
    ApiTransport? transport,
    this.deviceId = 'driver-app-session',
    this.pushTokenProvider,
  }) : _transport = transport ?? createApiTransport();

  final ApiTransport _transport;
  final String deviceId;
  final PushTokenProvider? pushTokenProvider;
  final _pendingOperations = <String, String>{};

  Future<void> _sendRetryable({
    required DriverSession session,
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
    _assertSuccess(response);
    _pendingOperations.remove(key);
  }

  String get _platform => kIsWeb
      ? 'WEB'
      : defaultTargetPlatform == TargetPlatform.iOS
      ? 'IOS'
      : 'ANDROID';

  Future<ApiResponse> _postAuth(
    String baseUrl,
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _transport.send(
      method: 'POST',
      uri: Uri.parse('${_base(baseUrl)}$path'),
      token: '',
      body: body,
    );
    _assertSuccess(response);
    return response;
  }

  Future<String> _loginAs(
    String baseUrl,
    String phone,
    String password,
    String appType,
  ) async {
    final pushToken = await pushTokenProvider?.token();
    final response = await _postAuth(baseUrl, '/auth/login', {
      'phone': phone,
      'password': password,
      'device_id': deviceId,
      'app_type': appType,
      'platform': _platform,
      if (pushToken != null && pushToken.isNotEmpty) 'push_token': pushToken,
    });
    final token = response.body['token'];
    if (token is! String || token.isEmpty) {
      throw const DriverApiException('Phiên đăng nhập không hợp lệ.');
    }
    return token;
  }

  @override
  Future<DriverLoginResult> authenticate({
    required String baseUrl,
    required String phone,
    required String password,
  }) async {
    try {
      return DriverLoginResult(
        await _loginAs(baseUrl, phone, password, 'DRIVER_APP'),
        onboarding: false,
      );
    } on DriverApiException catch (error) {
      if (error.statusCode != 422) rethrow;
      return DriverLoginResult(
        await _loginAs(baseUrl, phone, password, 'CUSTOMER_APP'),
        onboarding: true,
      );
    }
  }

  @override
  Future<void> register({
    required String baseUrl,
    required String name,
    required String phone,
    required String password,
  }) async {
    await _postAuth(baseUrl, '/auth/register', {
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
    final pushToken = await pushTokenProvider?.token();
    final response = await _postAuth(baseUrl, '/auth/phone/verify', {
      'phone': phone,
      'code': code,
      'device_id': deviceId,
      'app_type': 'CUSTOMER_APP',
      'platform': _platform,
      if (pushToken != null && pushToken.isNotEmpty) 'push_token': pushToken,
    });
    final token = response.body['token'];
    if (token is! String || token.isEmpty) {
      throw const DriverApiException('Phiên đăng nhập không hợp lệ.');
    }
    return token;
  }

  @override
  Future<void> resendPhone({
    required String baseUrl,
    required String phone,
  }) async {
    await _postAuth(baseUrl, '/auth/phone/resend', {'phone': phone});
  }

  @override
  Future<void> forgotPassword({
    required String baseUrl,
    required String phone,
  }) async {
    await _postAuth(baseUrl, '/auth/password/forgot', {'phone': phone});
  }

  @override
  Future<String> verifyReset({
    required String baseUrl,
    required String phone,
    required String code,
  }) async {
    final response = await _postAuth(baseUrl, '/auth/password/verify', {
      'phone': phone,
      'code': code,
    });
    final token = response.body['reset_token'];
    if (token is! String) {
      throw const DriverApiException('Mã đặt lại mật khẩu không hợp lệ.');
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
    await _postAuth(baseUrl, '/auth/password/reset', {
      'phone': phone,
      'token': resetToken,
      'password': password,
      'password_confirmation': password,
    });
  }

  @override
  Future<void> validateSession(DriverSession session) async {
    final response = await _transport.send(
      method: 'GET',
      uri: Uri.parse('${_base(session.baseUrl)}/me'),
      token: session.token,
    );
    _assertSuccess(response);
  }

  @override
  Future<List<DriverTicketSummary>> loadTickets(DriverSession session) async {
    final response = await _transport.send(
      method: 'GET',
      uri: _uri(session, '/support/tickets'),
      token: session.token,
    );
    _assertSuccess(response);
    return _listData(response)
        .map(DriverTicketSummary.fromJson)
        .toList(growable: false);
  }

  @override
  Future<DriverTicketSummary> loadTicket(
    DriverSession session,
    String id,
  ) async => DriverTicketSummary.fromJson(
    await _resource(session, 'GET', '/support/tickets/$id'),
  );

  @override
  Future<void> replyToTicket({
    required DriverSession session,
    required String id,
    required String body,
  }) async {
    await _resource(
      session,
      'POST',
      '/support/tickets/$id/messages',
      body: {'body': body},
    );
  }

  @override
  Future<void> logout(DriverSession session) async {
    final response = await _transport.send(
      method: 'POST',
      uri: Uri.parse('${_base(session.baseUrl)}/auth/logout'),
      token: session.token,
    );
    _assertSuccess(response);
  }

  @override
  Future<String> login({
    required String baseUrl,
    required String phone,
    required String password,
  }) async {
    return _loginAs(baseUrl, phone, password, 'DRIVER_APP');
  }

  Uri _uri(DriverSession session, String path) =>
      Uri.parse('${_base(session.baseUrl)}$path');

  Future<Map<String, dynamic>> _resource(
    DriverSession session,
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _transport.send(
      method: method,
      uri: _uri(session, path),
      token: session.token,
      body: body,
    );
    _assertSuccess(response);
    final data = response.body['data'];
    if (data is! Map<String, dynamic>) {
      throw const DriverApiException('Phản hồi máy chủ không hợp lệ.');
    }
    return data;
  }

  @override
  Future<DriverProfileSummary?> loadApplication(DriverSession session) async {
    try {
      return DriverProfileSummary.fromJson(
        await _resource(session, 'GET', '/driver/application'),
      );
    } on DriverApiException catch (error) {
      if (error.statusCode == 422) return null;
      rethrow;
    }
  }

  @override
  Future<DriverProfileSummary> saveApplication(DriverSession session) async =>
      DriverProfileSummary.fromJson(
        await _resource(session, 'POST', '/driver/application', body: const {}),
      );

  @override
  Future<List<Map<String, dynamic>>> loadVehicleTypes(
    DriverSession session,
  ) async {
    final response = await _transport.send(
      method: 'GET',
      uri: _uri(session, '/catalog/vehicle-types'),
      token: session.token,
    );
    _assertSuccess(response);
    return _listData(response);
  }

  @override
  Future<void> createVehicle({
    required DriverSession session,
    required String vehicleTypeId,
    required String plateNumber,
  }) async {
    await _resource(
      session,
      'POST',
      '/driver/vehicles',
      body: {'vehicle_type_id': vehicleTypeId, 'plate_number': plateNumber},
    );
  }

  @override
  Future<void> updateVehicle({
    required DriverSession session,
    required String vehicleId,
    required String vehicleTypeId,
    required String plateNumber,
  }) async {
    await _resource(
      session,
      'PATCH',
      '/driver/vehicles/$vehicleId',
      body: {'vehicle_type_id': vehicleTypeId, 'plate_number': plateNumber},
    );
  }

  Future<Map<String, dynamic>> _upload(
    DriverSession session,
    String path,
    String name,
    Uint8List bytes,
    Map<String, String> fields,
  ) async {
    final transport = _transport;
    if (transport is! MultipartApiTransport) {
      throw const DriverApiException('Thiết bị không hỗ trợ tải tệp.');
    }
    final response = await (transport as MultipartApiTransport).upload(
      uri: _uri(session, path),
      token: session.token,
      name: name,
      bytes: bytes,
      fields: fields,
    );
    _assertSuccess(response);
    final data = response.body['data'];
    if (data is! Map<String, dynamic>) {
      throw const DriverApiException('Phản hồi tải tệp không hợp lệ.');
    }
    return data;
  }

  @override
  Future<void> uploadDocument({
    required DriverSession session,
    required String documentType,
    required String name,
    required Uint8List bytes,
    String? documentNumber,
    String? vehicleId,
  }) async {
    await _upload(session, '/driver/documents', name, bytes, {
      'document_type': documentType,
      if (documentNumber != null && documentNumber.isNotEmpty)
        'document_number': documentNumber,
      if (vehicleId != null && vehicleId.isNotEmpty) 'vehicle_id': vehicleId,
    });
  }

  @override
  Future<void> submitApplication({
    required DriverSession session,
    required String vehicleId,
    required List<String> serviceTypes,
  }) async {
    await _resource(
      session,
      'POST',
      '/driver/application/submit',
      body: {'vehicle_id': vehicleId, 'service_types': serviceTypes},
    );
  }

  @override
  Future<DriverProfileSummary> setAvailability({
    required DriverSession session,
    required bool online,
    required double latitude,
    required double longitude,
    required double accuracy,
    required List<String> serviceTypes,
  }) async => DriverProfileSummary.fromJson(
    await _resource(
      session,
      'PUT',
      online ? '/driver/availability/online' : '/driver/availability/offline',
      body: online
          ? {
              'service_types': serviceTypes,
              'latitude': latitude,
              'longitude': longitude,
              'accuracy': accuracy,
              'captured_at': DateTime.now().toUtc().toIso8601String(),
            }
          : null,
    ),
  );

  @override
  Future<void> updateLocation({
    required DriverSession session,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    await _resource(
      session,
      'PUT',
      '/driver/location',
      body: {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'captured_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<String> uploadEvidence({
    required DriverSession session,
    required String serviceRequestId,
    required String evidenceType,
    required String name,
    required Uint8List bytes,
    required double latitude,
    required double longitude,
  }) async {
    final data = await _upload(
      session,
      '/driver/service-requests/$serviceRequestId/evidence',
      name,
      bytes,
      {
        'evidence_type': evidenceType,
        'latitude': '$latitude',
        'longitude': '$longitude',
      },
    );
    return data['id'] as String;
  }

  @override
  Future<void> createBankAccount({
    required DriverSession session,
    required String bankCode,
    required String accountNumber,
    required String accountName,
  }) async {
    await _resource(
      session,
      'POST',
      '/driver/bank-accounts',
      body: {
        'bank_code': bankCode,
        'account_number': accountNumber,
        'account_name': accountName,
      },
    );
  }

  @override
  Future<List<DriverOfferSummary>> loadOffers(DriverSession session) async {
    final response = await _transport.send(
      method: 'GET',
      uri: Uri.parse('${_base(session.baseUrl)}/driver/offers'),
      token: session.token,
    );
    _assertSuccess(response);
    final data = response.body['data'];
    if (data is! List) {
      throw const DriverApiException('Danh sách đề nghị không hợp lệ.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(DriverOfferSummary.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<DriverJobSummary>> loadJobHistory(DriverSession session) async {
    return (await loadJobHistoryPage(session)).jobs;
  }

  @override
  Future<DriverHistoryPage> loadJobHistoryPage(
    DriverSession session, {
    DriverHistoryFilter? filter,
  }) async {
    final query = filter?.toQuery() ?? const <String, String>{'page': '1'};
    final uri = _uri(
      session,
      '/driver/history',
    ).replace(queryParameters: query);
    final response = await _transport.send(
      method: 'GET',
      uri: uri,
      token: session.token,
    );
    _assertSuccess(response);
    final jobs = _listData(response)
        .map(DriverJobSummary.fromJson)
        .toList(growable: false);
    final meta = response.body['meta'] as Map<String, dynamic>? ?? const {};
    final summary = meta['summary'] as Map<String, dynamic>? ?? const {};
    return DriverHistoryPage(
      jobs: jobs,
      summary: DriverHistorySummary.fromJson(summary),
      currentPage: (meta['current_page'] as num?)?.toInt() ?? filter?.page ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  Future<DriverOfferSummary> respond({
    required DriverSession session,
    required DriverOfferSummary offer,
    required String action,
    required String idempotencyKey,
  }) async {
    final response = await _transport.send(
      method: 'POST',
      uri: Uri.parse(
        '${_base(session.baseUrl)}/driver/offers/${offer.id}/respond',
      ),
      token: session.token,
      headers: {'Idempotency-Key': idempotencyKey},
      body: {'action': action},
    );
    _assertSuccess(response);
    return DriverOfferSummary.fromJson(
      response.body['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<String> transition({
    required DriverSession session,
    required DriverOfferSummary offer,
    required String action,
    required double latitude,
    required double longitude,
    required String idempotencyKey,
    double? cashCollected,
    double? codCollected,
    String? evidenceId,
    String? outOfGeofenceReason,
  }) async {
    final response = await _transport.send(
      method: 'POST',
      uri: Uri.parse(
        '${_base(session.baseUrl)}/driver/service-requests/${offer.serviceRequestId}/transition',
      ),
      token: session.token,
      headers: {'Idempotency-Key': idempotencyKey},
      body: {
        'action': action,
        'latitude': latitude,
        'longitude': longitude,
        'cash_collected': ?cashCollected,
        'cod_collected': ?codCollected,
        'evidence_id': ?evidenceId,
        'out_of_geofence_reason': ?outOfGeofenceReason,
      },
    );
    _assertSuccess(response);
    return (response.body['data'] as Map<String, dynamic>)['status'] as String;
  }

  @override
  Future<DriverWalletSummary> loadWallet(DriverSession session) async {
    final response = await _transport.send(
      method: 'GET',
      uri: Uri.parse('${_base(session.baseUrl)}/wallet'),
      token: session.token,
    );
    _assertSuccess(response);
    return DriverWalletSummary.fromJson(
      response.body['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<DriverWalletTopupSummary> createTopup({
    required DriverSession session,
    required double amount,
    required String idempotencyKey,
  }) async {
    final response = await _transport.send(
      method: 'POST',
      uri: Uri.parse('${_base(session.baseUrl)}/driver/wallet/topups'),
      token: session.token,
      headers: {'Idempotency-Key': idempotencyKey},
      body: {'amount': amount},
    );
    _assertSuccess(response);
    return DriverWalletTopupSummary.fromJson(
      response.body['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<DriverBankAccountSummary>> loadBankAccounts(
    DriverSession session,
  ) async {
    final response = await _transport.send(
      method: 'GET',
      uri: Uri.parse('${_base(session.baseUrl)}/driver/bank-accounts'),
      token: session.token,
    );
    _assertSuccess(response);
    final data = response.body['data'] as List;
    return data
        .whereType<Map<String, dynamic>>()
        .map(DriverBankAccountSummary.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> requestWithdrawal({
    required DriverSession session,
    required String bankAccountId,
    required double amount,
    required String idempotencyKey,
  }) async {
    final response = await _transport.send(
      method: 'POST',
      uri: Uri.parse('${_base(session.baseUrl)}/driver/withdrawals'),
      token: session.token,
      headers: {'Idempotency-Key': idempotencyKey},
      body: {'bank_account_id': bankAccountId, 'amount': amount},
    );
    _assertSuccess(response);
  }

  @override
  Future<List<DriverChatMessage>> loadChat(
    DriverSession session,
    String serviceRequestId,
  ) async {
    final response = await _transport.send(
      method: 'GET',
      uri: Uri.parse(
        '${_base(session.baseUrl)}/service-requests/$serviceRequestId/chat',
      ),
      token: session.token,
    );
    _assertSuccess(response);
    return _listData(response)
        .map(DriverChatMessage.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> sendChat({
    required DriverSession session,
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
    required DriverSession session,
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
    required DriverSession session,
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
    required DriverSession session,
    required String serviceRequestId,
    required int score,
    String? comment,
  }) async {
    final response = await _transport.send(
      method: 'POST',
      uri: Uri.parse(
        '${_base(session.baseUrl)}/service-requests/$serviceRequestId/ratings',
      ),
      token: session.token,
      body: {
        'score': score,
        if (comment?.trim().isNotEmpty ?? false) 'comment': comment!.trim(),
      },
    );
    _assertSuccess(response);
  }

  @override
  Future<List<DriverNotificationSummary>> loadNotifications(
    DriverSession session,
  ) async {
    final response = await _transport.send(
      method: 'GET',
      uri: Uri.parse('${_base(session.baseUrl)}/notifications'),
      token: session.token,
    );
    _assertSuccess(response);
    return _listData(response)
        .map(DriverNotificationSummary.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> markNotificationRead(
    DriverSession session,
    String notificationId,
  ) async {
    final response = await _transport.send(
      method: 'PUT',
      uri: Uri.parse(
        '${_base(session.baseUrl)}/notifications/$notificationId/read',
      ),
      token: session.token,
    );
    _assertSuccess(response);
  }

  String _base(String value) => value.replaceFirst(RegExp(r'/$'), '');

  void _assertSuccess(ApiResponse response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final errors = response.body['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          throw DriverApiException(
            value.first.toString(),
            statusCode: response.statusCode,
          );
        }
      }
    }
    throw DriverApiException(
      response.body['message']?.toString() ?? 'Không thể hoàn tất yêu cầu.',
      statusCode: response.statusCode,
    );
  }

  List<Map<String, dynamic>> _listData(ApiResponse response) {
    final data = response.body['data'];
    if (data is! List) {
      throw const DriverApiException('Phản hồi từ máy chủ không hợp lệ.');
    }
    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}

class DriverApiException implements Exception {
  const DriverApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
