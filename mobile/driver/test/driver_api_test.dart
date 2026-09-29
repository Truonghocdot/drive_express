import 'package:driver/api/api_transport.dart';
import 'package:driver/api/driver_api.dart';
import 'package:driver/api/push_token_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses HTTPS endpoints for offer list and response', () async {
    final transport = RecordingTransport();
    final api = DriverApi(transport: transport);
    const session = DriverSession(
      baseUrl: 'http://localhost/api/v1',
      token: 'driver-token',
    );

    final offers = await api.loadOffers(session);
    await api.respond(
      session: session,
      offer: offers.first,
      action: 'accept',
      idempotencyKey: 'accept-key',
    );

    expect(transport.calls[0].uri.path, '/api/v1/driver/offers');
    expect(
      transport.calls[1].uri.path,
      '/api/v1/driver/offers/offer-1/respond',
    );
    expect(transport.calls[1].headers['Idempotency-Key'], 'accept-key');
  });

  test(
    'creates a driver wallet VietQR top-up through the driver endpoint',
    () async {
      final transport = RecordingTransport();
      final api = DriverApi(transport: transport);
      const session = DriverSession(
        baseUrl: 'http://localhost/api/v1',
        token: 'driver-token',
      );

      final topup = await api.createTopup(
        session: session,
        amount: 200000,
        idempotencyKey: 'driver-topup-key',
      );

      expect(topup.status, 'PENDING');
      expect(transport.calls.single.uri.path, '/api/v1/driver/wallet/topups');
      expect(
        transport.calls.single.headers['Idempotency-Key'],
        'driver-topup-key',
      );
    },
  );

  test('includes the FCM token in the driver login device context', () async {
    final transport = LoginTransport();
    final api = DriverApi(
      transport: transport,
      pushTokenProvider: FixedPushTokenProvider('driver-fcm-token'),
    );

    await api.login(
      baseUrl: 'http://localhost/api/v1',
      phone: '+84900000000',
      password: 'password',
    );

    expect(transport.body?['push_token'], 'driver-fcm-token');
    expect(transport.body?['app_type'], 'DRIVER_APP');
  });

  test('parses hourly offers with missing optional numeric fields', () {
    final offer = DriverOfferSummary.fromJson({
      'id': 'offer-hourly',
      'status': 'PENDING',
      'estimated_pickup_distance_meters': null,
      'estimated_driver_earning': null,
      'expires_at': DateTime.now().toUtc().toIso8601String(),
      'service_request': {
        'id': 'request-hourly',
        'service_type': 'HOURLY',
        'status': 'DRIVER_ARRIVING',
        'payment': {'method': 'CASH', 'customer_payable': null},
        'stops': [
          {'type': 'PICKUP', 'latitude': 10.77, 'longitude': 106.68},
        ],
      },
    });

    expect(offer.customerPayable, 0);
    expect(offer.estimatedEarning, 0);
    expect(offer.dropoffLatitude, offer.pickupLatitude);
  });

  test('reports an invalid offer without a pickup instead of casting null', () {
    expect(
      () => DriverOfferSummary.fromJson({
        'id': 'offer-invalid',
        'status': 'PENDING',
        'service_request': {
          'id': 'request-invalid',
          'service_type': 'DRIVE',
          'status': 'SEARCHING_DRIVER',
          'payment': {'method': 'CASH'},
          'stops': null,
        },
      }),
      throwsA(isA<DriverApiException>()),
    );
  });
}

class FixedPushTokenProvider extends PushTokenProvider {
  FixedPushTokenProvider(this.value);

  final String value;

  @override
  Future<String?> token() async => value;
}

class LoginTransport implements ApiTransport {
  Map<String, dynamic>? body;

  @override
  Future<ApiResponse> send({
    required String method,
    required Uri uri,
    required String token,
    Map<String, dynamic>? body,
    Map<String, String> headers = const {},
  }) async {
    this.body = body;
    return ApiResponse(200, {'token': 'session-token'});
  }
}

class RecordingTransport implements ApiTransport {
  final calls = <RecordedCall>[];

  @override
  Future<ApiResponse> send({
    required String method,
    required Uri uri,
    required String token,
    Map<String, dynamic>? body,
    Map<String, String> headers = const {},
  }) async {
    calls.add(RecordedCall(uri: uri, headers: headers));
    if (uri.path.endsWith('/driver/wallet/topups')) {
      return ApiResponse(201, {
        'data': {
          'id': 'topup-1',
          'amount': 200000,
          'status': 'PENDING',
          'vietqr_reference': 'TOPUP-TEST',
          'vietqr_payload': 'bank=MB&amount=200000',
          'expires_at': DateTime.now()
              .add(const Duration(minutes: 30))
              .toUtc()
              .toIso8601String(),
        },
      });
    }
    final status = body?['action'] == 'accept' ? 'ACCEPTED' : 'PENDING';
    final offer = {
      'id': 'offer-1',
      'status': status,
      'estimated_pickup_distance_meters': 500,
      'estimated_driver_earning': 15000,
      'expires_at': DateTime.now()
          .add(const Duration(seconds: 30))
          .toUtc()
          .toIso8601String(),
      'service_request': {
        'id': 'request-1',
        'service_type': 'DELIVERY',
        'status': 'DRIVER_ARRIVING_PICKUP',
        'payment': {'method': 'CASH', 'customer_payable': 18000},
        'stops': [
          {'type': 'PICKUP', 'latitude': 10.77, 'longitude': 106.68},
          {'type': 'DROPOFF', 'latitude': 10.78, 'longitude': 106.69},
        ],
      },
    };
    return ApiResponse(200, {
      'data': method == 'GET' ? [offer] : offer,
    });
  }
}

class RecordedCall {
  const RecordedCall({required this.uri, required this.headers});
  final Uri uri;
  final Map<String, String> headers;
}
