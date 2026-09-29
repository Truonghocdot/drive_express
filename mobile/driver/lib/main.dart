import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'api/driver_api.dart';
import 'api/driver_realtime.dart';
import 'api/goong_navigation_api.dart';
import 'api/push_token_provider.dart';
import 'api/session_store.dart';
import 'presentation/driver_app.dart';
import 'firebase_options.dart';

export 'presentation/driver_app.dart';

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
  const sessionStore = SecureDriverSessionStore();
  final pushTokenProvider = PushTokenProvider();
  await pushTokenProvider.initialize();
  final savedToken = await sessionStore.readToken();
  final onboarding = await sessionStore.readOnboarding();
  final deviceId = await sessionStore.installationId();
  const configured = String.fromEnvironment('API_BASE_URL');
  const goongApiKey = String.fromEnvironment('GOONG_API_KEY');
  final defaultUrl = defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8000/api/v1'
      : 'http://127.0.0.1:8000/api/v1';

  runApp(
    DriverApp(
      gateway: DriverApi(
        deviceId: deviceId,
        pushTokenProvider: pushTokenProvider,
      ),
      goong: GoongNavigationApi(apiKey: goongApiKey),
      sessionStore: sessionStore,
      realtime: DriverRealtime(),
      pushTokenProvider: pushTokenProvider,
      initialSession: DriverSession(
        baseUrl: configured.isEmpty ? defaultUrl : configured,
        token: savedToken ?? const String.fromEnvironment('API_TOKEN'),
        onboarding: onboarding,
      ),
    ),
  );
}
