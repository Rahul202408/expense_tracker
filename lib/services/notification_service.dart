import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
    // Initialize Time Zones for Daily Scheduled Notifications
    tz.initializeTimeZones();

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

    // 9. Schedule Daily Reminder Notification (Morning 7:00 AM every day)
    await scheduleDailyNotification(hour: 7, minute: 0);
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

  /// Schedule a Daily Recurring Notification at given hour and minute (24-hour format)
  Future<void> scheduleDailyNotification({
    int hour = 7,
    int minute = 0,
    String title = "Good Morning! ☀️",
    String body = "આજના તમારા ખર્ચ (Expenses) ટ્રૅક કરવાનું શરૂ કરો!",
  }) async {
    try {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _localNotifications.zonedSchedule(
        id: 1001,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint("Daily notification scheduled for $hour:$minute every day.");
    } catch (e) {
      debugPrint("Error scheduling daily notification: $e");
    }
  }

  /// Cancel all scheduled daily notifications if needed
  Future<void> cancelDailyNotification() async {
    await _localNotifications.cancel(id: 1001);
  }
}


