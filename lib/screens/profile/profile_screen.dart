import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/three_d_tilt_card.dart';
import '../splash/splash_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'security_settings_screen.dart';
import 'terms_conditions_screen.dart';
import 'app_guide_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    final bgColor = isDark ? const Color(0xff0F172A) : const Color(0xffF4F6FB);
    final cardColor = isDark ? const Color(0xff1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xff2D3748);

    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        title: Text(
          "My Profile",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: authService.getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data?.data() ?? {};
          final fullName = user["fullName"] ?? "User";
          final email = user["email"] ?? "No Email";
          final phone = user["phone"] ?? "";
          final photoUrl = user["photoUrl"] ?? "";

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),

            child: Column(
              children: [
                // 3D Hero Profile Card
                ThreeDTiltCard(
                  maxTiltAngle: 0.12,
                  elevation: 14,
                  shadowColor: const Color(0xff1E3C72),
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xff1E3C72),
                          Color(0xff2A5298),
                          Color(0xff11998E),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Avatar with glowing ring
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Colors.amberAccent, Colors.tealAccent],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.tealAccent.withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.white,
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl.isEmpty
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 50,
                                    color: Color(0xff1E3C72),
                                  )
                                : null,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),

                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              phone,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 3D Menu List Items
                _build3DTile(
                  context,
                  icon: Icons.person_outline_rounded,
                  iconColor: const Color(0xff1E3C72),
                  title: "Edit Profile",
                  cardColor: cardColor,
                  textColor: textColor,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditProfileScreen(fullName: fullName, phone: phone),
                      ),
                    );

                    if (result == true) {
                      setState(() {});
                    }
                  },
                ),

                // Dark Mode Switch Tile
                ThreeDTiltCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  maxTiltAngle: 0.04,
                  elevation: 4,
                  shadowColor: isDark ? const Color(0xff38EF7D) : Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.indigo.withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.dark_mode_rounded,
                          color: Colors.indigoAccent,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        "Dark Mode",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      value: themeProvider.isDark,
                      activeColor: const Color(0xff38EF7D),
                      onChanged: (value) {
                        themeProvider.toggleTheme(value);
                      },
                    ),
                  ),
                ),

                _build3DTile(
                  context,
                  icon: Icons.lock_outline_rounded,
                  iconColor: const Color(0xffFF9800),
                  title: "Change Password",
                  cardColor: cardColor,
                  textColor: textColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),

                _build3DTile(
                  context,
                  icon: Icons.shield_rounded,
                  iconColor: const Color(0xff11998E),
                  title: "Security & App Lock",
                  cardColor: cardColor,
                  textColor: textColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SecuritySettingsScreen(),
                      ),
                    );
                  },
                ),

                _build3DTile(
                  context,
                  icon: Icons.notifications_none_rounded,
                  iconColor: const Color(0xff00BCD4),
                  title: "Notifications",
                  cardColor: cardColor,
                  textColor: textColor,
                  onTap: () => _showNotificationsDialog(context),
                ),

                _build3DTile(
                  context,
                  icon: Icons.menu_book_rounded,
                  iconColor: const Color(0xff00BCD4),
                  title: "How to Use App",
                  cardColor: cardColor,
                  textColor: textColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppGuideScreen(),
                      ),
                    );
                  },
                ),

                _build3DTile(
                  context,
                  icon: Icons.gavel_rounded,
                  iconColor: const Color(0xff11998E),
                  title: "Terms & Conditions",
                  cardColor: cardColor,
                  textColor: textColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsConditionsScreen(),
                      ),
                    );
                  },
                ),

                _build3DTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  iconColor: const Color(0xff4CAF50),
                  title: "Privacy Policy",
                  cardColor: cardColor,
                  textColor: textColor,
                  onTap: () => _showPrivacyPolicyDialog(context),
                ),

                _build3DTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xff9C27B0),
                  title: "About App",
                  cardColor: cardColor,
                  textColor: textColor,
                  onTap: () => _showAboutAppDialog(context),
                ),

                const SizedBox(height: 8),

                _build3DTile(
                  context,
                  icon: Icons.logout_rounded,
                  iconColor: Colors.redAccent,
                  title: "Logout",
                  cardColor: cardColor,
                  textColor: Colors.redAccent,
                  onTap: () async {
                    await authService.logout();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const SplashScreen()),
                      (route) => false,
                    );
                  },
                ),

                _build3DTile(
                  context,
                  icon: Icons.delete_forever_rounded,
                  iconColor: Colors.red.shade700,
                  title: "Delete Account",
                  cardColor: cardColor,
                  textColor: Colors.red.shade700,
                  onTap: () {
                    _showDeleteDialog(context);
                  },
                ),

                const SizedBox(height: 20),

                Text(
                  "Version 1.0.6",
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _build3DTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color cardColor,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return ThreeDTiltCard(
      margin: const EdgeInsets.only(bottom: 12),
      maxTiltAngle: 0.04,
      elevation: 4,
      shadowColor: iconColor,
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.security_rounded, color: Color(0xff4CAF50)),
              SizedBox(width: 10),
              Text(
                "Privacy Policy",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "🛡️ Data Privacy & Protection",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  "Your financial data is encrypted and securely stored using Google Firebase Cloud Services. We do not sell, share, or track your personal financial transactions with third-party advertisers.",
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                SizedBox(height: 14),
                Text(
                  "🔐 Authentication Safety",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  "Passwords are salted and hashed securely by Firebase Authentication. You have full control to edit your profile or delete your account at any time.",
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4CAF50),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("I Understand"),
            ),
          ],
        );
      },
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: Color(0xff1E3C72)),
              SizedBox(width: 10),
              Text(
                "About App",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Expense Tracker",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff1E3C72),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Version 1.0.6",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "✨ Key Features:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 8),
                Text("• Interactive 3D Perspective Credit Card & Balance Tile"),
                Text("• Real-time Income & Expense Categorization"),
                Text("• Category Breakdown Pie Charts & Statistics"),
                Text("• Date Range Filtered Search & History Log"),
                Text("• Executive Dark Mode & Light Mode Theme Support"),
                SizedBox(height: 14),
                Text(
                  "🛠️ Technology:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 6),
                Text("Built with Flutter 3, Material 3, Firebase & Provider."),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1E3C72),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isDailyEnabled = true;
        TimeOfDay reminderTime = const TimeOfDay(hour: 20, minute: 0);
        bool isBudgetAlertEnabled = true;
        bool isLoaded = false;

        return StatefulBuilder(
          builder: (context, setStateModal) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetBg = isDark ? const Color(0xff1E293B) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xff1E293B);
            final cardBg = isDark
                ? const Color(0xff0F172A)
                : const Color(0xffF1F5F9);
            final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

            if (!isLoaded) {
              Future.microtask(() async {
                final daily = await NotificationService().getIsDailyReminderEnabled();
                final time = await NotificationService().getDailyReminderTime();
                final budget = await NotificationService().getIsBudgetAlertEnabled();
                if (ctx.mounted) {
                  setStateModal(() {
                    isDailyEnabled = daily;
                    reminderTime = time;
                    isBudgetAlertEnabled = budget;
                    isLoaded = true;
                  });
                }
              });
            }

            String formatTime(TimeOfDay time) {
              final now = DateTime.now();
              final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
              return TimeOfDay.fromDateTime(dt).format(context);
            }

            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xff00BCD4), Color(0xff00838F)],
                          ),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Notification Settings",
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            Text(
                              "Manage reminders & budget alerts",
                              style: TextStyle(
                                fontSize: 13,
                                color: subTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: subTextColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (!isLoaded)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xff00BCD4)),
                      ),
                    )
                  else ...[
                    // 1. Daily Reminder Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xff00BCD4).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.alarm_rounded,
                                  color: Color(0xff00BCD4),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Daily Expense Reminder",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Get daily notification to record spending",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: subTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isDailyEnabled,
                                activeColor: const Color(0xff00BCD4),
                                onChanged: (val) async {
                                  setStateModal(() => isDailyEnabled = val);
                                  await NotificationService().setDailyReminderEnabled(val);
                                },
                              ),
                            ],
                          ),

                          // Time Picker Row (Visible if Daily Reminder is Enabled)
                          if (isDailyEnabled) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_filled_rounded,
                                      size: 18,
                                      color: subTextColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Reminder Time",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      final pickedTime = await showTimePicker(
                                        context: context,
                                        initialTime: reminderTime,
                                      );
                                      if (pickedTime != null) {
                                        setStateModal(() => reminderTime = pickedTime);
                                        await NotificationService().setDailyReminderTime(pickedTime);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Reminder scheduled for ${formatTime(pickedTime)} daily! ⏰",
                                              ),
                                              backgroundColor: const Color(0xff00BCD4),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xff00BCD4).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xff00BCD4).withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            formatTime(reminderTime),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xff00BCD4),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.edit_outlined,
                                            size: 14,
                                            color: Color(0xff00BCD4),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. Budget Alert Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xffFF9800).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xffFF9800),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Budget Health Alerts",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Notify when spending exceeds 80% or 100%",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isBudgetAlertEnabled,
                            activeColor: const Color(0xffFF9800),
                            onChanged: (val) async {
                              setStateModal(() => isBudgetAlertEnabled = val);
                              await NotificationService().setBudgetAlertEnabled(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text("Delete Account"),
            ],
          ),
          content: const Text(
            "Are you sure you want to delete your account?\n\nAll your expense data will be permanently removed. This action cannot be undone.",
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await deleteAccount();
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uid = user.uid;

      // Delete user document in Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .delete();

      // Delete Firebase Auth User
      await user.delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'requires-recent-login') {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          _showReauthenticateDialog(currentUser);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "Failed to delete account"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReauthenticateDialog(User user) {
    final passwordController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (builderCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text("Confirm Password"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "For security reasons, please enter your password to confirm account deletion.",
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Current Password",
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final pass = passwordController.text.trim();
                          if (pass.isEmpty) return;

                          setDialogState(() => isSubmitting = true);

                          try {
                            final credential = EmailAuthProvider.credential(
                              email: user.email!,
                              password: pass,
                            );

                            await user.reauthenticateWithCredential(credential);

                            final uid = user.uid;

                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(uid)
                                .delete();

                            if (!dialogCtx.mounted || !mounted) return;

                            Navigator.pop(dialogCtx);

                            ScaffoldMessenger.of(context).showSnackBar(


                              const SnackBar(
                                content: Text("Account deleted successfully"),
                                backgroundColor: Colors.green,
                              ),
                            );

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const SplashScreen()),
                              (route) => false,
                            );
                          } on FirebaseAuthException catch (err) {
                            setDialogState(() => isSubmitting = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err.message ?? "Incorrect password"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } catch (err) {
                            setDialogState(() => isSubmitting = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: $err"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Confirm Delete"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}



