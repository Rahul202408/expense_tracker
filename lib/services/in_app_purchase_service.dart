import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InAppPurchaseService {
  static final InAppPurchaseService _instance = InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  InAppPurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Product IDs configured in Google Play Console
  static const String monthlyPlanId = 'pro_monthly';
  static const String yearlyPlanId = 'pro_yearly';
  static const String lifetimePlanId = 'pro_lifetime';
  static const String altLifetimePlanId = 'lifetime-buy';

  static const Set<String> _productIds = {
    monthlyPlanId,
    yearlyPlanId,
    lifetimePlanId,
    altLifetimePlanId,
  };

  static const String _prefIsProKey = 'is_pro_user';
  static const String _prefPlanKey = 'pro_plan_id';
  static const String _prefPurchaseDateKey = 'pro_purchase_date';

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  List<String> _notFoundIds = [];
  List<String> get notFoundIds => _notFoundIds;

  String? _lastError;
  String? get lastError => _lastError;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  bool _isFetching = false;
  bool get isFetching => _isFetching;

  Function(bool isPro, String? planId)? onProStatusChanged;

  final StreamController<String> _purchaseCompletedController =
      StreamController<String>.broadcast();
  /// Stream that emits the purchased plan ID ONLY when Google Play genuinely confirms payment
  Stream<String> get onPurchaseCompleted => _purchaseCompletedController.stream;

  final StreamController<void> _purchaseCanceledController =
      StreamController<void>.broadcast();
  /// Stream that emits when the user cancels the Google Play billing flow or closes without paying
  Stream<void> get onPurchaseCanceled => _purchaseCanceledController.stream;

  final StreamController<String> _purchaseErrorController =
      StreamController<String>.broadcast();
  /// Stream that emits when Google Play encounters an error during payment
  Stream<String> get onPurchaseError => _purchaseErrorController.stream;

  /// For debug/testing: trigger purchase completion stream manually
  void notifyPurchaseSuccessForTesting(String planId) {
    _purchaseCompletedController.add(planId);
  }

  /// Initialize In-App Purchase and listen to purchase updates
  Future<void> initialize() async {
    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        _lastError = "Google Play Store is not available on this device.";
        debugPrint("InAppPurchase: Store is not available.");
        return;
      }

      // Cancel previous subscription if active
      await _subscription?.cancel();

      // Listen to purchases stream
      _subscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) => debugPrint("InAppPurchase Stream Error: $error"),
      );

      // Fetch product details from store
      await fetchProducts();
    } catch (e) {
      _lastError = e.toString();
      debugPrint("InAppPurchase initialize error: $e");
    }
  }

  /// Fetch product details from Google Play Store
  Future<void> fetchProducts() async {
    _isFetching = true;
    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        _lastError = "Google Play Store is not available on this device.";
        _isFetching = false;
        return;
      }

      final ProductDetailsResponse response =
          await _iap.queryProductDetails(_productIds).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint("InAppPurchase: queryProductDetails timed out");
          return ProductDetailsResponse(
            productDetails: [],
            notFoundIDs: _productIds.toList(),
          );
        },
      );

      _notFoundIds = response.notFoundIDs;

      if (response.error != null) {
        _lastError = response.error!.message;
        debugPrint("InAppPurchase query error: ${response.error!.message}");
      }

      if (response.productDetails.isNotEmpty) {
        _products = response.productDetails;
        _lastError = null;
        debugPrint("InAppPurchase: Loaded ${_products.length} products from store.");
      } else if (_notFoundIds.isNotEmpty) {
        _lastError = "Products not found in Google Play: ${_notFoundIds.join(', ')}";
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint("InAppPurchase: Failed to fetch products: $e");
    } finally {
      _isFetching = false;
    }
  }

  /// Start purchase flow with detailed diagnostic results
  Future<PurchaseResult> buyProductWithResult(String productId) async {
    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        return const PurchaseResult(
          success: false,
          isStoreUnavailable: true,
          message: "Google Play Store billing service is not available on this device.",
        );
      }

      ProductDetails? product;
      try {
        if (productId == lifetimePlanId || productId == altLifetimePlanId) {
          product = _products.firstWhere(
            (p) => p.id == lifetimePlanId || p.id == altLifetimePlanId,
          );
        } else {
          product = _products.firstWhere((p) => p.id == productId);
        }
      } catch (_) {
        product = null;
      }

      // If product not found in cached list, try fetching from store
      if (product == null) {
        await fetchProducts();
        try {
          if (productId == lifetimePlanId || productId == altLifetimePlanId) {
            product = _products.firstWhere(
              (p) => p.id == lifetimePlanId || p.id == altLifetimePlanId,
            );
          } else {
            product = _products.firstWhere((p) => p.id == productId);
          }
        } catch (_) {
          product = null;
        }
      }

      if (product == null) {
        debugPrint("InAppPurchase: Product $productId not found in store details.");
        return PurchaseResult(
          success: false,
          isProductNotFound: true,
          message: "Product '$productId' was not returned by Google Play Store.",
        );
      }

      PurchaseParam purchaseParam;
      if (product is GooglePlayProductDetails) {
        if (product.id == lifetimePlanId || product.id == altLifetimePlanId) {
          // One-time non-consumable product
          purchaseParam = GooglePlayPurchaseParam(productDetails: product);
        } else {
          // Subscription: Google Play Billing 5+ requires offerToken
          final String? offerToken = product.offerToken;
          if (offerToken != null) {
            purchaseParam = GooglePlayPurchaseParam(
              productDetails: product,
              offerToken: offerToken,
            );
          } else {
            purchaseParam = GooglePlayPurchaseParam(productDetails: product);
          }
        }
      } else {
        purchaseParam = PurchaseParam(productDetails: product);
      }

      final launched = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (launched) {
        return const PurchaseResult(
          success: true,
          message: "Purchase initiated successfully in Google Play.",
        );
      } else {
        return const PurchaseResult(
          success: false,
          message: "Google Play purchase dialog could not be launched. Please try again.",
        );
      }
    } catch (e) {
      debugPrint("InAppPurchase: Exception in buyProduct: $e");
      return PurchaseResult(
        success: false,
        message: "An error occurred while launching Google Play billing: $e",
      );
    }
  }

  /// Start purchase flow (backwards compatibility)
  Future<bool> buyProduct(String productId) async {
    final result = await buyProductWithResult(productId);
    return result.success;
  }

  /// Handle incoming purchase updates from Google Play
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint("InAppPurchase: Purchase pending for ${purchaseDetails.productID}");
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        final errorMsg = purchaseDetails.error?.message ?? "Payment encountered an error";
        debugPrint("InAppPurchase: Purchase error: $errorMsg");
        _purchaseErrorController.add(errorMsg);
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        debugPrint("InAppPurchase: Purchase canceled for ${purchaseDetails.productID}");
        _purchaseCanceledController.add(null);
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        // Genuine new payment confirmed by Google Play!
        debugPrint("InAppPurchase: Payment CONFIRMED by Google Play for ${purchaseDetails.productID}");
        await _deliverProduct(purchaseDetails.productID);

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }

        // Fire confirmation event ONLY when user has successfully paid
        _purchaseCompletedController.add(purchaseDetails.productID);
      } else if (purchaseDetails.status == PurchaseStatus.restored) {
        // Restored existing purchase
        debugPrint("InAppPurchase: Purchase restored for ${purchaseDetails.productID}");
        await _deliverProduct(purchaseDetails.productID);

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  /// Deliver product and save Pro status locally and in Firestore
  Future<void> _deliverProduct(String productId) async {
    await saveProStatus(isPro: true, planId: productId);
    if (onProStatusChanged != null) {
      onProStatusChanged!(true, productId);
    }
  }

  /// Save Pro status to SharedPreferences and Firebase Firestore
  Future<void> saveProStatus({
    required bool isPro,
    String? planId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefIsProKey, isPro);
    if (planId != null) {
      await prefs.setString(_prefPlanKey, planId);
      await prefs.setString(_prefPurchaseDateKey, DateTime.now().toIso8601String());
    } else if (!isPro) {
      await prefs.remove(_prefPlanKey);
      await prefs.remove(_prefPurchaseDateKey);
    }

    // Sync with Firebase Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'isPro': isPro,
          'proPlan': planId,
          'proUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error syncing Pro status to Firestore: $e");
    }
  }

  /// Clear Pro status locally (e.g., on logout or for a free user)
  Future<void> clearProStatusLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefIsProKey, false);
    await prefs.remove(_prefPlanKey);
    await prefs.remove(_prefPurchaseDateKey);
    if (onProStatusChanged != null) {
      onProStatusChanged!(false, null);
    }
  }

  /// Load cached Pro status from SharedPreferences (only if user is logged in)
  Future<bool> getIsPro() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefIsProKey) ?? false;
  }

  /// Load current active plan ID
  Future<String?> getActivePlanId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefPlanKey);
  }

  /// Restore purchases for user (e.g., when switching devices)
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint("InAppPurchase: Restore error: $e");
    }
  }

  /// Sync Pro subscription state from Firebase Firestore (e.g. across installs/devices/new logins)
  Future<void> syncProStatusFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await clearProStatusLocally();
        return;
      }
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final isPro = doc.data()!['isPro'] as bool? ?? false;
        final planId = doc.data()!['proPlan'] as String?;
        if (isPro) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_prefIsProKey, true);
          if (planId != null) {
            await prefs.setString(_prefPlanKey, planId);
          }
          if (onProStatusChanged != null) {
            onProStatusChanged!(true, planId);
          }
        } else {
          // Explicitly clear local Pro cache for free users!
          await clearProStatusLocally();
        }
      } else {
        // Document does not exist or user has never bought Pro: clear local cache!
        await clearProStatusLocally();
      }
    } catch (e) {
      debugPrint("InAppPurchase: Error syncing Pro status from Firestore: $e");
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

class PurchaseResult {
  final bool success;
  final String message;
  final bool isStoreUnavailable;
  final bool isProductNotFound;

  const PurchaseResult({
    required this.success,
    required this.message,
    this.isStoreUnavailable = false,
    this.isProductNotFound = false,
  });
}
