import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/payment_notification_service.dart';
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
  bool _isAutoDetectEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAutoDetectSetting();
  }

  Future<void> _loadAutoDetectSetting() async {
    final enabled = await PaymentNotificationService().isAutoDetectEnabled();
    if (mounted) {
      setState(() {
        _isAutoDetectEnabled = enabled;
      });
    }
  }

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
                        // Avatar
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

                // Edit Profile Tile
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

                // Auto-Detect Payments Switch Tile
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
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Color(0xFF10B981),
                          size: 22,
                        ),
                      ),
                      title: Text(
                        "Auto-Detect UPI Payments",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        "GPay, PhonePe, Paytm, BHIM & Bank alerts",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      value: _isAutoDetectEnabled,
                      activeColor: const Color(0xff38EF7D),
                      onChanged: (value) async {
                        setState(() {
                          _isAutoDetectEnabled = value;
                        });
                        await PaymentNotificationService().setAutoDetectEnabled(value);
                      },
                    ),
                  ),
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
                  iconColor: const Color(0xffE53935),
                  title: "Log Out",
                  cardColor: cardColor,
                  textColor: textColor,
                  onTap: () async {
                    await authService.logout();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const SplashScreen()),
                      (route) => false,
                    );
                  },
                ),

                const SizedBox(height: 12),

                TextButton.icon(
                  onPressed: () => _showDeleteDialog(context),
                  icon: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  label: const Text(
                    "Delete Account",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
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
    required VoidCallback onTap,
  }) {
    return ThreeDTiltCard(
      margin: const EdgeInsets.only(bottom: 12),
      maxTiltAngle: 0.04,
      elevation: 4,
      shadowColor: iconColor,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.1),
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: textColor.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Privacy Policy"),
        content: const SingleChildScrollView(
          child: Text(
            "Expense Tracker values your privacy. We collect minimal personal information necessary to manage your financial data securely.\n\nAll your expense data is stored securely using Google Firebase encryption. We never share or sell your personal or financial information to any third party.",
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("About Expense Tracker"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Version: "),
            const SizedBox(height: 8),
            const Text("Developed by TR Tech Solutions."),
            const SizedBox(height: 8),
            const Text("An intuitive and smart money management app to help you track expenses, manage budgets, and save more."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    bool isDailyReminderEnabled = true;
    bool isBudgetAlertEnabled = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setStateModal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text("Notification Settings"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text("Daily Reminder"),
                    subtitle: const Text("Receive a reminder to log expenses at 9:00 PM"),
                    value: isDailyReminderEnabled,
                    onChanged: (val) async {
                      setStateModal(() => isDailyReminderEnabled = val);
                      await NotificationService().setDailyReminderEnabled(val);
                    },
                  ),
                  SwitchListTile(
                    title: const Text("Budget Overspending Alert"),
                    subtitle: const Text("Notify when reaching 90% of category budget"),
                    value: isBudgetAlertEnabled,
                    onChanged: (val) async {
                      setStateModal(() => isBudgetAlertEnabled = val);
                      await NotificationService().setBudgetAlertEnabled(val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Done"),
                ),
              ],
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

      await FirebaseFirestore.instance.collection("users").doc(uid).delete();
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: "),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
