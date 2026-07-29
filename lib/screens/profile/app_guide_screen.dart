import 'package:flutter/material.dart';

class AppGuideScreen extends StatelessWidget {
  const AppGuideScreen({super.key});

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
          "How to Use App",
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
            // Top Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff00BCD4), Color(0xff00838F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff00BCD4).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: Colors.white, size: 36),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "User Guide & Tutorial",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Master all features of Expense Tracker",
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

            _buildGuideCard(
              cardBgColor: cardBgColor,
              textColor: textColor,
              subTextColor: subTextColor,
              stepNumber: "1",
              icon: Icons.add_circle_outline_rounded,
              iconColor: const Color(0xff4CAF50),
              title: "Adding Income & Expense Entries",
              description:
                  "Tap the '+' (Add) button on the home screen or quick navigation bar. Select whether it's an Expense or Income, pick a category (Food, Salary, Bills, Travel, etc.), enter the amount, select date, and tap Save.",
            ),

            _buildGuideCard(
              cardBgColor: cardBgColor,
              textColor: textColor,
              subTextColor: subTextColor,
              stepNumber: "2",
              icon: Icons.account_balance_wallet_rounded,
              iconColor: const Color(0xff00BCD4),
              title: "3D Balance Card & Overview",
              description:
                  "On the Home Screen, your net total balance is automatically updated in real-time on the 3D tilt card along with total income and total expense summaries.",
            ),

            _buildGuideCard(
              cardBgColor: cardBgColor,
              textColor: textColor,
              subTextColor: subTextColor,
              stepNumber: "3",
              icon: Icons.pie_chart_rounded,
              iconColor: const Color(0xff9C27B0),
              title: "Analytics & Pie Charts",
              description:
                  "Navigate to the Analytics tab to view detailed pie charts showing your category-wise spending percentage. Helps you instantly identify where your money goes.",
            ),

            _buildGuideCard(
              cardBgColor: cardBgColor,
              textColor: textColor,
              subTextColor: subTextColor,
              stepNumber: "4",
              icon: Icons.history_toggle_off_rounded,
              iconColor: const Color(0xffFF9800),
              title: "Filter & Search Transaction History",
              description:
                  "Go to the History tab to filter transactions by type (All, Expenses, Income), date ranges (Today, This Week, This Month), or search by category name.",
            ),

            _buildGuideCard(
              cardBgColor: cardBgColor,
              textColor: textColor,
              subTextColor: subTextColor,
              stepNumber: "5",
              icon: Icons.notifications_active_rounded,
              iconColor: const Color(0xffE91E63),
              title: "Daily Reminders & Budget Health Alerts",
              description:
                  "In Profile -> Notifications, set your preferred daily reminder time (e.g. 8:00 PM) so you never forget to log expenses. Turn on Budget Health Alerts to get warned if spending reaches 80% or 100% of income.",
            ),

            _buildGuideCard(
              cardBgColor: cardBgColor,
              textColor: textColor,
              subTextColor: subTextColor,
              stepNumber: "6",
              icon: Icons.fingerprint_rounded,
              iconColor: const Color(0xff3F51B5),
              title: "App Lock & Security Settings",
              description:
                  "Keep your private financial records secure! Go to Profile -> Security Settings to enable PIN Lock or Biometric authentication (Fingerprint / Face ID).",
            ),

            _buildGuideCard(
              cardBgColor: cardBgColor,
              textColor: textColor,
              subTextColor: subTextColor,
              stepNumber: "7",
              icon: Icons.dark_mode_rounded,
              iconColor: const Color(0xffFFC107),
              title: "Dark Mode & Personalization",
              description:
                  "Switch effortlessly between sleek Dark Mode and clean Light Mode anytime from the toggle in the Profile tab.",
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required Color cardBgColor,
    required Color textColor,
    required Color subTextColor,
    required String stepNumber,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Step $stepNumber",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
