import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../widgets/three_d_tilt_card.dart';

class AnalyticsHeroCard extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;
  final int incomeCount;
  final int expenseCount;
  final String currencySymbol;

  const AnalyticsHeroCard({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
    required this.incomeCount,
    required this.expenseCount,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Savings rate calculation (Income saved percentage)
    final double savingsRate = income > 0 ? ((income - expense) / income) * 100 : 0.0;
    final bool isSurplus = balance >= 0;

    // Income vs Expense ratio for the cash flow bar
    final double totalVolume = income + expense;
    final double incomeFraction = totalVolume > 0 ? (income / totalVolume).clamp(0.0, 1.0) : 0.5;
    final double expenseFraction = totalVolume > 0 ? (expense / totalVolume).clamp(0.0, 1.0) : 0.5;

    return ThreeDTiltCard(
      margin: const EdgeInsets.symmetric(vertical: 8),
      maxTiltAngle: 0.05,
      elevation: isDark ? 4 : 8,
      shadowColor: isSurplus
          ? const Color(0xFF10B981).withValues(alpha: 0.25)
          : const Color(0xFFEF4444).withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.02),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.75),
                        Colors.white.withValues(alpha: 0.35),
                      ],
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : const Color(0xFF6366F1).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Ambient Glowing Glass Orbs
                Positioned(
                  top: -24,
                  right: -24,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.14 : 0.09),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -24,
                  left: -24,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isSurplus ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                          .withValues(alpha: isDark ? 0.12 : 0.08),
                    ),
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // Top Row: Net Cash Flow Label & Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFF6366F1),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "NET SAVINGS",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                // Savings Rate Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSurplus
                        ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12)
                        : const Color(0xFFEF4444).withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSurplus
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : const Color(0xFFEF4444).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSurplus
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: isSurplus
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSurplus
                            ? "+${savingsRate.toStringAsFixed(1)}% Saved"
                            : "${savingsRate.toStringAsFixed(1)}% Deficit",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isSurplus
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Big Bold Net Balance
            Text(
              "${isSurplus ? '+' : '-'}$currencySymbol ${balance.abs().toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: isSurplus
                    ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                    : const Color(0xFFEF4444),
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 16),

            // Visual Cash Flow Ratio Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Cash Flow Ratio",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      totalVolume > 0
                          ? "${(incomeFraction * 100).toStringAsFixed(0)}% In / ${(expenseFraction * 100).toStringAsFixed(0)}% Out"
                          : "No activity",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 8,
                    child: totalVolume > 0
                        ? Row(
                            children: [
                              Expanded(
                                flex: (incomeFraction * 100).toInt(),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                flex: (expenseFraction * 100).toInt(),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Bottom Dual Pods: Total Income & Total Expense
            Row(
              children: [
                // Total Income Pod
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.08 : 0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.22 : 0.25),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "INCOME",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: isDark
                                    ? const Color(0xFF6EE7B7)
                                    : const Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "+$currencySymbol ${income.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF065F46),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$incomeCount deposits",
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade400
                                : const Color(0xFF047857).withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Total Expense Pod
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.08 : 0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.22 : 0.25),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "EXPENSE",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: isDark
                                    ? const Color(0xFFFCA5A5)
                                    : const Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "-$currencySymbol ${expense.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFFF87171)
                                : const Color(0xFF991B1B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$expenseCount expenses",
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade400
                                : const Color(0xFFB91C1C).withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
