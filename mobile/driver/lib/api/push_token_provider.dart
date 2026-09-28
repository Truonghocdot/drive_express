import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class PushTokenProvider {
  FirebaseMessaging? _messaging;
  StreamSubscription<String>? _refreshSubscription;
  String? _token;

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
      _token = await _messaging!.getToken();
      _refreshSubscription = _messaging!.onTokenRefresh.listen((token) {
        _token = token;
      });
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

  Future<void> dispose() async {
    await _refreshSubscription?.cancel();
  }
}
