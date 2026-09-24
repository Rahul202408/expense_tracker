import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/app_logo.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/login_screen.dart';
import '../main_screen.dart';
import '../../services/auth_service.dart';
import '../../services/security_service.dart';
import '../../services/app_open_ad_manager.dart';
import '../../services/app_prompt_service.dart';
import '../auth/app_lock_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _footerOpacityAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    AppOpenAdManager().setAdSuppressed(true);

    // Main entrance animation controller
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Continuous subtle pulsing glow controller for the logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Logo entrance animation
    _logoScaleAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    // Title and Tagline entrance
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.80, curve: Curves.easeIn),
      ),
    );

    // Progress bar fill animation
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.20, 0.95, curve: Curves.easeInOut),
      ),
    );

    // Footer entrance
    _footerOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.60, 1.0, curve: Curves.easeIn),
      ),
    );

    _mainController.forward();

    Timer(const Duration(milliseconds: 2500), checkFirstLaunch);
  }

  Future<void> checkFirstLaunch() async {
    // Register app cold launch count for contextual prompts and ad gating
    await AppPromptService().registerLaunch();

    final prefs = await SharedPreferences.getInstance();
    bool seen = prefs.getBool("onboarding") ?? false;

    // Check if 30-day session is active and valid
    final authService = AuthService();
    final bool sessionValid = await authService.isSessionValid();

    if (!mounted) return;

    // Only show onboarding if user has never seen it AND does not have an active login session
    if (!seen && !sessionValid) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
      return;
    }

    // Attempt to get currentUser. If null and session is recorded, allow Firebase a moment to restore token
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null && sessionValid) {
      try {
        user = await FirebaseAuth.instance
            .authStateChanges()
            .firstWhere((u) => u != null)
            .timeout(const Duration(milliseconds: 1200));
      } catch (_) {
        user = FirebaseAuth.instance.currentUser;
      }
    }

    if (!mounted) return;

    if (user != null && sessionValid) {
      // User is authenticated and within 30-day active window
      await authService.updateLastActiveTime();

      final isLockEnabled = await SecurityService().isAppLockEnabled();

      if (!mounted) return;

      if (isLockEnabled) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AppLockScreen(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainScreen(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } else {
      // Either not logged in or inactive for 30+ days (1 month)
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xff080E1E),
                    const Color(0xff0B1329),
                    const Color(0xff0F172A),
                  ]
                : [
                    const Color(0xffF8FAFC),
                    const Color(0xffEEF2F6),
                    const Color(0xffE2E8F0),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glowing gradient orbs
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff10B981).withValues(alpha: isDark ? 0.16 : 0.12),
                ),
              ),
            ),
            Positioned(
              top: 200,
              left: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff3B82F6).withValues(alpha: isDark ? 0.14 : 0.10),
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xffF59E0B).withValues(alpha: isDark ? 0.10 : 0.08),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Center animated App Brand Area
                  Center(
                    child: FadeTransition(
                      opacity: _logoOpacityAnimation,
                      child: ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final pulseVal = _pulseController.value;
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xff10B981)
                                        .withValues(alpha: 0.25 + (pulseVal * 0.20)),
                                    blurRadius: 40 + (pulseVal * 20),
                                    spreadRadius: 4 + (pulseVal * 6),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xff3B82F6)
                                        .withValues(alpha: 0.20 + (pulseVal * 0.15)),
                                    blurRadius: 30 + (pulseVal * 15),
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: child,
                            );
                          },
                          child: const AppLogo(size: 135),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Title & Tagline with slide + fade
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: FadeTransition(
                      opacity: _textOpacityAnimation,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Expense Tracker",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xff1A202C),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xffF59E0B), Color(0xffD97706)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "PRO",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Glassmorphism Tagline Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xff1E293B).withValues(alpha: 0.7)
                                  : Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xff10B981).withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xff10B981),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Track • Save • Grow Smartly",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff10B981),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Sleek Modern Gradient Loading Progress Bar
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, _) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 80),
                        child: Column(
                          children: [
                            Container(
                              height: 4,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _progressAnimation.value.clamp(0.05, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xff11998E),
                                        Color(0xff38EF7D),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xff10B981).withValues(alpha: 0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Studio & Version Footer
                  FadeTransition(
                    opacity: _footerOpacityAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: Color(0xff10B981),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Created By TR Tech Solutions",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.65)
                                      : const Color(0xff64748B),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Version 1.2.3",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.35)
                                  : const Color(0xff94A3B8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
