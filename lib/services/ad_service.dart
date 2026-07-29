import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  /// Check if test ads should be used (defaults to true if not specified in .env)
  static bool get useTestAds {
    final flag = dotenv.env['ADMOB_USE_TEST_ADS'];
    if (flag != null) {
      return flag.toLowerCase() == 'true';
    }
    return kDebugMode;
  }

  /// Official Google Test Banner Ad Unit IDs
  static const String _androidTestBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _iosTestBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';

  /// Official Google Test Interstitial Ad Unit IDs
  static const String _androidTestInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _iosTestInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';

  /// Official Google Test App Open Ad Unit IDs
  static const String _androidTestAppOpenAdUnitId = 'ca-app-pub-3940256099942544/9257395921';
  static const String _iosTestAppOpenAdUnitId = 'ca-app-pub-3940256099942544/5632439545';

  /// Official Google Test Native Advanced Ad Unit IDs
  static const String _androidTestNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';
  static const String _iosTestNativeAdUnitId = 'ca-app-pub-3940256099942544/3986624511';

  /// Real Ad Unit IDs loaded from .env
  static String get _androidProdBannerAdUnitId =>
      dotenv.env['ADMOB_ANDROID_BANNER_AD_UNIT_ID'] ?? 'ca-app-pub-4560112883494699/5781222514';

  static String get _iosProdBannerAdUnitId =>
      dotenv.env['ADMOB_IOS_BANNER_AD_UNIT_ID'] ?? _iosTestBannerAdUnitId;

  static String get _androidProdAppOpenAdUnitId =>
      dotenv.env['ADMOB_ANDROID_APP_OPEN_AD_UNIT_ID'] ?? 'ca-app-pub-4560112883494699/8464326256';

  static String get _iosProdAppOpenAdUnitId =>
      dotenv.env['ADMOB_IOS_APP_OPEN_AD_UNIT_ID'] ?? _iosTestAppOpenAdUnitId;

  static String get _androidProdNativeAdUnitId =>
      dotenv.env['ADMOB_ANDROID_NATIVE_AD_UNIT_ID'] ?? 'ca-app-pub-4560112883494699/8935099544';

  static String get _iosProdNativeAdUnitId =>
      dotenv.env['ADMOB_IOS_NATIVE_AD_UNIT_ID'] ?? _iosTestNativeAdUnitId;

  /// Returns the appropriate Banner Ad Unit ID
  static String get bannerAdUnitId {
    if (useTestAds) {
      if (Platform.isAndroid) return _androidTestBannerAdUnitId;
      if (Platform.isIOS) return _iosTestBannerAdUnitId;
    } else {
      if (Platform.isAndroid) return _androidProdBannerAdUnitId;
      if (Platform.isIOS) return _iosProdBannerAdUnitId;
    }
    return _androidTestBannerAdUnitId;
  }

  /// Returns the appropriate Interstitial Ad Unit ID
  static String get interstitialAdUnitId {
    if (useTestAds) {
      if (Platform.isAndroid) return _androidTestInterstitialAdUnitId;
      if (Platform.isIOS) return _iosTestInterstitialAdUnitId;
    } else {
      if (Platform.isAndroid) {
        return dotenv.env['ADMOB_ANDROID_INTERSTITIAL_AD_UNIT_ID'] ?? _androidTestInterstitialAdUnitId;
      }
      if (Platform.isIOS) {
        return dotenv.env['ADMOB_IOS_INTERSTITIAL_AD_UNIT_ID'] ?? _iosTestInterstitialAdUnitId;
      }
    }
    return _androidTestInterstitialAdUnitId;
  }

  /// Returns the appropriate App Open Ad Unit ID
  static String get appOpenAdUnitId {
    if (useTestAds) {
      if (Platform.isAndroid) return _androidTestAppOpenAdUnitId;
      if (Platform.isIOS) return _iosTestAppOpenAdUnitId;
    } else {
      if (Platform.isAndroid) return _androidProdAppOpenAdUnitId;
      if (Platform.isIOS) return _iosProdAppOpenAdUnitId;
    }
    return _androidTestAppOpenAdUnitId;
  }

  /// Returns the appropriate Native Ad Unit ID
  static String get nativeAdUnitId {
    if (useTestAds) {
      if (Platform.isAndroid) return _androidTestNativeAdUnitId;
      if (Platform.isIOS) return _iosTestNativeAdUnitId;
    } else {
      if (Platform.isAndroid) return _androidProdNativeAdUnitId;
      if (Platform.isIOS) return _iosProdNativeAdUnitId;
    }
    return _androidTestNativeAdUnitId;
  }

  /// Initialize Mobile Ads SDK
  static Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      if (kDebugMode) {
        print("AdMob SDK successfully initialized.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to initialize AdMob SDK: $e");
      }
    }
  }
}
