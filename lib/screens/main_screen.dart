import 'package:flutter/material.dart';

import 'home/home_screen.dart';
import 'analytics/analytics_screen.dart';
import 'history/history_screen.dart';
import 'profile/profile_screen.dart';
import 'home/widgets/custom_bottom_nav.dart';
import '../services/auth_service.dart';
import '../services/app_prompt_service.dart';
import '../services/app_open_ad_manager.dart';
import '../services/app_update_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onNavigateTab: _onTabSelect),
      const AnalyticsScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];
    AppOpenAdManager().setAdSuppressed(false);
    AuthService().updateLastActiveTime();
    _initLaunchPrompts();
  }

  void _initLaunchPrompts() {
    // Allow dashboard UI to render smoothly before checking and triggering contextual prompts
    Future.delayed(const Duration(milliseconds: 1400), () async {
      if (mounted) {
        // High priority: Check if new version is released on Google Play Store
        await AppUpdateService().checkForUpdate(context);
        if (mounted) {
          AppPromptService().checkAndTriggerPrompts(context);
        }
      }
    });
  }

  void _onTabSelect(int index) {
    if (currentIndex != index) {
      setState(() {
        currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: currentIndex,
        onTap: _onTabSelect,
      ),
    );
  }
}
