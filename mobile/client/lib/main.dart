import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'api/booking_api.dart';
import 'api/booking_realtime.dart';
import 'api/client_location.dart';
import 'api/goong_location_api.dart';
import 'api/push_token_provider.dart';
import 'api/session_store.dart';
import 'presentation/client_app.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  const sessionStore = SecureBookingSessionStore();
  final pushTokenProvider = PushTokenProvider();
  await pushTokenProvider.initialize();
  final savedToken = await sessionStore.readToken();
  final deviceId = await sessionStore.installationId();
  const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  const goongApiKey = String.fromEnvironment('GOONG_API_KEY');
  final defaultBaseUrl = kIsWeb
      ? 'http://127.0.0.1:8000/api/v1'
      : defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8000/api/v1'
      : 'http://127.0.0.1:8000/api/v1';

  runApp(
    BookingApp(
      gateway: BookingApi(
        deviceId: deviceId,
        pushTokenProvider: pushTokenProvider,
      ),
      locationSource: DeviceClientLocationSource(),
      goong: GoongLocationApi(apiKey: goongApiKey),
      sessionStore: sessionStore,
      realtime: BookingRealtime(),
      pushTokenProvider: pushTokenProvider,
      initialSession: BookingSession(
        baseUrl: configuredBaseUrl.isEmpty ? defaultBaseUrl : configuredBaseUrl,
        token: savedToken ?? const String.fromEnvironment('API_TOKEN'),
        vehicleTypeId: const String.fromEnvironment('VEHICLE_TYPE_ID'),
      ),
    ),
  );
}
