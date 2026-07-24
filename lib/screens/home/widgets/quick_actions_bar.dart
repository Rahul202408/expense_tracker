import 'package:flutter/material.dart';
import '../../transaction/add_transaction_screen.dart';

class QuickActionsBar extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const QuickActionsBar({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final actions = [
      _ActionData(
        title: "Income",
        icon: Icons.add_rounded,
        gradient: const [Color(0xff11998E), Color(0xff38EF7D)],
        shadowColor: const Color(0xff11998E),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(initialIsExpense: false),
            ),
          );
        },
      ),
      _ActionData(
        title: "Expense",
        icon: Icons.remove_rounded,
        gradient: const [Color(0xffFF5252), Color(0xffFF1744)],
        shadowColor: Colors.redAccent,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(initialIsExpense: true),
            ),
          );
        },
      ),
      _ActionData(
        title: "Analytics",
        icon: Icons.analytics_rounded,
        gradient: const [Color(0xff1E3C72), Color(0xff2A5298)],
        shadowColor: const Color(0xff1E3C72),
        onTap: () {
          if (onNavigateTab != null) {
            onNavigateTab!(1);
          }
        },
      ),
      _ActionData(
        title: "Tips",
        icon: Icons.lightbulb_rounded,
        gradient: const [Color(0xffFF9800), Color(0xffFFC107)],
        shadowColor: Colors.orange,
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Row(
                children: [
                  Icon(Icons.lightbulb_rounded, color: Colors.amber),
                  SizedBox(width: 8),
                  Text("Financial Insight"),
                ],
              ),
              content: const Text(
                "💡 Pro Tip: Following the 50/30/20 rule helps build long-term savings!\n\n50% Needs, 30% Wants, 20% Savings.",
                style: TextStyle(fontSize: 15, height: 1.4),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Got it!"),
                ),
              ],
            ),
          );
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((act) {
          return GestureDetector(
            onTap: act.onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: act.gradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: act.shadowColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      act.icon,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  act.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xff2D3748),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionData {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final Color shadowColor;
  final VoidCallback onTap;

  const _ActionData({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.shadowColor,
    required this.onTap,
  });
}
