import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/in_app_purchase_service.dart';

class ProProvider with ChangeNotifier {
  final InAppPurchaseService _iapService = InAppPurchaseService();

  bool _isPro = false;
  String? _activePlanId;
  bool _isLoading = false;

  bool get isPro => _isPro;
  String? get activePlanId => _activePlanId;
  bool get isLoading => _isLoading;

  Stream<String> get onPurchaseCompleted => _iapService.onPurchaseCompleted;
  Stream<void> get onPurchaseCanceled => _iapService.onPurchaseCanceled;
  Stream<String> get onPurchaseError => _iapService.onPurchaseError;

  ProProvider() {
    init();
  }

  Future<void> init() async {
    try {
      // Setup listener for In-App Purchase status changes
      _iapService.onProStatusChanged = (isPro, planId) {
        _isPro = isPro;
        _activePlanId = planId;
        notifyListeners();
      };

      // Listen to Firebase Auth state changes (Account login / logout / switch)
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user == null) {
          _isPro = false;
          _activePlanId = null;
          await _iapService.clearProStatusLocally();
        } else {
          await _iapService.syncProStatusFromFirestore();
          _isPro = await _iapService.getIsPro();
          _activePlanId = await _iapService.getActivePlanId();
        }
        notifyListeners();
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _isPro = false;
        _activePlanId = null;
        await _iapService.clearProStatusLocally();
      } else {
        await _iapService.syncProStatusFromFirestore();
        _isPro = await _iapService.getIsPro();
        _activePlanId = await _iapService.getActivePlanId();
      }

      await _iapService.initialize();
    } catch (e) {
      debugPrint("ProProvider init error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sync user PRO subscription status from Firestore
  Future<void> syncFromFirestore() async {
    await _iapService.syncProStatusFromFirestore();
  }

  /// Refresh products list from Google Play Store
  Future<void> refreshProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _iapService.fetchProducts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Purchase plan via Google Play Billing with detailed diagnostic result
  Future<PurchaseResult> purchasePlanWithResult(String planId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final PurchaseResult result = await _iapService.buyProductWithResult(planId).timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          debugPrint("InAppPurchase: buyProduct timed out");
          return const PurchaseResult(
            success: false,
            message: "Google Play Store request timed out. Please check your internet connection.",
          );
        },
      );
      return result;
    } catch (e) {
      debugPrint("Purchase error: $e");
      return PurchaseResult(
        success: false,
        message: "Purchase error: $e",
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Purchase plan via Google Play Billing (boolean outcome)
  Future<bool> purchasePlan(String planId) async {
    final result = await purchasePlanWithResult(planId);
    return result.success;
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _iapService.restorePurchases().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint("InAppPurchase: restorePurchases timed out");
        },
      );
      _isPro = await _iapService.getIsPro();
      _activePlanId = await _iapService.getActivePlanId();
    } catch (e) {
      debugPrint("Restore error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Manual Mock Upgrade for Debug / Testing
  Future<void> mockUpgradeForTesting(String planId) async {
    _isPro = true;
    _activePlanId = planId;
    await _iapService.saveProStatus(isPro: true, planId: planId);
    _iapService.notifyPurchaseSuccessForTesting(planId);
    notifyListeners();
  }

  /// Cancel / Downgrade for Debug / Testing
  Future<void> mockDowngradeForTesting() async {
    _isPro = false;
    _activePlanId = null;
    await _iapService.saveProStatus(isPro: false);
    notifyListeners();
  }
}
