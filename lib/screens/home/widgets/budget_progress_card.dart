import 'package:flutter/material.dart';
import '../../../widgets/three_d_tilt_card.dart';

class BudgetProgressCard extends StatelessWidget {
  final double income;
  final double expense;

  const BudgetProgressCard({
    super.key,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xff1E293B) : Colors.white;
    final titleTextColor = isDark ? Colors.white : const Color(0xff2D3748);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.shade200;

    final double safeIncome = income > 0 ? income : 1.0;
    final double ratio = (expense / safeIncome).clamp(0.0, 1.0);
    final int percentage = (ratio * 100).toInt();

    Color statusColor = const Color(0xff00E676);
    String statusMessage = "Excellent Budget Health!";

    if (percentage > 85) {
      statusColor = const Color(0xffFF5252);
      statusMessage = "Warning: High Spending Ratio";
    } else if (percentage > 60) {
      statusColor = const Color(0xffFF9800);
      statusMessage = "Moderate Spending Rate";
    }

    return ThreeDTiltCard(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      maxTiltAngle: 0.08,
      elevation: isDark ? 2 : 8,
      shadowColor: isDark ? Colors.black : statusColor,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xff1E293B),
                    statusColor.withValues(alpha: 0.12),
                  ]
                : [
                    Colors.white,
                    statusColor.withValues(alpha: 0.04),
                  ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        Icons.donut_large_rounded,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Budget Health",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: titleTextColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$percentage% Spent",
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Liquid Progress Bar
            Stack(
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withValues(alpha: 0.7),
                          statusColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              statusMessage,
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
