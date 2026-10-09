import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import '../../services/notification_service.dart';
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
import '../../widgets/google_review_dialog.dart';
import '../../widgets/currency_picker_bottom_sheet.dart';

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
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        future: authService.getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data?.data() ?? {};
          final currentAuthUser = FirebaseAuth.instance.currentUser;

          // Robust cascade name resolution
          String resolvedFullName = "";
          if (user["fullName"] != null && user["fullName"].toString().trim().isNotEmpty) {
            resolvedFullName = user["fullName"].toString().trim();
          } else if (user["displayName"] != null && user["displayName"].toString().trim().isNotEmpty) {
            resolvedFullName = user["displayName"].toString().trim();
          } else if (user["name"] != null && user["name"].toString().trim().isNotEmpty) {
            resolvedFullName = user["name"].toString().trim();
          } else if (currentAuthUser?.displayName != null && currentAuthUser!.displayName!.trim().isNotEmpty) {
            resolvedFullName = currentAuthUser.displayName!.trim();
          } else if (AuthService.cachedName != null && AuthService.cachedName!.trim().isNotEmpty) {
            resolvedFullName = AuthService.cachedName!.trim();
          } else if (currentAuthUser?.email != null && currentAuthUser!.email!.isNotEmpty) {
            resolvedFullName = currentAuthUser.email!.split('@')[0];
          } else if (user["email"] != null && user["email"].toString().isNotEmpty) {
            resolvedFullName = user["email"].toString().split('@')[0];
          } else if (AuthService.cachedEmail != null && AuthService.cachedEmail!.isNotEmpty) {
            resolvedFullName = AuthService.cachedEmail!.split('@')[0];
          }
          final fullName = resolvedFullName.isNotEmpty ? resolvedFullName : "Valued User";

          final email = (user["email"] != null && user["email"].toString().trim().isNotEmpty)
              ? user["email"].toString().trim()
              : (currentAuthUser?.email ?? AuthService.cachedEmail ?? "No Email Connected");

          final phone = user["phone"] ?? "";

          final photoUrl = (user["photoUrl"] != null && user["photoUrl"].toString().trim().isNotEmpty)
              ? user["photoUrl"].toString().trim()
              : (currentAuthUser?.photoURL ?? AuthService.cachedPhotoUrl ?? "");

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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xff10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xff10B981).withValues(alpha: 0.28),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currencyProvider.currentCurrency.flagEmoji,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "${currencyProvider.symbol} ${currencyProvider.code}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xff10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: subtitleTextColor.withValues(alpha: 0.5),
                            size: 22,
                          ),
                        ],
                      ),
                      dividerColor: dividerColor,
                      onTap: () => _showCurrencyDialog(context, currencyProvider),
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
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xffFBBF24),
                      title: "Rate on Google Play",
                      subtitle: "Share your experience with 5 stars ⭐",
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: subtitleTextColor.withValues(alpha: 0.5),
                        size: 22,
                      ),
                      dividerColor: dividerColor,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const GoogleReviewDialog(),
                        );
                      },
                    ),
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
                          "v1.3.5 (35)",
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
                        "Expense Tracker • Version 1.3.5 (Build 35)",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: subtitleTextColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 125),
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
          color: isPro
              ? const Color(0xffF59E0B).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.12),
          width: isPro ? 1.5 : 1.2,
        ),
        boxShadow: [
          if (isPro)
            BoxShadow(
              color: const Color(0xffF59E0B).withValues(alpha: 0.2),
              blurRadius: 24,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
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
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isPro
                              ? [const Color(0xffFBBF24), const Color(0xffFFD700), const Color(0xffD97706)]
                              : [const Color(0xff38BDF8), const Color(0xff6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isPro ? const Color(0xffF59E0B) : const Color(0xff38BDF8))
                                .withValues(alpha: 0.45),
                            blurRadius: 16,
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
                    if (isPro)
                      Positioned(
                        top: -5,
                        left: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xffFBBF24), Color(0xffD97706)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xffF59E0B).withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Text('👑', style: TextStyle(fontSize: 10, height: 1)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xffF59E0B), Color(0xffD97706)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xffF59E0B).withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('👑', style: TextStyle(fontSize: 10)),
                                SizedBox(width: 3),
                                Text(
                                  "VIP",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
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
                  colors: [Color(0xffD97706), Color(0xff78350F)],
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
                        pro.isPro ? "VIP PRO MEMBER 👑" : "UPGRADE TO PRO 👑",
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
                          pro.isPro ? "VIP ACTIVE ✨" : "VIP ACCESS",
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
                        ? "Tap to review VIP Superpowers • 100% Ad-Free • Unlimited PDF"
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

  Future<void> _showCurrencyDialog(BuildContext context, CurrencyProvider currencyProvider) async {
    final picked = await showCurrencyPickerModal(
      context: context,
      selectedCurrency: currencyProvider.currentCurrency,
    );
    if (picked != null) {
      await currencyProvider.setCurrency(picked);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Currency updated to ${picked.country} (${picked.symbol} ${picked.code})! 🎉"),
            backgroundColor: const Color(0xff10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8 * anim.value,
            sigmaY: 8 * anim.value,
          ),
          child: ScaleTransition(
            scale: curvedAnim,
            child: FadeTransition(
              opacity: anim,
              child: Dialog(
                backgroundColor: isDark ? const Color(0xff1E293B) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                  side: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                elevation: 16,
                insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xff6366F1).withValues(alpha: 0.22),
                              const Color(0xff8B5CF6).withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff6366F1).withValues(alpha: 0.25),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: Color(0xff6366F1),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Privacy Policy",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: isDark ? Colors.white : const Color(0xff0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Your privacy and financial security come first.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xff64748B),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildPrivacyItem(
                        icon: Icons.lock_outline_rounded,
                        color: const Color(0xff10B981),
                        title: "Encrypted Cloud Storage",
                        subtitle: "All records are securely encrypted via Google Firebase servers.",
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildPrivacyItem(
                        icon: Icons.shield_outlined,
                        color: const Color(0xff3B82F6),
                        title: "No Data Selling",
                        subtitle: "We never sell, rent, or trade your personal or financial data.",
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildPrivacyItem(
                        icon: Icons.download_done_rounded,
                        color: const Color(0xff8B5CF6),
                        title: "You Own Your Data",
                        subtitle: "You can export reports to Excel/PDF or delete your data anytime.",
                        isDark: isDark,
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Understood",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacyItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff0F172A) : const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xffE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xff1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : const Color(0xff64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8 * anim.value,
            sigmaY: 8 * anim.value,
          ),
          child: ScaleTransition(
            scale: curvedAnim,
            child: FadeTransition(
              opacity: anim,
              child: Dialog(
                backgroundColor: isDark ? const Color(0xff1E293B) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                  side: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                elevation: 16,
                insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xff0F172A) : const Color(0xffF1F5F9),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff6366F1).withValues(alpha: 0.18),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const AppLogo(size: 48, showShadow: false),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Expense Tracker",
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: isDark ? Colors.white : const Color(0xff0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Smart Money & Budget Manager",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : const Color(0xff64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xff10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xff10B981).withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, size: 14, color: Color(0xff10B981)),
                            SizedBox(width: 5),
                            Text(
                              "Version 1.3.5 (Build 35)",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xff10B981),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xff0F172A) : const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white10 : const Color(0xffE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildAboutFeatureRow(
                              icon: Icons.insights_rounded,
                              color: const Color(0xff3B82F6),
                              text: "Smart Analytics & Category Insights",
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildAboutFeatureRow(
                              icon: Icons.cloud_sync_rounded,
                              color: const Color(0xff10B981),
                              text: "Real-time Cloud Sync & Backup",
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildAboutFeatureRow(
                              icon: Icons.lock_rounded,
                              color: const Color(0xffF59E0B),
                              text: "PIN & Biometric Security Protection",
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Developed with ❤️ by TR Tech Solutions",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xff475569),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xff334155) : const Color(0xff0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Close",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutFeatureRow({
    required IconData icon,
    required Color color,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xff334155),
            ),
          ),
        ),
      ],
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
                        await notifService.sendTestNotification();
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
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? AuthService.cachedEmail;
    final userName = FirebaseAuth.instance.currentUser?.displayName;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "LogoutDialog",
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curve),
            child: FadeTransition(
              opacity: anim1,
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xff131D31) : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.grey.shade200,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Glowing Luxury Logout Icon Badge
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xffEF4444).withValues(alpha: 0.22),
                              const Color(0xffF43F5E).withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: const Color(0xffEF4444).withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xffEF4444).withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xffEF4444), Color(0xffDC2626)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 2. Title
                      Text(
                        "Log Out of Expense Tracker?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xff0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 3. Subtitle description
                      Text(
                        "Are you sure you want to exit? You can sign right back in anytime to continue managing your money.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xff94A3B8) : const Color(0xff64748B),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 4. User Status & Cloud Backup Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xff10B981).withValues(alpha: 0.25),
                                    const Color(0xff059669).withValues(alpha: 0.15),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xff10B981).withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Icon(
                                Icons.cloud_done_rounded,
                                color: Color(0xff10B981),
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName != null && userName.isNotEmpty
                                        ? userName
                                        : (userEmail ?? "Active Account"),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xff1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    "Transactions safely synced to cloud",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 5. Action Buttons (Stay In & Log Out)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : Colors.grey.shade300,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                "Stay In",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.grey.shade300 : const Color(0xff475569),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [Color(0xffEF4444), Color(0xffDC2626)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xffEF4444).withValues(alpha: 0.4),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await authService.logout();
                                  TransactionService.clearCache();
                                  if (!context.mounted) return;
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                                    (route) => false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.logout_rounded, color: Colors.white, size: 17),
                                    SizedBox(width: 6),
                                    Text(
                                      "Log Out",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext dialogContext) {
    final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

    showGeneralDialog(
      context: dialogContext,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8 * anim.value,
            sigmaY: 8 * anim.value,
          ),
          child: ScaleTransition(
            scale: curvedAnim,
            child: FadeTransition(
              opacity: anim,
              child: Dialog(
                backgroundColor: isDark ? const Color(0xff1E293B) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                  side: const BorderSide(
                    color: Color(0xffEF4444),
                    width: 1.2,
                  ),
                ),
                elevation: 20,
                insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xffDC2626).withValues(alpha: 0.25),
                              const Color(0xffEF4444).withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xffDC2626).withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xffDC2626),
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "Delete Account?",
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: isDark ? Colors.white : const Color(0xff0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xffEF4444).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xffEF4444).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.delete_sweep_rounded, color: Color(0xffEF4444), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "All transaction history, budgets, and cloud records will be permanently erased.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : const Color(0xff991B1B),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.lock_reset_rounded, color: Color(0xffEF4444), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "This action is immediate and completely irreversible.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : const Color(0xff991B1B),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(
                                  color: isDark ? Colors.white24 : const Color(0xffCBD5E1),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                "Keep Account",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white70 : const Color(0xff475569),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [Color(0xffDC2626), Color(0xffB91C1C)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xffDC2626).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await deleteAccount();
                                },
                                icon: const Icon(Icons.delete_forever_rounded, size: 18, color: Colors.white),
                                label: const Text(
                                  "Delete Forever",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final uid = user.uid;

      // 1. Delete all user transaction records in subcollection
      final transactionsRef = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("transactions");
      final snapshot = await transactionsRef.get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(FirebaseFirestore.instance.collection("users").doc(uid));
      await batch.commit();

      // 2. Delete user from Firebase Auth
      await user.delete();

      // 3. Clear auth session & transaction cache
      await AuthService().logout();
      TransactionService.clearCache();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account and data deleted successfully"),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Security requirement: Please log out and log back in before deleting your account."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.message ?? e.code}"),
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
}