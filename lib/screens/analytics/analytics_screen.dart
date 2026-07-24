import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';
import '../../services/dashboard_service.dart';
import '../../services/transaction_service.dart';

import '../../services/analytics_service.dart';
import 'widgets/expense_pie_chart.dart';

import 'widgets/analytics_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactionService = TransactionService();
    final dashboardService = DashboardService();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Analytics"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: StreamBuilder<List<TransactionModel>>(
        stream: transactionService.getTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data!;

          final income = dashboardService.totalIncome(transactions);

          final expense = dashboardService.totalExpense(transactions);

          final balance = dashboardService.totalBalance(transactions);

          final analyticsService = AnalyticsService();
          final categoryData = analyticsService.categoryTotals(transactions);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                AnalyticsCard(
                  title: "Total Income",
                  amount: "₹ ${income.toStringAsFixed(2)}",
                  icon: Icons.arrow_downward,
                  color: Colors.green,
                ),

                AnalyticsCard(
                  title: "Total Expense",
                  amount: "₹ ${expense.toStringAsFixed(2)}",
                  icon: Icons.arrow_upward,
                  color: Colors.red,
                ),

                AnalyticsCard(
                  title: "Savings",
                  amount: "₹ ${balance.toStringAsFixed(2)}",
                  icon: Icons.account_balance_wallet,
                  color: Colors.blue,
                ),

                const SizedBox(height: 30),

                Text(
                  "Category Analytics",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xff1A202C),
                  ),
                ),
                ExpensePieChart(categoryData: categoryData),

                const SizedBox(height: 20),

                ...categoryData.entries.toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  final colors = [
                    Colors.blue,
                    Colors.red,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.teal,
                    Colors.pink,
                    Colors.amber,
                  ];

                  return Card(
                    color: isDark ? const Color(0xff1E293B) : Colors.white,
                    elevation: isDark ? 2 : 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                      ),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 8,
                        backgroundColor: colors[index % colors.length],
                      ),
                      title: Text(
                        item.key,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xff2D3748),
                        ),
                      ),
                      trailing: Text(
                        "₹ ${item.value.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xff38EF7D) : const Color(0xff1E3C72),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 25),
              ],
            ),
          );
        },
      ),
    );
  }
}
