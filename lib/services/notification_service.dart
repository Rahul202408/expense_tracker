import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const String _keyDailyEnabled = 'pref_daily_reminder_enabled';
  static const String _keyDailyHour = 'pref_daily_reminder_hour';
  static const String _keyDailyMinute = 'pref_daily_reminder_minute';
  static const String _keyBudgetAlertEnabled = 'pref_budget_alert_enabled';

  // Track last triggered alert state to prevent duplicate notifications in a single session
  bool _alert80Triggered = false;
  bool _alert100Triggered = false;

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

    // 9. Sync Daily Notification from saved SharedPreferences preferences
    await syncDailyNotificationFromPrefs();
  }

  /// Synchronize daily scheduled notification with SharedPreferences settings
  Future<void> syncDailyNotificationFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isEnabled = prefs.getBool(_keyDailyEnabled) ?? true;
    final int hour = prefs.getInt(_keyDailyHour) ?? 20; // Default 8:00 PM
    final int minute = prefs.getInt(_keyDailyMinute) ?? 0;

    if (isEnabled) {
      await scheduleDailyNotification(hour: hour, minute: minute);
    } else {
      await cancelDailyNotification();
    }
  }

  /// Getters for Notification Preferences
  Future<bool> getIsDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDailyEnabled) ?? true;
  }

  Future<TimeOfDay> getDailyReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final int hour = prefs.getInt(_keyDailyHour) ?? 20;
    final int minute = prefs.getInt(_keyDailyMinute) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<bool> getIsBudgetAlertEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBudgetAlertEnabled) ?? true;
  }

  /// Setters for Notification Preferences
  Future<void> setDailyReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailyEnabled, enabled);
    await syncDailyNotificationFromPrefs();
  }

  Future<void> setDailyReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyHour, time.hour);
    await prefs.setInt(_keyDailyMinute, time.minute);
    await syncDailyNotificationFromPrefs();
  }

  Future<void> setBudgetAlertEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBudgetAlertEnabled, enabled);
  }

  /// Trigger budget alert notification if threshold (80% or 100%) is reached
  Future<void> checkAndTriggerBudgetAlert({
    required double expense,
    required double income,
  }) async {
    final isEnabled = await getIsBudgetAlertEnabled();
    if (!isEnabled || income <= 0) return;

    final double ratio = expense / income;
    if (ratio >= 1.0) {
      if (!_alert100Triggered) {
        _alert100Triggered = true;
        await showLocalNotification(
          id: 2002,
          title: "🚨 Budget Limit Exceeded! (100%)",
          body: "You have crossed 100% of your budget limit. Check your spending!",
        );
      }
    } else if (ratio >= 0.8) {
      if (!_alert80Triggered) {
        _alert80Triggered = true;
        await showLocalNotification(
          id: 2001,
          title: "⚠️ High Spending Alert! (80%)",
          body: "You have spent over 80% of your total budget. Spend wisely!",
        );
      }
    } else {
      // Reset triggers if budget goes back below 80%
      _alert80Triggered = false;
      _alert100Triggered = false;
    }
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
    required int hour,
    required int minute,
    String title = "Daily Expense Reminder 📝",
    String body = "Don't forget to track your daily expenses today!",
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


