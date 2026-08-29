import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/currency_service.dart';

class CurrencyProvider extends ChangeNotifier {
  static const String _prefCurrencyCodeKey = 'user_currency_code';

  CurrencyInfo _currentCurrency = CurrencyService.defaultCurrency;
  CurrencyInfo get currentCurrency => _currentCurrency;

  String get symbol => _currentCurrency.symbol;
  String get code => _currentCurrency.code;
  String get country => _currentCurrency.country;
  String get countryCode => _currentCurrency.countryCode;

  CurrencyProvider() {
    _loadUserCurrency();
  }

  Future<void> _loadUserCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefCurrencyCodeKey);

      if (savedCode != null) {
        final match = CurrencyService.supportedCurrencies.firstWhere(
          (c) => c.code == savedCode,
          orElse: () => CurrencyService.defaultCurrency,
        );
        _currentCurrency = match;
      } else {
        _currentCurrency = CurrencyService.defaultCurrency;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading user currency: $e");
    }
  }

  Future<void> setCurrency(CurrencyInfo info) async {
    _currentCurrency = info;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefCurrencyCodeKey, info.code);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'country': info.country,
          'countryCode': info.countryCode,
          'currencySymbol': info.symbol,
          'currencyCode': info.code,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error saving user currency & country to Firestore: $e");
    }
  }

  String format(double amount) {
    return "$symbol${amount.toStringAsFixed(2)}";
  }
}