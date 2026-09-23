import 'package:flutter/material.dart';

import 'home/home_screen.dart';
import 'analytics/analytics_screen.dart';
import 'history/history_screen.dart';
import 'profile/profile_screen.dart';
import 'home/widgets/custom_bottom_nav.dart';
import '../services/auth_service.dart';
import '../services/app_prompt_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    AuthService().updateLastActiveTime();
    _initLaunchPrompts();
  }

  void _initLaunchPrompts() async {
    await AppPromptService().registerLaunch();
    // Allow dashboard UI to render smoothly before checking and triggering contextual prompts
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        AppPromptService().checkAndTriggerPrompts(context);
      }
    });
  }

  void _onTabSelect(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateTab: _onTabSelect),
      const AnalyticsScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(currentIndex),
          child: screens[currentIndex],
        ),
      ),

      bottomNavigationBar: CustomBottomNav(
        currentIndex: currentIndex,
        onTap: _onTabSelect,
      ),
    );
  }
}
