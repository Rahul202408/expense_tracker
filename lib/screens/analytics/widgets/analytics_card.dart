import 'package:flutter/material.dart';
import '../../../../widgets/three_d_tilt_card.dart';

class AnalyticsCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  const AnalyticsCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xff1E293B) : Colors.white;
    final amountTextColor = isDark ? Colors.white : const Color(0xff1A202C);
    final titleTextColor = isDark ? Colors.grey.shade300 : Colors.grey.shade600;
    final borderColor = isDark
        ? color.withValues(alpha: 0.3)
        : Colors.grey.shade200;

    return ThreeDTiltCard(
      margin: const EdgeInsets.symmetric(vertical: 8),
      maxTiltAngle: 0.08,
      elevation: isDark ? 2 : 8,
      shadowColor: isDark ? Colors.black : color,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xff1E293B),
                    color.withValues(alpha: 0.15),
                  ]
                : [
                    Colors.white,
                    color.withValues(alpha: 0.03),
                  ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                border: Border.all(
                  color: color.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: amountTextColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
