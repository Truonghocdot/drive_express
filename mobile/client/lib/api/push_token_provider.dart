import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class PushTokenProvider {
  FirebaseMessaging? _messaging;
  StreamSubscription<String>? _refreshSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  String? _token;
  final _foregroundMessages = StreamController<RemoteMessage>.broadcast();
  final _openedMessages = StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get foregroundMessages => _foregroundMessages.stream;
  Stream<RemoteMessage> get openedMessages => _openedMessages.stream;

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      _messaging = FirebaseMessaging.instance;
      await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      _token = await _messaging!.getToken();
      _refreshSubscription = _messaging!.onTokenRefresh.listen((token) {
        _token = token;
      });
      _messageSubscription = FirebaseMessaging.onMessage.listen(
        _foregroundMessages.add,
      );
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _openedMessages.add,
      );
    } catch (error) {
      debugPrint('Firebase messaging is unavailable: $error');
      _messaging = null;
    }
  }

  Future<String?> token() async {
    if (_messaging == null) {
      return _token;
    }

    try {
      _token ??= await _messaging!.getToken();
    } catch (error) {
      debugPrint('Unable to read Firebase messaging token: $error');
    }

    return _token;
  }

  Future<RemoteMessage?> initialMessage() =>
      _messaging?.getInitialMessage() ?? Future.value();

  Future<void> dispose() async {
    await _refreshSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _foregroundMessages.close();
    await _openedMessages.close();
  }
}
