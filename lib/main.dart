import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/connectivity_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/app_open_ad_manager.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/firebase_analytics_service.dart';
import 'providers/pro_provider.dart';
import 'widgets/no_internet_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase FIRST before anything else
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      debugPrint("Firebase default app already initialized");
    } else {
      debugPrint("Firebase init FirebaseException: $e");
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }
      } catch (e2) {
        debugPrint("Firebase fallback init note: $e2");
      }
    }
  } catch (e) {
    debugPrint("Firebase init generic note: $e");
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e2) {
      debugPrint("Firebase fallback init note: $e2");
    }
  }

  // 2. Load .env environment variables safely
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("dotenv load note: $e");
  }

  // 3. Initialize local session cache safely
  try {
    await AuthService.initCachedSession();
  } catch (e) {
    debugPrint("AuthService initCachedSession note: $e");
  }

  // 4. Safely log app open
  try {
    FirebaseAnalyticsService().logAppOpen();
  } catch (e) {
    debugPrint("Analytics logAppOpen note: $e");
  }

  // 5. Initialize ads & notifications in parallel without blocking initial UI frame
  try {
    AdService.initialize().then((_) {
      AppOpenAdManager().initialize();
    }).catchError((e) {
      debugPrint("AdService init note: $e");
    });
  } catch (e) {
    debugPrint("AdService launch note: $e");
  }

  try {
    NotificationService().init().catchError((e) {
      debugPrint("NotificationService init note: $e");
    });
  } catch (e) {
    debugPrint("NotificationService launch note: $e");
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint("FlutterError caught: ${details.exceptionAsString()}");
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xff0F172A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xff10B981), size: 48),
              const SizedBox(height: 12),
              const Text(
                "Expense Tracker",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // 6. Guarantee runApp always executes to display Flutter UI
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => ProProvider()),
      ],
      child: const ExpenseTrackerApp(),
    ),
  );
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Expense Tracker: Money Manager",
      navigatorObservers: [FirebaseAnalyticsService().observer],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      builder: (context, child) {
        return NoInternetBannerWrapper(child: child ?? const SizedBox.shrink());
      },
      home: const SplashScreen(),
    );
  }
}