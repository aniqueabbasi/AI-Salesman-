import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 BG Message: ${message.messageId}');
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;

  

  static Future<void> initialize() async {
    // Request permissions on iOS / Android 13+
    await _messaging.requestPermission();

    // Get token for testing/logging
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      debugPrint('📩 FG Message: ${msg.messageId}');
      // TODO: Display in-app notification UI if desired.
    });

    // When app opened from a terminated state via a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      debugPrint('🔗 Notification tapped: ${msg.messageId}');
      // TODO: Navigate or handle data payload.
    });
  }
}
