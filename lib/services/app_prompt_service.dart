import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/pro_provider.dart';
import '../screens/pro/pro_screen.dart';
import '../widgets/google_review_dialog.dart';

/// AppPromptService manages smart contextual prompts:
/// 1. Launch 1: User explores the app (no popups).
/// 2. Launch 2: Full-screen PRO screen with top-left X button (only if not Pro).
/// 3. Launch 3: Beautiful Google Review pop-up dialog.
/// 4. Launch 4: Regular experience (no review dialog).
/// 5. Launch 5: If user didn't review on Launch 3, show Google Review dialog again.
/// 6. Once user submits a review, never show the review prompt again.
class AppPromptService {
  static final AppPromptService _instance = AppPromptService._internal();
  factory AppPromptService() => _instance;
  AppPromptService._internal();

  static const String keyLaunchCount = 'app_launch_count';
  static const String keyHasRated = 'has_rated_app';
  static const String keyProPaywallShownLaunch2 = 'pro_paywall_shown_launch_2';

  static const String playStoreWebUrl =
      'https://play.google.com/store/apps/details?id=com.trtech.expense_tracker';
  static const String playStoreMarketUri =
      'market://details?id=com.trtech.expense_tracker';

  /// Register app launch and increment launch counter
  Future<int> registerLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(keyLaunchCount) ?? 0) + 1;
    await prefs.setInt(keyLaunchCount, count);
    debugPrint("AppPromptService: App launch count is now $count");
    return count;
  }

  /// Get current launch count
  Future<int> getLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyLaunchCount) ?? 0;
  }

  /// Check if user has already given a rating / review
  Future<bool> hasRated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyHasRated) ?? false;
  }

  /// Mark app as rated
  Future<void> setRated(bool rated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyHasRated, rated);
    debugPrint("AppPromptService: has_rated_app set to $rated");
  }

  /// Open Google Play Store for rating
  Future<bool> openPlayStore() async {
    await setRated(true);

    final Uri marketUri = Uri.parse(playStoreMarketUri);
    final Uri webUri = Uri.parse(playStoreWebUrl);

    try {
      if (await canLaunchUrl(marketUri)) {
        return await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("AppPromptService: Error launching play store URL: $e");
    }
    return false;
  }

  /// Check launch conditions and trigger appropriate prompt in MainScreen
  Future<void> checkAndTriggerPrompts(BuildContext context) async {
    if (!context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return;

    final launchCount = prefs.getInt(keyLaunchCount) ?? 0;
    final hasRatedApp = prefs.getBool(keyHasRated) ?? false;

    // Check if user is already a PRO member
    final proProvider = Provider.of<ProProvider>(context, listen: false);
    final isPro = proProvider.isPro;

    debugPrint(
      "AppPromptService: Evaluating prompts -> Launch: $launchCount, isPro: $isPro, hasRated: $hasRatedApp",
    );

    // RULE 1: First time app open (Launch 1) -> Let user explore the app.
    if (launchCount <= 1) {
      return;
    }

    // RULE 2: Second time app open (Launch 2) -> Full-screen Pro screen with top-left X button
    if (launchCount == 2 && !isPro) {
      final alreadyShown = prefs.getBool(keyProPaywallShownLaunch2) ?? false;
      if (!alreadyShown) {
        await prefs.setBool(keyProPaywallShownLaunch2, true);
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const ProScreen(),
          ),
        );
        return;
      }
    }

    // RULE 3 & 4: Third time (Launch 3) or Fifth time (Launch 5) -> Google Review Pop-up dialog
    // If user has already reviewed, never show it again.
    if ((launchCount == 3 || launchCount == 5) && !hasRatedApp) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => const GoogleReviewDialog(),
        );
      }
    }
  }
}
