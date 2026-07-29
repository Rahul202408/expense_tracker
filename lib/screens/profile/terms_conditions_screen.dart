import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xff0F172A) : const Color(0xffF8FAFC);
    final cardBgColor = isDark ? const Color(0xff1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xff1E293B);
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff11998E), Color(0xff38EF7D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff11998E).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.gavel_rounded, color: Colors.white, size: 36),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Legal & Privacy Terms",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Last updated: July 2026",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionCard(
              cardBgColor: cardBgColor,
              textColor: textColor,
              subTextColor: subTextColor,
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xff11998E),
              title: "1. Acceptance of Terms",
              content:
                  "By creating an account or accessing the Expense Tracker application, you agree to comply with and be bound by these Terms & Conditions. If you do not agree to these terms, please refrain from using the application.",
            ),

            _buildSectionCard(
              cardBgColor: cardBgColor,
              textColor: textColor,
              subTextColor: subTextColor,
              icon: Icons.security_rounded,
              iconColor: const Color(0xff00BCD4),
              title: "2. User Account & Security",
              content:
                  "You are responsible for maintaining the confidentiality of your login credentials, PIN, and biometric access (Fingerprint/Face ID). Any activity occurring under your account is your sole responsibility. You agree to notify us immediately of any unauthorized access.",
            ),

            _buildSectionCard(
              cardBgColor: cardBgColor,
              textColor: textColor,
              subTextColor: subTextColor,
              icon: Icons.account_balance_wallet_rounded,
              iconColor: const Color(0xff4CAF50),
              title: "3. Financial Data & Cloud Sync",
              content:
                  "Expense Tracker provides personal money management tools. Your income and expense entries are securely encrypted and saved using Google Firebase Cloud Services. We do not sell, share, or monetize your personal transaction records with third parties.",
            ),

            _buildSectionCard(
              cardBgColor: cardBgColor,
              textColor: textColor,
              subTextColor: subTextColor,
              icon: Icons.notifications_active_rounded,
              iconColor: const Color(0xffFF9800),
              title: "4. Notifications & Alerts",
              content:
                  "The application offers optional daily expense recording reminders and budget health threshold warnings (80% & 100% of income). You can enable or disable these notifications anytime in Profile -> Notification Settings.",
            ),

            _buildSectionCard(
              cardBgColor: cardBgColor,
              textColor: textColor,
              subTextColor: subTextColor,
              icon: Icons.ads_click_rounded,
              iconColor: const Color(0xff9C27B0),
              title: "5. Advertisements & AdMob Policies",
              content:
                  "To keep Expense Tracker free for all users, Google AdMob advertisements (Banner, Native, and App Open ads) are integrated. These ads comply with Google AdMob Publisher Policies and do not access your private financial records.",
            ),

            _buildSectionCard(
              cardBgColor: cardBgColor,
              textColor: textColor,
              subTextColor: subTextColor,
              icon: Icons.assignment_late_rounded,
              iconColor: const Color(0xffE53935),
              title: "6. Limitation of Liability",
              content:
                  "Expense Tracker is designed for personal budgeting and informational purposes only. While we aim for 100% accuracy, the developers are not liable for any financial decisions, loss of data, or inaccuracies resulting from user inputs.",
            ),

            _buildSectionCard(
              cardBgColor: cardBgColor,
              textColor: textColor,
              subTextColor: subTextColor,
              icon: Icons.update_rounded,
              iconColor: const Color(0xff3F51B5),
              title: "7. Modifications & Contact",
              content:
                  "We reserve the right to update these terms to reflect feature improvements or policy changes. Continued use of the app signifies acceptance of updated terms. For inquiries or support, contact us via the app support portal.",
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required Color cardBgColor,
    required Color textColor,
    required Color subTextColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: subTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
