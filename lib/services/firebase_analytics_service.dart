import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseAnalyticsService {
  static final FirebaseAnalyticsService _instance = FirebaseAnalyticsService._internal();
  factory FirebaseAnalyticsService() => _instance;
  FirebaseAnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalytics get analytics => _analytics;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
    } catch (e) {
      debugPrint("Analytics logAppOpen error: $e");
    }
  }

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint("Analytics logScreenView error: $e");
    }
  }

  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint("Analytics logLogin error: $e");
    }
  }

  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint("Analytics logSignUp error: $e");
    }
  }

  Future<void> logAddTransaction({
    required String category,
    required double amount,
    required bool isExpense,
  }) async {
    try {
      await _analytics.logEvent(
        name: isExpense ? 'expense_logged' : 'income_logged',
        parameters: {
          'category': category,
          'amount': amount,
          'type': isExpense ? 'expense' : 'income',
        },
      );
    } catch (e) {
      debugPrint("Analytics logAddTransaction error: $e");
    }
  }

  Future<void> logProPlanView() async {
    try {
      await _analytics.logEvent(name: 'pro_screen_viewed');
    } catch (e) {
      debugPrint("Analytics logProPlanView error: $e");
    }
  }

  Future<void> logProPurchaseStarted(String planId) async {
    try {
      await _analytics.logEvent(
        name: 'pro_purchase_started',
        parameters: {'plan_id': planId},
      );
    } catch (e) {
      debugPrint("Analytics logProPurchaseStarted error: $e");
    }
  }

  Future<void> logProPurchaseSuccess(String planId) async {
    try {
      await _analytics.logEvent(
        name: 'pro_purchase_success',
        parameters: {'plan_id': planId},
      );
    } catch (e) {
      debugPrint("Analytics logProPurchaseSuccess error: $e");
    }
  }

  Future<void> logExportReport(String format) async {
    try {
      await _analytics.logEvent(
        name: 'report_exported',
        parameters: {'format': format},
      );
    } catch (e) {
      debugPrint("Analytics logExportReport error: $e");
    }
  }

  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint("Analytics setUserId error: $e");
    }
  }
}
