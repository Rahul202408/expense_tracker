import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_service.dart';
import 'app_prompt_service.dart';
import 'in_app_purchase_service.dart';

class AppOpenAdManager with WidgetsBindingObserver {
  static final AppOpenAdManager _instance = AppOpenAdManager._internal();
  factory AppOpenAdManager() => _instance;
  AppOpenAdManager._internal();

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _appOpenLoadTime;
  bool _isProUser = false;

  /// Timestamp when app was paused / sent to background
  DateTime? _appPausedTime;

  /// Timestamp when the last App Open Ad was dismissed or failed
  DateTime? _lastAdDismissedTime;

  /// Explicit flag to suppress ads during sensitive flows (e.g. login, signup, onboarding, lock screen)
  bool _isAdSuppressed = false;

  /// Minimum duration the app must stay in the background before showing an App Open Ad on resume.
  /// (30 seconds) - This completely prevents ads from appearing when a user simply pulls down
  /// the phone's notification shutter (sater) or opens a brief system dialog (Google Sign-In, permissions).
  static const Duration minBackgroundDuration = Duration(seconds: 30);

  /// Cooldown between App Open Ads (4 minutes) to avoid overwhelming returning users.
  static const Duration minAdInterval = Duration(minutes: 4);

  /// Maximum duration allowed for an App Open Ad before it's considered expired (4 hours)
  static const Duration maxCacheDuration = Duration(hours: 4);

  /// Initialize observer and load initial ad
  void initialize() async {
    WidgetsBinding.instance.addObserver(this);
    _isProUser = await InAppPurchaseService().getIsPro();
    if (!_isProUser) {
      loadAd();
    }
  }

  /// Explicitly control ad suppression (e.g. on Auth or Onboarding screens)
  void setAdSuppressed(bool suppressed) {
    _isAdSuppressed = suppressed;
    if (kDebugMode) {
      print('AppOpenAdManager: Ad suppression set to $suppressed');
    }
  }

  void updateProStatus(bool isPro) {
    _isProUser = isPro;
    if (isPro && _appOpenAd != null) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
    }
  }

  /// Load an AppOpenAd
  void loadAd() async {
    _isProUser = await InAppPurchaseService().getIsPro();
    if (_isProUser || isAdAvailable) return;

    // Check if user is a first-time user (Launch 1)
    try {
      final prefs = await SharedPreferences.getInstance();
      final launchCount = prefs.getInt(AppPromptService.keyLaunchCount) ?? 0;
      if (launchCount <= 1) {
        if (kDebugMode) {
          print(
            'AppOpenAdManager: Skipping ad load for first-time user (launch count: $launchCount).',
          );
        }
        return;
      }
    } catch (_) {}

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
    if (_isProUser || _appOpenAd == null || _appOpenLoadTime == null) return false;
    return DateTime.now().difference(_appOpenLoadTime!) < maxCacheDuration;
  }

  /// Check whether ad should be suppressed
  Future<bool> _shouldSuppressAd() async {
    // 1. Pro users never see ads
    _isProUser = await InAppPurchaseService().getIsPro();
    if (_isProUser) return true;

    // 2. Explicit screen suppression active (e.g. on Login, Signup, Onboarding screens)
    if (_isAdSuppressed) {
      if (kDebugMode) {
        print('AppOpenAdManager: Ad explicitly suppressed for current flow.');
      }
      return true;
    }

    // 3. User is not authenticated
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        print('AppOpenAdManager: User not logged in, suppressing App Open Ad.');
      }
      return true;
    }

    // 4. First-time user rule: No ads on Launch 1 or before first session is complete
    try {
      final prefs = await SharedPreferences.getInstance();
      final launchCount = prefs.getInt(AppPromptService.keyLaunchCount) ?? 0;
      if (launchCount <= 1) {
        if (kDebugMode) {
          print(
            'AppOpenAdManager: First-time user (launch $launchCount), suppressing App Open Ad.',
          );
        }
        return true;
      }
    } catch (_) {}

    // 5. Cooldown interval check
    if (_lastAdDismissedTime != null) {
      final elapsed = DateTime.now().difference(_lastAdDismissedTime!);
      if (elapsed < minAdInterval) {
        if (kDebugMode) {
          print(
            'AppOpenAdManager: In ad cooldown (${elapsed.inSeconds}s < ${minAdInterval.inSeconds}s). Skipping ad.',
          );
        }
        return true;
      }
    }

    return false;
  }

  /// Show ad if available
  void showAdIfAvailable() async {
    final shouldSuppress = await _shouldSuppressAd();
    if (shouldSuppress) return;

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
        _lastAdDismissedTime = DateTime.now();
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        _lastAdDismissedTime = DateTime.now();
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    _appOpenAd!.show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _appPausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final pausedTime = _appPausedTime;
      _appPausedTime = null;

      // Check how long the app was paused in the background
      if (pausedTime != null) {
        final timeInBackground = DateTime.now().difference(pausedTime);
        if (timeInBackground < minBackgroundDuration) {
          if (kDebugMode) {
            print(
              'AppOpenAdManager: App was in background for ${timeInBackground.inSeconds}s (< ${minBackgroundDuration.inSeconds}s). Shutter / brief interruption ignored.',
            );
          }
          return;
        }
      }

      showAdIfAvailable();
    }
  }

  /// Clean up resources
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appOpenAd?.dispose();
  }
}
