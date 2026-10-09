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

  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _footerOpacityAnimation;
  late Animation<double> _progressAnimation;
  late Future<User?> _authRestoreFuture;
  Timer? _splashTimer;
  Timer? _fallbackTimer;
  bool _hasNavigated = false;

  Future<User?> _resolveInitialUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) return user;

      return await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((u) => u != null)
          .timeout(
            const Duration(milliseconds: 3000),
            onTimeout: () {
              try {
                return FirebaseAuth.instance.currentUser;
              } catch (_) {
                return null;
              }
            },
          );
    } catch (_) {
      try {
        return FirebaseAuth.instance.currentUser;
      } catch (_) {
        return null;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    try {
      AppOpenAdManager().setAdSuppressed(true);
    } catch (_) {}
    _authRestoreFuture = _resolveInitialUser();

    // Main entrance animation controller - full 5.0 seconds duration for seamless data loading
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    // Continuous subtle pulsing glow controller for the logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Premium Logo Entrance: Drops smoothly from Top to Center with gentle spring bounce
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.36, curve: Curves.easeOutBack),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.36, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.24, curve: Curves.easeIn),
      ),
    );

    // Title and Tagline entrance (slides up and fades in after logo lands)
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.38),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.28, 0.54, curve: Curves.easeOutCubic),
      ),
    );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.28, 0.50, curve: Curves.easeIn),
      ),
    );

    // Progress bar fill animation across the full 5-second duration
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.12, 0.96, curve: Curves.easeInOutCubic),
      ),
    );

    // Footer entrance
    _footerOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.60, 0.92, curve: Curves.easeIn),
      ),
    );

    _mainController.forward();

    // Allow full 5050ms for animations and parallel Firebase Auth restoration
    _splashTimer = Timer(const Duration(milliseconds: 5050), checkFirstLaunch);

    // Bulletproof fallback timer to ensure user NEVER gets stuck on splash screen
    _fallbackTimer = Timer(const Duration(milliseconds: 6200), () {
      if (!_hasNavigated && mounted) {
        checkFirstLaunch();
      }
    });
  }

  Future<void> checkFirstLaunch() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    try {
      // 1. Register launch for contextual prompts safely with timeout
      try {
        await AppPromptService().registerLaunch().timeout(const Duration(seconds: 1));
      } catch (e) {
        debugPrint("Splash registerLaunch note: $e");
      }

      // 2. Read local state safely with timeout
      SharedPreferences? prefs;
      try {
        prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
      } catch (_) {}

      final authService = AuthService();

      // 3. Resolve user auth with timeout
      User? user;
      try {
        user = await _authRestoreFuture.timeout(const Duration(seconds: 3));
      } catch (_) {}
      try {
        user ??= FirebaseAuth.instance.currentUser;
      } catch (_) {}

      // If user is null, attempt silent Google sign-in restoration
      if (user == null) {
        try {
          user = await authService.trySilentGoogleSignIn().timeout(const Duration(seconds: 2));
        } catch (_) {}
      }
      try {
        user ??= FirebaseAuth.instance.currentUser;
      } catch (_) {}

      // 4. Session verification: strictly requires a non-null authenticated Firebase user
      final bool hasValidSession = user != null;

      // Clean up any stale ghost login flags so state is 100% consistent
      if (!hasValidSession) {
        try {
          await prefs?.setBool("is_user_logged_in", false);
          await prefs?.remove("logged_user_uid");
        } catch (_) {}
      }

      if (!mounted) return;

      // 5. Navigate to Home or Lock screen if session is valid
      if (hasValidSession) {
        try {
          await authService.recordUserLoginSession(user);
          await authService.updateLastActiveTime();
        } catch (_) {}

        bool isLockEnabled = false;
        try {
          isLockEnabled = await SecurityService().isAppLockEnabled().timeout(const Duration(seconds: 1));
        } catch (_) {}

        if (!mounted) return;

        if (isLockEnabled) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AppLockScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
        return;
      }

      if (!mounted) return;

      // 6. First-time users see Onboarding, returning users go directly to LoginScreen
      final bool seen = prefs?.getBool("onboarding") ?? false;
      if (!seen) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint("Splash checkFirstLaunch safety fallback: $e");
      if (!mounted) return;
      // Fail-safe navigation: directly take user to LoginScreen so they are never stuck
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _fallbackTimer?.cancel();
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

                  // Center animated App Brand Area with Top-to-Center slide
                  Center(
                    child: SlideTransition(
                      position: _logoSlideAnimation,
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
                  ),

                  const SizedBox(height: 30),

                  // Title & Tagline with slide + fade
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: FadeTransition(
                      opacity: _textOpacityAnimation,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Expense Tracker",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : const Color(0xff1A202C),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Glassmorphism Tagline Badge
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Container(
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Sleek Modern Gradient Loading Progress Bar with Dynamic Status
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, _) {
                      final progress = _progressAnimation.value;
                      String statusText;
                      IconData statusIcon;

                      if (progress < 0.38) {
                        statusText = "Securing your vault...";
                        statusIcon = Icons.lock_outline_rounded;
                      } else if (progress < 0.76) {
                        statusText = "Synchronizing insights...";
                        statusIcon = Icons.sync_rounded;
                      } else {
                        statusText = "Ready to manage smartly!";
                        statusIcon = Icons.check_circle_outline_rounded;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 72),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  statusIcon,
                                  size: 13,
                                  color: const Color(0xff10B981).withValues(alpha: 0.9),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : const Color(0xff64748B),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Container(
                              height: 4.5,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress.clamp(0.04, 1.0),
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
                                        color: const Color(0xff10B981).withValues(alpha: 0.65),
                                        blurRadius: 8,
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
                            "Version 1.3.5",
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
