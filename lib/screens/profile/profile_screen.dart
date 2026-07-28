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
                  "Version 1.0.0",
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
                        "Version 1.0.0",
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.notifications_active_rounded, color: Color(0xff00BCD4)),
              SizedBox(width: 10),
              Text("Notifications"),
            ],
          ),
          content: const Text(
            "🔔 Push notifications are enabled! You will receive reminders for daily expense tracking and weekly budget health reports.",
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                NotificationService().showLocalNotification(
                  id: 1,
                  title: "Test Notification 🔔",
                  body: "Notifications are working perfectly in Expense Tracker!",
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Test notification sent!"),
                    backgroundColor: Colors.teal,
                  ),
                );
              },
              child: const Text("Send Test"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff00BCD4),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
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



