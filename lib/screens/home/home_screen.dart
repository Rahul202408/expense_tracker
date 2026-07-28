import 'package:flutter/material.dart';

import 'widgets/balance_card.dart';
import 'widgets/home_header.dart';
import 'widgets/quick_actions_bar.dart';
import 'widgets/budget_progress_card.dart';
import 'widgets/transaction_tile.dart';
import '../profile/profile_screen.dart';

import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import 'widgets/empty_transaction.dart';
import '../../services/dashboard_service.dart';
import '../transaction/add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TransactionService _transactionService = TransactionService();
  final DashboardService _dashboardService = DashboardService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xff1A202C);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Header with Profile Avatar tap callback
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: HomeHeader(
                  onProfileTap: () {
                    if (widget.onNavigateTab != null) {
                      widget.onNavigateTab!(3);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 12),

              StreamBuilder<List<TransactionModel>>(
                stream: _transactionService.getTransactions(),
                builder: (context, snapshot) {
                  final transactions = snapshot.data ?? [];
                  final income = _dashboardService.totalIncome(transactions);
                  final expense = _dashboardService.totalExpense(transactions);
                  final balance = _dashboardService.totalBalance(transactions);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3D Credit Card Balance
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: BalanceCard(
                          income: income,
                          expense: expense,
                          balance: balance,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quick Action Shortcuts Bar
                      QuickActionsBar(onNavigateTab: widget.onNavigateTab),

                      const SizedBox(height: 12),

                      // Budget Health Liquid Meter
                      BudgetProgressCard(
                        income: income,
                        expense: expense,
                      ),

                      const SizedBox(height: 14),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          "Recent Transactions",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (transactions.isEmpty)
                        const EmptyTransaction()
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];

                            return Dismissible(
                              key: Key(transaction.id),
                              onDismissed: (_) async {
                                await _transactionService.deleteTransaction(
                                  transaction.id,
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Transaction Deleted"),
                                    ),
                                  );
                                }
                              },
                              child: TransactionTile(
                                icon: _getCategoryIcon(transaction.category),
                                iconColor: transaction.isExpense
                                    ? Colors.red
                                    : Colors.green,
                                title: transaction.title,
                                category: transaction.category,
                                amount: transaction.amount.toStringAsFixed(2),
                                isExpense: transaction.isExpense,
                                date: transaction.date,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddTransactionScreen(
                                        transaction: transaction,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 110),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Travel':
        return Icons.flight_takeoff_rounded;
      case 'Salary':
        return Icons.account_balance_wallet_rounded;
      case 'Bills':
        return Icons.receipt_long_rounded;
      case 'Health':
        return Icons.medical_services_rounded;
      case 'Education':
        return Icons.school_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
