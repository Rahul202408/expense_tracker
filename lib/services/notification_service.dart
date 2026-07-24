import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Permission માંગો
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint("Permission: ${settings.authorizationStatus}");

    // Device Token
    String? token = await _messaging.getToken();

    debugPrint("FCM TOKEN:");
    debugPrint(token);

    // Foreground Notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Title: ${message.notification?.title}");
      debugPrint("Body: ${message.notification?.body}");
    });
  }
}
