import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/app_update_dialog.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  /// Current Installed App Version
  static const int currentBuildNumber = 35;
  static const String currentVersionName = "1.3.5";

  static const String _prefKeyLastDismissedUpdate = "update_prompt_last_dismissed_ms";
  static const String _prefKeyDismissedVersionCode = "update_prompt_dismissed_version_code";

  // Minimum interval between repeated "Later" prompts (24 hours)
  static const Duration _promptCooldown = Duration(hours: 24);

  /// Check if a newer version is released on Google Play Store via Firestore app_config
  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('version_info')
          .get()
          .timeout(
            const Duration(seconds: 4),
            onTimeout: () => throw Exception("Timeout fetching update info"),
          );

      if (!doc.exists || doc.data() == null) {
        return;
      }

      final data = doc.data()!;
      final int latestVersionCode = (data['latest_version_code'] as num?)?.toInt() ?? currentBuildNumber;
      final String latestVersionName = (data['latest_version_name'] as String?) ?? currentVersionName;
      final String releaseNotes = (data['release_notes'] as String?) ??
          "Exciting new features, improved charts & animations, and performance upgrades are now ready for you.";
      final bool isForceUpdate = (data['is_force_update'] as bool?) ?? false;

      // Check if update is actually newer than current installed version
      if (latestVersionCode <= currentBuildNumber) {
        return;
      }

      // If not forced, check if user clicked "Later" recently
      if (!isForceUpdate) {
        final prefs = await SharedPreferences.getInstance();
        final lastDismissedMs = prefs.getInt(_prefKeyLastDismissedUpdate) ?? 0;
        final dismissedCode = prefs.getInt(_prefKeyDismissedVersionCode) ?? 0;

        final timeSinceDismissed = DateTime.now().millisecondsSinceEpoch - lastDismissedMs;
        // Suppress if dismissed for the same version within the cooldown period
        if (dismissedCode == latestVersionCode && timeSinceDismissed < _promptCooldown.inMilliseconds) {
          return;
        }
      }

      if (!context.mounted) return;

      // Present the Frosted Glassmorphism Update Dialog
      await showDialog(
        context: context,
        barrierDismissible: !isForceUpdate,
        builder: (dialogCtx) => AppUpdateDialog(
          latestVersion: latestVersionName,
          currentVersion: currentVersionName,
          releaseNotes: releaseNotes,
          isForceUpdate: isForceUpdate,
          onLater: () async {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt(_prefKeyLastDismissedUpdate, DateTime.now().millisecondsSinceEpoch);
              await prefs.setInt(_prefKeyDismissedVersionCode, latestVersionCode);
            } catch (_) {}
          },
        ),
      );
    } catch (_) {
      // Gracefully ignore if offline or unconfigured
    }
  }
}
