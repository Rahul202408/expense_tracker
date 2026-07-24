import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';

import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';

// import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
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

      title: "Expense Tracker",

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      themeMode: themeProvider.themeMode,

      home: const SplashScreen(),
    );
  }
}
