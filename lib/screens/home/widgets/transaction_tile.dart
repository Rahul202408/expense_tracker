import 'package:flutter/material.dart';
import '../../../widgets/three_d_tilt_card.dart';

class TransactionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String category;
  final String amount;
  final bool isExpense;
  final DateTime? date;

  const TransactionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.category,
    required this.amount,
    required this.isExpense,
    this.date,
  });

  String _formatDate(DateTime? d) {
    if (d == null) return "Today";
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(d.year, d.month, d.day);
    final diff = today.difference(txDate).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";

    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${d.day} ${months[d.month - 1]} ${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xff1E293B) : Colors.white;
    final titleTextColor = isDark ? Colors.white : const Color(0xff2D3748);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.shade200;

    return ThreeDTiltCard(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      maxTiltAngle: 0.06,
      elevation: isDark ? 2 : 6,
      shadowColor: isDark ? Colors.black : iconColor,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(22),
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
                    const Color(0xff162032),
                  ]
                : [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
          ),
        ),
        child: Row(
          children: [
            // 3D Glowing Icon container
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    iconColor.withValues(alpha: 0.25),
                    iconColor.withValues(alpha: 0.10),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: titleTextColor,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isExpense ? "- ₹$amount" : "+ ₹$amount",
                  style: TextStyle(
                    color: isExpense
                        ? const Color(0xffFF5252)
                        : const Color(0xff00E676),
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _formatDate(date),
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
