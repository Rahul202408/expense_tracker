import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction_model.dart';
import '../../services/dashboard_service.dart';
import '../../services/transaction_service.dart';
import '../../providers/currency_provider.dart';
import '../../services/analytics_service.dart';
import '../transaction/add_transaction_screen.dart';
import 'widgets/analytics_hero_card.dart';
import 'widgets/category_spend_card.dart';
import 'widgets/expense_pie_chart.dart';
import '../../widgets/app_shimmer.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final TransactionService _transactionService = TransactionService();
  final DashboardService _dashboardService = DashboardService();
  final AnalyticsService _analyticsService = AnalyticsService();

  String _selectedPeriod = "This Month";
  final List<String> _periods = ["This Month", "This Week", "This Year", "All Time"];

  List<TransactionModel> _filterByPeriod(
    List<TransactionModel> list,
    String period,
  ) {
    if (period == "All Time") return list;
    final now = DateTime.now();

    return list.where((t) {
      if (period == "This Week") {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final end = start.add(const Duration(days: 7));
        return !t.date.isBefore(start) && t.date.isBefore(end);
      } else if (period == "This Month") {
        return t.date.year == now.year && t.date.month == now.month;
      } else if (period == "This Year") {
        return t.date.year == now.year;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = Provider.of<CurrencyProvider>(context).symbol;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Financial Analytics",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: StreamBuilder<List<TransactionModel>>(
        stream: _transactionService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const AnalyticsSkeleton();
          }

          final allTransactions = snapshot.data ?? [];
          final transactions = _filterByPeriod(allTransactions, _selectedPeriod);

          final income = _dashboardService.totalIncome(transactions);
          final expense = _dashboardService.totalExpense(transactions);
          final balance = _dashboardService.totalBalance(transactions);

          final incomeCount = transactions.where((t) => !t.isExpense).length;
          final expenseCount = transactions.where((t) => t.isExpense).length;

          final categoryData = _analyticsService.categoryTotals(transactions);

          // Count transactions per category
          final Map<String, int> categoryCounts = {};
          for (final t in transactions) {
            if (t.isExpense) {
              categoryCounts[t.category] = (categoryCounts[t.category] ?? 0) + 1;
            }
          }

          // Sort categories by highest spend descending
          final sortedCategories = categoryData.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Time Period Segmented Filter Pills
                _buildPeriodFilter(isDark),

                const SizedBox(height: 14),

                // 2. Executive Financial Overview Hero Card
                RepaintBoundary(
                  child: AnalyticsHeroCard(
                    income: income,
                    expense: expense,
                    balance: balance,
                    incomeCount: incomeCount,
                    expenseCount: expenseCount,
                    currencySymbol: currencySymbol,
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Smart Financial Insight Banner
                _buildInsightBanner(
                  isDark: isDark,
                  income: income,
                  expense: expense,
                  currencySymbol: currencySymbol,
                ),

                const SizedBox(height: 22),

                // 4. Section Header: Category Breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Spending by Category",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (sortedCategories.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${sortedCategories.length} Categories",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // 5. Interactive Pie Chart
                if (categoryData.isNotEmpty)
                  RepaintBoundary(
                    child: ExpensePieChart(
                      categoryData: categoryData,
                      currencySymbol: currencySymbol,
                    ),
                  ),

                const SizedBox(height: 14),

                // 6. Ranked Category Spending Cards
                if (sortedCategories.isEmpty)
                  _buildEmptyState(isDark)
                else
                  ...sortedCategories.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final catEntry = entry.value;
                    final count = categoryCounts[catEntry.key] ?? 1;

                    return CategorySpendCard(
                      category: catEntry.key,
                      amount: catEntry.value,
                      totalExpense: expense,
                      count: count,
                      currencySymbol: currencySymbol,
                      rank: rank,
                    );
                  }),

                const SizedBox(height: 90),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodFilter(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.65)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0)),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  period,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey.shade300 : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightBanner({
    required bool isDark,
    required double income,
    required double expense,
    required String currencySymbol,
  }) {
    String message;
    IconData icon;
    Color accentColor;

    if (income == 0 && expense == 0) {
      message = "No transactions found for $_selectedPeriod. Start logging expenses to track analytics.";
      icon = Icons.insights_rounded;
      accentColor = const Color(0xFF6366F1);
    } else if (income > 0 && expense <= income) {
      final pct = ((income - expense) / income * 100).toStringAsFixed(0);
      message = "Great financial health! You saved $pct% of your total earnings in $_selectedPeriod.";
      icon = Icons.verified_rounded;
      accentColor = const Color(0xFF10B981);
    } else if (income > 0 && expense > income) {
      final over = (expense - income).toStringAsFixed(0);
      message = "Spending alert: Expenses exceeded earnings by $currencySymbol$over in $_selectedPeriod.";
      icon = Icons.warning_amber_rounded;
      accentColor = const Color(0xFFEF4444);
    } else {
      message = "Total outflow in $_selectedPeriod is $currencySymbol${expense.toStringAsFixed(2)}. Add income to track savings rate.";
      icon = Icons.info_outline_rounded;
      accentColor = const Color(0xFFF59E0B);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade200 : const Color(0xFF1E293B),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.85),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.2 : 0.1),
            ),
            child: const Icon(
              Icons.pie_chart_outline_rounded,
              color: Color(0xFF6366F1),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "No Expenses in $_selectedPeriod",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Add expenses to view category breakdowns and analytics graphs.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              "Add Expense",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
