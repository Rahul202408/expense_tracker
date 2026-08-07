import 'package:flutter/material.dart';
import '../../../widgets/three_d_tilt_card.dart';
import 'summary_card.dart';

class BalanceCard extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;

  const BalanceCard({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return ThreeDTiltCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      maxTiltAngle: 0.15,
      elevation: 16,
      shadowColor: const Color(0xff0D47A1),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
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
            stops: [0.0, 0.5, 1.0],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Background 3D glass circles / shapes
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.tealAccent.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Card Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Colors.amberAccent,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Total Balance",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // SIM Chip visual decor
                    Container(
                      width: 36,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade300,
                            Colors.amber.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 28,
                          height: 18,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.amber.shade900.withValues(alpha: 0.5),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  "₹${balance.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        offset: Offset(0, 3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: "Income",
                        amount: "₹${income.toStringAsFixed(2)}",
                        icon: Icons.arrow_downward_rounded,
                        iconColor: const Color(0xff00E676),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: SummaryCard(
                        title: "Expense",
                        amount: "₹${expense.toStringAsFixed(2)}",
                        icon: Icons.arrow_upward_rounded,
                        iconColor: const Color(0xffFF5252),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
