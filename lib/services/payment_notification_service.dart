import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentNotificationService {
  static final PaymentNotificationService _instance = PaymentNotificationService._internal();
  factory PaymentNotificationService() => _instance;
  PaymentNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const String prefAutoDetectKey = 'auto_detect_payments';

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handled when user taps the auto-expense notification
      },
    );
  }

  Future<bool> isAutoDetectEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefAutoDetectKey) ?? true;
  }

  Future<void> setAutoDetectEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefAutoDetectKey, enabled);
  }

  Future<void> processNotification({
    required String packageName,
    required String title,
    required String text,
  }) async {
    final isEnabled = await isAutoDetectEnabled();
    if (!isEnabled) return;

    final fullContent = '\ \';
    final amount = _extractAmount(fullContent);

    if (amount == null || amount <= 0) return;

    final merchant = _extractMerchant(fullContent, packageName);
    final paymentApp = _getPaymentAppName(packageName);
    final category = _guessCategory(merchant, fullContent);

    await _saveAutoExpense(
      amount: amount,
      title: merchant,
      category: category,
      paymentMethod: paymentApp,
    );

    await _showNotification(
      amount: amount,
      merchant: merchant,
      paymentApp: paymentApp,
    );
  }

  double? _extractAmount(String text) {
    final regexes = [
      RegExp(r'(?:paid|sent|debited|spent|transferred|?|rs|inr)\s*[\:?\s]*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
      RegExp(r'([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:paid|debited|sent|spent)', caseSensitive: false),
    ];

    for (final reg in regexes) {
      final match = reg.firstMatch(text);
      if (match != null) {
        final str = match.group(1)?.replaceAll(',', '');
        if (str != null) {
          final val = double.tryParse(str);
          if (val != null && val > 0) return val;
        }
      }
    }
    return null;
  }

  String _extractMerchant(String text, String packageName) {
    final merchantRegex = RegExp(
      r'(?:to|at|for)\s+([A-Za-z0-9\s&.-]+?)(?=\s+(?:via|using|ref|on|bal|account|upi)|$)',
      caseSensitive: false,
    );
    final match = merchantRegex.firstMatch(text);
    if (match != null) {
      final found = match.group(1)?.trim();
      if (found != null && found.isNotEmpty && found.length < 30) {
        return found;
      }
    }
    return _getPaymentAppName(packageName);
  }

  String _getPaymentAppName(String packageName) {
    if (packageName.contains('paisa') || packageName.contains('gpay')) return 'Google Pay';
    if (packageName.contains('phonepe')) return 'PhonePe';
    if (packageName.contains('paytm')) return 'Paytm';
    if (packageName.contains('bhim') || packageName.contains('npci')) return 'BHIM';
    if (packageName.contains('cred')) return 'Cred';
    if (packageName.contains('amazon')) return 'Amazon Pay';
    return 'Online Payment';
  }

  String _guessCategory(String merchant, String fullText) {
    final lower = '\ \'.toLowerCase();

    if (lower.contains('swiggy') || lower.contains('zomato') || lower.contains('food') || lower.contains('restaurant') || lower.contains('tea') || lower.contains('cafe')) {
      return 'Food';
    }
    if (lower.contains('amazon') || lower.contains('flipkart') || lower.contains('myntra') || lower.contains('shopping') || lower.contains('store') || lower.contains('mart')) {
      return 'Shopping';
    }
    if (lower.contains('uber') || lower.contains('ola') || lower.contains('rapido') || lower.contains('metro') || lower.contains('fuel') || lower.contains('petrol')) {
      return 'Transport';
    }
    if (lower.contains('recharge') || lower.contains('bill') || lower.contains('electricity') || lower.contains('water') || lower.contains('broadband')) {
      return 'Bills';
    }
    if (lower.contains('movie') || lower.contains('cinema') || lower.contains('bookmyshow') || lower.contains('netflix')) {
      return 'Entertainment';
    }
    return 'General';
  }

  Future<void> _saveAutoExpense({
    required double amount,
    required String title,
    required String category,
    required String paymentMethod,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('expenses').add({
      'userId': user.uid,
      'title': title,
      'amount': amount,
      'category': category,
      'type': 'expense',
      'paymentMethod': paymentMethod,
      'date': Timestamp.now(),
      'note': 'Auto-detected from \',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _showNotification({
    required double amount,
    required String merchant,
    required String paymentApp,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'auto_expense_channel',
      'Auto Expense Detection',
      channelDescription: 'Notifications for auto-detected payments from GPay, PhonePe, Paytm, etc.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Auto Expense Added! ??',
      body: '?\ for "\" via \ saved to expenses.',
      notificationDetails: details,
    );
  }
}
