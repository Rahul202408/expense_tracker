import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important expense tracker notifications.',
    importance: Importance.high,
  );

  Future<void> init() async {
    // 1. Request FCM Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint("Notification Permission status: ${settings.authorizationStatus}");

    // 2. Set FCM background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Set iOS/macOS Foreground Presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Initialize Local Notifications for Android & iOS
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint("Notification clicked with payload: ${details.payload}");
      },
    );

    // 5. Create Android Notification Channel
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(_channel);
      await androidImplementation.requestNotificationsPermission();
    }

    // 6. Get & Log FCM Token
    try {
      String? token = await _messaging.getToken();
      debugPrint("FCM TOKEN: $token");
    } catch (e) {
      debugPrint("Error fetching FCM token: $e");
    }

    // 7. Handle Foreground Notifications (Display using Local Notifications)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Received Foreground Message: ${message.notification?.title}");

      final notification = message.notification;

      if (notification != null) {
        showLocalNotification(
          id: notification.hashCode,
          title: notification.title ?? "Expense Tracker",
          body: notification.body ?? "",
          payload: message.data.toString(),
        );
      }
    });

    // 8. Handle Notification click when app opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("App opened from notification: ${message.notification?.title}");
    });
  }

  /// Show a local heads-up notification instantly
  Future<void> showLocalNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}
