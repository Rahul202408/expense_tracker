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
  await AuthService.initCachedSession();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("dotenv load note: $e");
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseAnalyticsService().logAppOpen();

  // Initialize ads & notifications in parallel without blocking initial UI frame
  AdService.initialize().then((_) {
    AppOpenAdManager().initialize();
  });
  NotificationService().init();

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