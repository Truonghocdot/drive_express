import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../api/booking_api.dart';
import '../api/booking_realtime.dart';
import '../api/client_location.dart';
import '../api/goong_location_api.dart';
import '../api/session_store.dart';
import '../api/push_token_provider.dart';
import 'client_app_controller.dart';
import 'pages/auth/login_page.dart';
import 'pages/main_navigation_page.dart';
import 'pages/order/active_order_tracking_page.dart';
import 'theme/app_theme.dart';

class BookingApp extends StatefulWidget {
  const BookingApp({
    super.key,
    required this.gateway,
    required this.initialSession,
    this.locationSource,
    this.goong,
    this.sessionStore,
    this.realtime,
    this.pushTokenProvider,
  });

  final BookingGateway gateway;
  final BookingSession initialSession;
  final ClientLocationSource? locationSource;
  final GoongLocationApi? goong;
  final BookingSessionStore? sessionStore;
  final BookingRealtime? realtime;
  final PushTokenProvider? pushTokenProvider;

  @override
  State<BookingApp> createState() => _BookingAppState();
}

class _BookingAppState extends State<BookingApp> {
  final navigatorKey = GlobalKey<NavigatorState>();
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription? foregroundSubscription;
  StreamSubscription? openedSubscription;
  late final ClientAppController controller = ClientAppController(
    gateway: widget.gateway,
    initialSession: widget.initialSession,
    locationSource: widget.locationSource,
    goong: widget.goong,
    sessionStore: widget.sessionStore,
    realtime: widget.realtime,
  );

  @override
  void initState() {
    super.initState();
    controller.initialize();
    controller.prepareLocation();
    foregroundSubscription = widget.pushTokenProvider?.foregroundMessages
        .listen(_handleForegroundMessage);
    openedSubscription = widget.pushTokenProvider?.openedMessages.listen(
      _openNotification,
    );
    _openInitialNotification();
  }

  @override
  void dispose() {
    foregroundSubscription?.cancel();
    openedSubscription?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Giao hàng & Đặt xe',
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [Locale('vi', 'VN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ClientTheme.light(),
      darkTheme: ClientTheme.dark(),
      themeMode: ThemeMode.system,
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.initializing) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return controller.authenticated
              ? MainNavigationPage(controller: controller)
              : LoginPage(controller: controller);
        },
      ),
    );
  }

  Future<void> _openInitialNotification() async {
    final message = await widget.pushTokenProvider?.initialMessage();
    if (message != null) await _openNotification(message);
  }

  void _handleForegroundMessage(dynamic message) {
    unawaited(controller.loadNotifications());
    final title = message.notification?.title ?? 'Drive';
    final body = message.notification?.body ?? 'Bạn có cập nhật mới.';
    messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('$title: $body')),
    );
  }

  Future<void> _openNotification(dynamic message) async {
    unawaited(controller.loadNotifications());
    final requestId = message.data['service_request_id']?.toString();
    if (requestId == null || requestId.isEmpty || !controller.authenticated) {
      return;
    }
    await controller.openServiceRequest(requestId);
    if (!mounted || controller.activeRequest == null) return;
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ActiveOrderTrackingPage(controller: controller),
      ),
    );
  }
}
