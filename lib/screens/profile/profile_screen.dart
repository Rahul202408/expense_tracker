import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/payment_notification_service.dart';
import '../../services/currency_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/app_logo.dart';
import '../splash/splash_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'security_settings_screen.dart';
import 'terms_conditions_screen.dart';
import 'app_guide_screen.dart';
import '../pro/pro_screen.dart';
import '../../providers/pro_provider.dart';

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
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final proProvider = Provider.of<ProProvider>(context);
    final isDark = themeProvider.isDark;

    // Theme tailored palette
    final bgColor = isDark ? const Color(0xff0B1120) : const Color(0xffF4F6FB);
    final surfaceColor = isDark ? const Color(0xff162032) : Colors.white;
    final cardBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final titleTextColor = isDark ? Colors.white : const Color(0xff1E293B);
    final subtitleTextColor = isDark ? const Color(0xff94A3B8) : const Color(0xff64748B);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Account & Settings",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: titleTextColor,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: authService.getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data?.data() ?? {};
          final fullName = user["fullName"] ?? "Valued User";
          final email = user["email"] ?? "No Email Connected";
          final phone = user["phone"] ?? "";
          final photoUrl = user["photoUrl"] ?? "";

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HERO PROFILE CARD
                _buildHeroProfileCard(
                  fullName: fullName,
                  email: email,
                  phone: phone,
                  photoUrl: photoUrl,
                  isPro: proProvider.isPro,
                  currencyCode: currencyProvider.code,
                  currencySymbol: currencyProvider.symbol,
                  onEditTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(fullName: fullName, phone: phone),
                      ),
                    );
                    if (result == true && mounted) {
                      setState(() {});
                    }
                  },
                ),

                const SizedBox(height: 16),

                // 2. VIP PRO SHOWCASE CARD
                _buildProCard(context, proProvider),

                const SizedBox(height: 24),

                // 3. SECTION 1: PREFERENCES & SMART TOOLS
                _buildSectionTitle("PREFERENCES & SMART TOOLS", subtitleTextColor),
                const SizedBox(height: 8),
                _buildGroupContainer(
                  surfaceColor: surfaceColor,
                  borderColor: cardBorderColor,
                  children: [
                    _buildSettingRow(
                      icon: Icons.currency_exchange_rounded,
                      iconColor: const Color(0xff10B981),
                      title: "Currency & Region",
                      subtitle: "Manage default display currency",
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xff10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xff10B981).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          "${currencyProvider.symbol} ${currencyProvider.code}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff10B981),
                          ),
                        ),
                      ),
                      dividerColor: dividerColor,
                      onTap: () => _showCurrencyDialog(context, currencyProvider),
                    ),
                    _buildSettingRow(
                      icon: Icons.flash_auto_rounded,
                      iconColor: const Color(0xff3B82F6),
                      title: "Auto-Detect UPI Payments",
                      subtitle: "Instant SMS/Notification expense logging",
                      trailing: Switch.adaptive(
                        value: _isAutoDetectEnabled,
                        activeColor: const Color(0xff3B82F6),
                        onChanged: (val) async {
                          setState(() => _isAutoDetectEnabled = val);
                          await PaymentNotificationService().setAutoDetectEnabled(val);
                        },
                      ),
                      dividerColor: dividerColor,
                    ),
                    _buildSettingRow(
                      icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      iconColor: isDark ? const Color(0xff818CF8) : const Color(0xffF59E0B),
                      title: "Dark Appearance",
                      subtitle: isDark ? "Dark theme active" : "Light theme active",
                      trailing: Switch.adaptive(
                        value: themeProvider.isDark,
                        activeColor: const Color(0xff818CF8),
                        onChanged: (val) => themeProvider.toggleTheme(val),
                      ),
                      dividerColor: dividerColor,
                    ),
                    _buildSettingRow(
                      icon: Icons.notifications_active_rounded,
                      iconColor: const Color(0xffEC4899),
                      title: "Notifications & Reminders",
                      subtitle: "Daily 9:00 PM log reminder & budget alerts",
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: subtitleTextColor.withValues(alpha: 0.5),
                        size: 22,
                      ),
                      dividerColor: null, // Last item, no divider
                      onTap: () => _showNotificationsDialog(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 4. SECTION 2: SECURITY & ACCOUNT
                _buildSectionTitle("SECURITY & ACCOUNT", subtitleTextColor),
                const SizedBox(height: 8),
                _buildGroupContainer(
                  surfaceColor: surfaceColor,
                  borderColor: cardBorderColor,
                  children: [
                    _buildSettingRow(
                      icon: Icons.badge_rounded,
                      iconColor: const Color(0xff06B6D4),
                      title: "Personal Information",
                      subtitle: "Edit name, phone number & profile",
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: subtitleTextColor.withValues(alpha: 0.5),
                        size: 22,
                      ),
                      dividerColor: dividerColor,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(fullName: fullName, phone: phone),
                          ),
                        );
                        if (result == true && mounted) {
                          setState(() {});
                        }
                      },
                    ),
                    _buildSettingRow(
                      icon: Icons.lock_reset_rounded,
                      iconColor: const Color(0xffF59E0B),
                      title: "Change Password",
                      subtitle: "Update account authentication password",
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: subtitleTextColor.withValues(alpha: 0.5),
                        size: 22,
                      ),
                      dividerColor: dividerColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                        );
                      },
                    ),
                    _buildSettingRow(
                      icon: Icons.security_rounded,
                      iconColor: const Color(0xff10B981),
                      title: "App Lock & Biometrics",
                      subtitle: proProvider.isPro
                          ? "Fingerprint, Face Unlock & PIN security"
                          : "Exclusive PRO feature • Lock your app",
                      trailing: proProvider.isPro
                          ? Icon(
                              Icons.chevron_right_rounded,
                              color: subtitleTextColor.withValues(alpha: 0.5),
                              size: 22,
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xffF59E0B), Color(0xffD97706)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xffF59E0B).withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_rounded, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    "PRO",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      dividerColor: null,
                      onTap: () {
                        if (!proProvider.isPro) {
                          _showAppLockPaywall(context);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
                          );
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 5. SECTION 3: HELP & LEGAL
                _buildSectionTitle("SUPPORT & LEGAL", subtitleTextColor),
                const SizedBox(height: 8),
                _buildGroupContainer(
                  surfaceColor: surfaceColor,
                  borderColor: cardBorderColor,
                  children: [
                    _buildSettingRow(
                      icon: Icons.menu_book_rounded,
                      iconColor: const Color(0xff6366F1),
                      title: "How to Use App",
                      subtitle: "Interactive guide & feature walkthroughs",
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: subtitleTextColor.withValues(alpha: 0.5),
                        size: 22,
                      ),
                      dividerColor: dividerColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AppGuideScreen()),
                        );
                      },
                    ),
                    _buildSettingRow(
                      icon: Icons.description_rounded,
                      iconColor: const Color(0xff64748B),
                      title: "Terms & Conditions",
                      subtitle: "Usage guidelines and policies",
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: subtitleTextColor.withValues(alpha: 0.5),
                        size: 22,
                      ),
                      dividerColor: dividerColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                        );
                      },
                    ),
                    _buildSettingRow(
                      icon: Icons.privacy_tip_rounded,
                      iconColor: const Color(0xff14B8A6),
                      title: "Privacy Policy",
                      subtitle: "How your data is encrypted & protected",
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: subtitleTextColor.withValues(alpha: 0.5),
                        size: 22,
                      ),
                      dividerColor: dividerColor,
                      onTap: () => _showPrivacyPolicyDialog(context),
                    ),
                    _buildSettingRow(
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xff8B5CF6),
                      title: "About Expense Tracker",
                      subtitle: "Developed by TR Tech Solutions",
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xff8B5CF6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xff8B5CF6).withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Text(
                          "v1.2.1 (21)",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff8B5CF6),
                          ),
                        ),
                      ),
                      dividerColor: null,
                      onTap: () => _showAboutAppDialog(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 6. SECTION 4: ACTIONS (LOGOUT & DELETE)
                _buildSectionTitle("ACCOUNT ACTIONS", subtitleTextColor),
                const SizedBox(height: 8),
                _buildGroupContainer(
                  surfaceColor: surfaceColor,
                  borderColor: cardBorderColor,
                  children: [
                    _buildSettingRow(
                      icon: Icons.logout_rounded,
                      iconColor: const Color(0xffEF4444),
                      title: "Log Out",
                      subtitle: "Sign out safely from this device",
                      trailing: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xffEF4444),
                        size: 20,
                      ),
                      dividerColor: dividerColor,
                      onTap: () => _showLogoutConfirmDialog(context, authService),
                    ),
                    _buildSettingRow(
                      icon: Icons.delete_forever_rounded,
                      iconColor: const Color(0xffDC2626),
                      title: "Delete Account",
                      subtitle: "Permanently erase all transaction data",
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xffDC2626),
                        size: 22,
                      ),
                      dividerColor: null,
                      onTap: () => _showDeleteDialog(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 7. FOOTER BRANDING
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: Color(0xff11998E),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Created By TR Tech Solutions",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : const Color(0xff475569),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Expense Tracker • Version 1.2.1 (Build 21)",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: subtitleTextColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===================== WIDGET COMPONENTS =====================

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildHeroProfileCard({
    required String fullName,
    required String email,
    required String phone,
    required String photoUrl,
    required bool isPro,
    required String currencyCode,
    required String currencySymbol,
    required VoidCallback onEditTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff1E293B),
            Color(0xff0F172A),
            Color(0xff090D16),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0F172A).withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with dynamic gradient ring & edit badge
              GestureDetector(
                onTap: onEditTap,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isPro
                              ? [const Color(0xffFBBF24), const Color(0xffD97706)]
                              : [const Color(0xff38BDF8), const Color(0xff6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isPro ? const Color(0xffF59E0B) : const Color(0xff38BDF8))
                                .withValues(alpha: 0.35),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xff1E293B),
                        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl.isEmpty
                            ? const Icon(
                                Icons.person_rounded,
                                size: 38,
                                color: Colors.white70,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xff2563EB),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Name, Email, Phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isPro)
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
                              ),
                            ),
                          )
                        else
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xff38BDF8),
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Quick Status Pills Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStatPill(
                  dotColor: const Color(0xff10B981),
                  label: "Status",
                  value: "Active",
                ),
                _buildDividerDot(),
                _buildQuickStatPill(
                  dotColor: const Color(0xff38BDF8),
                  label: "Currency",
                  value: "$currencySymbol $currencyCode",
                ),
                _buildDividerDot(),
                _buildQuickStatPill(
                  dotColor: isPro ? const Color(0xffF59E0B) : const Color(0xff94A3B8),
                  label: "Plan",
                  value: isPro ? "PRO VIP ✨" : "Free Plan",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatPill({
    required Color dotColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDividerDot() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }

  Widget _buildProCard(BuildContext context, ProProvider pro) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: pro.isPro
              ? const LinearGradient(
                  colors: [Color(0xffD97706), Color(0xff92400E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xff1E293B), Color(0xff0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: Border.all(
            color: const Color(0xffF59E0B).withValues(alpha: 0.6),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffF59E0B).withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xffFBBF24), Color(0xffD97706)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffF59E0B).withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        pro.isPro ? "PRO MEMBER 👑" : "UPGRADE TO PRO 👑",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xffF59E0B).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xffF59E0B),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          pro.isPro ? "ACTIVE" : "VIP ACCESS",
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xffFBBF24),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    pro.isPro
                        ? "100% Ad-Free • Biometric App Lock • Unlimited PDF Reports"
                        : "Remove all ads, unlock Biometric Lock & PDF reports",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupContainer({
    required Color surfaceColor,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required Color? dividerColor,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon in soft tinted circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 21),
                ),
                const SizedBox(width: 14),
                // Titles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
        if (dividerColor != null)
          Padding(
            padding: const EdgeInsets.only(left: 70, right: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: dividerColor,
            ),
          ),
      ],
    );
  }

  // ===================== DIALOGS & ACTIONS =====================

  void _showCurrencyDialog(BuildContext context, CurrencyProvider currencyProvider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            "Select Currency & Country",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: CurrencyService.supportedCurrencies.length,
              itemBuilder: (context, index) {
                final curr = CurrencyService.supportedCurrencies[index];
                final isSelected = curr.code == currencyProvider.code;

                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: isSelected ? const Color(0xff10B981).withValues(alpha: 0.1) : null,
                  title: Text(
                    "${curr.name} (${curr.symbol})",
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? const Color(0xff10B981) : null,
                    ),
                  ),
                  subtitle: Text("${curr.country} [${curr.countryCode}]"),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xff10B981))
                      : null,
                  onTap: () async {
                    await currencyProvider.setCurrency(curr);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Currency updated to ${curr.name} (${curr.symbol})! 🎉"),
                          backgroundColor: const Color(0xff10B981),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Privacy Policy", style: TextStyle(fontWeight: FontWeight.w800)),
        content: const SingleChildScrollView(
          child: Text(
            "Expense Tracker values your privacy. We collect minimal personal information necessary to manage your financial data securely.\n\nAll your expense data is stored securely using Google Firebase encryption. We never share or sell your personal or financial information to any third party.",
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            AppLogo(size: 38, showShadow: false),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Expense Tracker",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xff10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Version: 1.2.1 (Build 21)",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xff10B981),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Developed by TR Tech Solutions.",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              "An intuitive, smart money manager designed to help you track daily expenses, manage category budgets, and achieve financial freedom.",
              style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAppLockPaywall(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xff0F172A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xffF59E0B), width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xffF59E0B).withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xffF59E0B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "PRO Feature",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xff1E293B),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "App Lock (PIN & Biometric Security) is an exclusive PRO feature.",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xff1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Protect your sensitive financial records from prying eyes with Fingerprint, Face ID, and 4-Digit PIN protection.\n\nUpgrade to PRO to get full security, 100% ad-free experience, unlimited PDF & Excel exports, and more!",
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark ? Colors.white70 : const Color(0xff475569),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Maybe Later",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffF59E0B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProScreen()),
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium_rounded, size: 18, color: Colors.black),
                  SizedBox(width: 6),
                  Text(
                    "Unlock PRO 👑",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNotificationsDialog(BuildContext context) async {
    final notifService = NotificationService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark ? const Color(0xff162032) : Colors.white;
    final cardBgColor = isDark ? const Color(0xff0B1120) : const Color(0xffF8FAFC);
    final titleTextColor = isDark ? Colors.white : const Color(0xff1E293B);
    final subtitleTextColor = isDark ? const Color(0xff94A3B8) : const Color(0xff64748B);
    final cardBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    // Initial values loaded from NotificationService
    bool isDailyReminderEnabled = await notifService.getIsDailyReminderEnabled();
    bool isBudgetAlertEnabled = await notifService.getIsBudgetAlertEnabled();
    TimeOfDay reminderTime = await notifService.getDailyReminderTime();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setStateModal) {
            String formatTime(TimeOfDay time) {
              final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
              final minute = time.minute.toString().padLeft(2, '0');
              final period = time.period == DayPeriod.am ? 'AM' : 'PM';
              return "$hour:$minute $period";
            }

            return Dialog(
              backgroundColor: surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                  width: 1.2,
                ),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row with Glow Badge & Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xffEC4899), Color(0xffF43F5E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xffEC4899).withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Notifications & Alerts",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: titleTextColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Never miss daily expense logging",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subtitleTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close_rounded, color: subtitleTextColor, size: 22),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Card 1: Daily Log Reminder Card
                    Container(
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDailyReminderEnabled
                              ? const Color(0xffEC4899).withValues(alpha: 0.35)
                              : cardBorderColor,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffEC4899).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.alarm_rounded,
                                    color: Color(0xffEC4899),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Daily Log Reminder",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: titleTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Gentle reminder to record expenses",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: subtitleTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: isDailyReminderEnabled,
                                  activeColor: const Color(0xffEC4899),
                                  onChanged: (val) async {
                                    setStateModal(() => isDailyReminderEnabled = val);
                                    await notifService.setDailyReminderEnabled(val);
                                  },
                                ),
                              ],
                            ),
                          ),

                          // If enabled, display clickable Time Picker row
                          if (isDailyReminderEnabled) ...[
                            Divider(height: 1, color: cardBorderColor),
                            InkWell(
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: ctx,
                                  initialTime: reminderTime,
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.fromSeed(
                                          seedColor: const Color(0xffEC4899),
                                          brightness: isDark ? Brightness.dark : Brightness.light,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setStateModal(() => reminderTime = picked);
                                  await notifService.setDailyReminderTime(picked);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Reminder scheduled for ${formatTime(picked)} daily!"),
                                        backgroundColor: const Color(0xffEC4899),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule_rounded,
                                      size: 18,
                                      color: Color(0xffEC4899),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Reminder Time",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: subtitleTextColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffEC4899).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xffEC4899).withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            formatTime(reminderTime),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xffEC4899),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.edit_rounded,
                                            size: 13,
                                            color: Color(0xffEC4899),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Card 2: Budget Overspending Alert Card
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isBudgetAlertEnabled
                              ? const Color(0xff3B82F6).withValues(alpha: 0.35)
                              : cardBorderColor,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xff3B82F6).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.trending_up_rounded,
                              color: Color(0xff3B82F6),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Budget Limit Alerts",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: titleTextColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Instant heads-up at 80% & 100% limit",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: subtitleTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: isBudgetAlertEnabled,
                            activeColor: const Color(0xff3B82F6),
                            onChanged: (val) async {
                              setStateModal(() => isBudgetAlertEnabled = val);
                              await notifService.setBudgetAlertEnabled(val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Card 3: Test Notification Button
                    InkWell(
                      onTap: () async {
                        await notifService.showLocalNotification(
                          id: 8888,
                          title: "🔔 Expense Reminder",
                          body: "Don't forget to track your expenses for today!",
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Test notification sent! Check your notification bar."),
                              backgroundColor: Color(0xff10B981),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xff10B981).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xff10B981).withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_active_outlined,
                              size: 18,
                              color: Color(0xff10B981),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Send Test Notification Now",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Save / Done Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffEC4899),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          "Save & Close",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutConfirmDialog(BuildContext context, AuthService authService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xff1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xffEF4444).withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xffEF4444),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Log Out",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xff1E293B),
                ),
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to log out of your account? You will need to log back in to access your transactions.",
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDark ? Colors.grey.shade300 : const Color(0xff475569),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await authService.logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              },
              child: const Text(
                "Log Out",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 8),
              Text("Delete Account", style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          content: const Text(
            "Are you sure you want to delete your account?\n\nAll your expense and income records will be permanently removed. This action cannot be undone.",
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await deleteAccount();
              },
              child: const Text("Delete Account", style: TextStyle(color: Colors.white)),
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
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}