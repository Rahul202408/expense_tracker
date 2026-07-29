import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_service.dart';

class AppOpenAdManager with WidgetsBindingObserver {
  static final AppOpenAdManager _instance = AppOpenAdManager._internal();
  factory AppOpenAdManager() => _instance;
  AppOpenAdManager._internal();

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _appOpenLoadTime;

  /// Maximum duration allowed for an App Open Ad before it's considered expired (4 hours)
  static const Duration maxCacheDuration = Duration(hours: 4);

  /// Initialize observer and load initial ad
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    loadAd();
  }

  /// Load an AppOpenAd
  void loadAd() {
    if (isAdAvailable) return;

    AppOpenAd.load(
      adUnitId: AdService.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          if (kDebugMode) {
            print('AppOpenAd loaded successfully.');
          }
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            print('AppOpenAd failed to load: $error');
          }
          _appOpenAd = null;
        },
      ),
    );
  }

  /// Check if ad is available and not expired
  bool get isAdAvailable {
    if (_appOpenAd == null || _appOpenLoadTime == null) return false;
    return DateTime.now().difference(_appOpenLoadTime!) < maxCacheDuration;
  }

  /// Show ad if available
  void showAdIfAvailable() {
    if (!isAdAvailable) {
      if (kDebugMode) {
        print('AppOpenAd is not available yet. Loading new ad.');
      }
      loadAd();
      return;
    }

    if (_isShowingAd) {
      if (kDebugMode) {
        print('AppOpenAd is already showing.');
      }
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    _appOpenAd!.show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      showAdIfAvailable();
    }
  }

  /// Clean up resources
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appOpenAd?.dispose();
  }
}
