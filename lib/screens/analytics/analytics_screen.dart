import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/transaction_model.dart';
import '../../services/dashboard_service.dart';
import '../../services/transaction_service.dart';
import '../../providers/currency_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/export_service.dart';
import '../pro/pro_screen.dart';
import '../../providers/pro_provider.dart';
import '../transaction/add_transaction_screen.dart';
import 'widgets/analytics_hero_card.dart';
import 'widgets/category_spend_card.dart';
import 'widgets/expense_pie_chart.dart';
import 'widgets/spending_trend_bar_chart.dart';
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
  late Stream<List<TransactionModel>> _transactionStream;

  @override
  void initState() {
    super.initState();
    _transactionStream = _transactionService.getTransactions();
  }

  String _selectedPeriod = "All";
  final List<String> _periods = [
    "All",
    "This Month",
    "This Week",
    "This Year",
    "Custom 📅",
  ];
  DateTimeRange? _customDateRange;

  // View toggles
  bool _isExpenseView = true; // true = Expense, false = Income
  bool _isDonutView = true; // true = Donut Chart, false = Trend Bar Chart

  List<TransactionModel> _filterByPeriod(
    List<TransactionModel> list,
    String period,
  ) {
    if (period == "All" || period == "All Time") return list;
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
      } else if (period == "Custom 📅" && _customDateRange != null) {
        final start = DateTime(
          _customDateRange!.start.year,
          _customDateRange!.start.month,
          _customDateRange!.start.day,
        );
        final end = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
        );
        return !t.date.isBefore(start) && !t.date.isAfter(end);
      }
      return true;
    }).toList();
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 14)),
            end: now,
          ),
      builder: (ctx, child) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF6366F1),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF6366F1),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = "Custom 📅";
      });
    }
  }

  void _handleExportTap(
    BuildContext context,
    List<TransactionModel> filtered,
    String currencySymbol,
    bool isDark,
  ) {
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No transactions available to export for this period."),
          backgroundColor: Color(0xffEF4444),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final proProvider = Provider.of<ProProvider>(context, listen: false);
    if (!proProvider.isPro) {
      _showExportPaywall(context);
    } else {
      _showExportSheet(context, filtered, currencySymbol, isDark);
    }
  }

  void _showExportPaywall(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8 * anim.value,
            sigmaY: 8 * anim.value,
          ),
          child: ScaleTransition(
            scale: curvedAnim,
            child: FadeTransition(
              opacity: anim,
              child: Dialog(
                backgroundColor: isDark ? const Color(0xff1E293B) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                  side: const BorderSide(
                    color: Color(0xffF59E0B),
                    width: 1.3,
                  ),
                ),
                elevation: 20,
                insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xffF59E0B).withValues(alpha: 0.25),
                              const Color(0xffD97706).withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xffF59E0B).withValues(alpha: 0.35),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Color(0xffF59E0B),
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "PRO Feature",
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: isDark ? Colors.white : const Color(0xff0F172A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text("👑", style: TextStyle(fontSize: 20)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Exporting PDF statements and Excel spreadsheets is an exclusive PRO capability.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : const Color(0xff64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xffF59E0B).withValues(alpha: isDark ? 0.10 : 0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xffF59E0B).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildPaywallFeature(
                              icon: Icons.picture_as_pdf_rounded,
                              text: "Unlimited PDF & Excel Statements",
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildPaywallFeature(
                              icon: Icons.block_rounded,
                              text: "Zero Ads Experience",
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildPaywallFeature(
                              icon: Icons.fingerprint_rounded,
                              text: "PIN & Biometric App Lock",
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(
                                  color: isDark ? Colors.white24 : const Color(0xffCBD5E1),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white70 : const Color(0xff475569),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [Color(0xffF59E0B), Color(0xffD97706)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xffF59E0B).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ProScreen()),
                                  );
                                },
                                icon: const Icon(Icons.star_rounded, size: 18, color: Colors.black87),
                                label: const Text(
                                  "Unlock PRO",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaywallFeature({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xffF59E0B), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xff1E293B),
            ),
          ),
        ),
      ],
    );
  }

  void _showExportSheet(
    BuildContext context,
    List<TransactionModel> transactions,
    String currencySymbol,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "Export Financial Report",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xff0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Period: $_selectedPeriod • ${transactions.length} Records",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xff64748B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? Colors.white10 : const Color(0xffE2E8F0),
                      ),
                    ),
                    tileColor: isDark ? const Color(0xff0F172A) : const Color(0xffF8FAFC),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xffEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xffEF4444)),
                    ),
                    title: const Text(
                      "PDF Document",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      "Print-ready structured summary with categories & totals",
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ExportService().exportToPdf(
                        transactions: transactions,
                        currencySymbol: currencySymbol,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? Colors.white10 : const Color(0xffE2E8F0),
                      ),
                    ),
                    tileColor: isDark ? const Color(0xff0F172A) : const Color(0xffF8FAFC),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xff10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.table_chart_rounded, color: Color(0xff10B981)),
                    ),
                    title: const Text(
                      "CSV Spreadsheet (Excel)",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      "Compatible with Microsoft Excel, Google Sheets & Numbers",
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ExportService().exportToCsv(
                        transactions: transactions,
                        currencySymbol: currencySymbol,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
        actions: [
          StreamBuilder<List<TransactionModel>>(
            stream: _transactionStream,
            initialData: TransactionService.cachedTransactions,
            builder: (context, snap) {
              final all = snap.data ?? TransactionService.cachedTransactions ?? [];
              final filtered = _filterByPeriod(all, _selectedPeriod);
              return IconButton(
                tooltip: "Export Report",
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.ios_share_rounded,
                    size: 18,
                    color: isDark ? Colors.white : const Color(0xff0F172A),
                  ),
                ),
                onPressed: () => _handleExportTap(context, filtered, currencySymbol, isDark),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: StreamBuilder<List<TransactionModel>>(
        stream: _transactionStream,
        initialData: TransactionService.cachedTransactions,
        builder: (context, snapshot) {
          final bool isWaiting =
              (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) ||
                  (snapshot.data == null &&
                      TransactionService.cachedTransactions == null &&
                      !snapshot.hasError);

          if (isWaiting) {
            return const AnalyticsSkeleton();
          }

          final allTransactions = snapshot.data ??
              TransactionService.cachedTransactions ??
              [];
          final transactions = _filterByPeriod(allTransactions, _selectedPeriod);

          final income = _dashboardService.totalIncome(transactions);
          final expense = _dashboardService.totalExpense(transactions);
          final balance = _dashboardService.totalBalance(transactions);

          final incomeCount = transactions.where((t) => !t.isExpense).length;
          final expenseCount = transactions.where((t) => t.isExpense).length;

          // Category data filtered by Expense or Income
          final categoryData = _analyticsService.categoryTotals(
            transactions,
            isExpense: _isExpenseView,
          );

          // Count transactions per category
          final Map<String, int> categoryCounts = {};
          for (final t in transactions) {
            if (t.isExpense == _isExpenseView) {
              categoryCounts[t.category] = (categoryCounts[t.category] ?? 0) + 1;
            }
          }

          // Sort categories by highest spend / earnings descending
          final sortedCategories = categoryData.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // Quick stats calculation
          final totalTargetVolume = _isExpenseView ? expense : income;
          final topCategoryName = sortedCategories.isNotEmpty ? sortedCategories.first.key : "None";
          final topCategoryPct = (totalTargetVolume > 0 && sortedCategories.isNotEmpty)
              ? (sortedCategories.first.value / totalTargetVolume * 100).toStringAsFixed(0)
              : "0";

          // Calculate daily average
          final now = DateTime.now();
          int dayDivisor = 1;
          if (_selectedPeriod == "This Week") {
            dayDivisor = now.weekday;
          } else if (_selectedPeriod == "This Month") {
            dayDivisor = now.day;
          } else if (_selectedPeriod == "This Year") {
            dayDivisor = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
          } else if (_selectedPeriod == "Custom 📅" && _customDateRange != null) {
            dayDivisor = (_customDateRange!.duration.inDays + 1).clamp(1, 365);
          } else {
            dayDivisor = 30;
          }
          final dailyAverage = totalTargetVolume / dayDivisor.clamp(1, 365);

          // Financial score (0 - 100)
          int healthScore = 75;
          String healthStatus = "Good";
          Color healthColor = const Color(0xFF10B981);
          if (income == 0 && expense == 0) {
            healthScore = 50;
            healthStatus = "Neutral";
            healthColor = const Color(0xFF6366F1);
          } else if (income > 0) {
            final double savingsRate = ((income - expense) / income).clamp(-1.0, 1.0);
            if (savingsRate >= 0.3) {
              healthScore = (70 + (savingsRate * 30)).round().clamp(70, 100);
              healthStatus = "Excellent";
              healthColor = const Color(0xFF10B981);
            } else if (savingsRate >= 0.0) {
              healthScore = (50 + (savingsRate * 60)).round().clamp(50, 70);
              healthStatus = "Balanced";
              healthColor = const Color(0xFFF59E0B);
            } else {
              healthScore = (50 + (savingsRate * 50)).round().clamp(10, 49);
              healthStatus = "Caution";
              healthColor = const Color(0xFFEF4444);
            }
          } else {
            healthScore = 40;
            healthStatus = "Caution";
            healthColor = const Color(0xFFEF4444);
          }

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

                const SizedBox(height: 12),

                // 3. Smart Quick Stats 3-Card Row (Financial Score, Daily Average, Top Category)
                _buildQuickStatsRow(
                  isDark: isDark,
                  healthScore: healthScore,
                  healthStatus: healthStatus,
                  healthColor: healthColor,
                  dailyAverage: dailyAverage,
                  currencySymbol: currencySymbol,
                  topCategory: topCategoryName,
                  topCategoryPct: topCategoryPct,
                ),

                const SizedBox(height: 12),

                // 4. Smart Financial Insight Banner
                _buildInsightBanner(
                  isDark: isDark,
                  income: income,
                  expense: expense,
                  currencySymbol: currencySymbol,
                ),

                const SizedBox(height: 18),

                // 5. Segmented Type Switcher: [ Expenses ] ↔ [ Income ]
                _buildTypeSwitcher(isDark),

                const SizedBox(height: 18),

                // 6. Section Header with Dual Chart Toggle (Donut vs Bar Chart)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isExpenseView ? "Spending by Category" : "Income by Category",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (sortedCategories.isNotEmpty)
                          Text(
                            "${sortedCategories.length} Categories • $currencySymbol${totalTargetVolume.toStringAsFixed(0)} Total",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),

                    // Chart View Toggle (Donut vs Trend Bar)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _isDonutView = true),
                            borderRadius: BorderRadius.circular(11),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isDonutView
                                    ? (_isExpenseView ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                Icons.donut_large_rounded,
                                size: 17,
                                color: _isDonutView ? Colors.white : Colors.grey,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() => _isDonutView = false),
                            borderRadius: BorderRadius.circular(11),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: !_isDonutView
                                    ? (_isExpenseView ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                Icons.bar_chart_rounded,
                                size: 17,
                                color: !_isDonutView ? Colors.white : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 7. Interactive Chart: Donut or Trend Bar
                if (categoryData.isNotEmpty)
                  RepaintBoundary(
                    child: _isDonutView
                        ? ExpensePieChart(
                            categoryData: categoryData,
                            currencySymbol: currencySymbol,
                            isExpense: _isExpenseView,
                          )
                        : SpendingTrendBarChart(
                            transactions: transactions,
                            period: _selectedPeriod,
                            isExpense: _isExpenseView,
                            currencySymbol: currencySymbol,
                          ),
                  ),

                const SizedBox(height: 14),

                // 8. Ranked Category Cards
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
                      totalExpense: totalTargetVolume,
                      count: count,
                      currencySymbol: currencySymbol,
                      rank: rank,
                      isExpense: _isExpenseView,
                    );
                  }),

                const SizedBox(height: 125),
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

          String displayText = period;
          if (period == "Custom 📅" && _customDateRange != null) {
            final start = DateFormat('dd MMM').format(_customDateRange!.start);
            final end = DateFormat('dd MMM').format(_customDateRange!.end);
            displayText = "$start - $end";
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                if (period == "Custom 📅") {
                  _pickCustomDateRange();
                } else {
                  setState(() {
                    _selectedPeriod = period;
                  });
                }
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
                  displayText,
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

  Widget _buildTypeSwitcher(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff1E293B) : const Color(0xffF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xffE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isExpenseView = true),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: _isExpenseView
                      ? const LinearGradient(
                          colors: [Color(0xffEF4444), Color(0xffDC2626)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isExpenseView
                      ? [
                          BoxShadow(
                            color: const Color(0xffEF4444).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 16,
                      color: _isExpenseView ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Expenses",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _isExpenseView
                            ? Colors.white
                            : (isDark ? Colors.white60 : Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isExpenseView = false),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: !_isExpenseView
                      ? const LinearGradient(
                          colors: [Color(0xff10B981), Color(0xff059669)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isExpenseView
                      ? [
                          BoxShadow(
                            color: const Color(0xff10B981).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 16,
                      color: !_isExpenseView ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Income",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: !_isExpenseView
                            ? Colors.white
                            : (isDark ? Colors.white60 : Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow({
    required bool isDark,
    required int healthScore,
    required String healthStatus,
    required Color healthColor,
    required double dailyAverage,
    required String currencySymbol,
    required String topCategory,
    required String topCategoryPct,
  }) {
    return Row(
      children: [
        // Health Score
        Expanded(
          child: _buildMiniStatCard(
            isDark: isDark,
            icon: Icons.speed_rounded,
            color: healthColor,
            title: "Score",
            value: "$healthScore/100",
            subtitle: healthStatus,
          ),
        ),
        const SizedBox(width: 8),

        // Daily Average
        Expanded(
          child: _buildMiniStatCard(
            isDark: isDark,
            icon: Icons.calendar_today_rounded,
            color: const Color(0xFF6366F1),
            title: "Daily Avg",
            value: "$currencySymbol${dailyAverage.toStringAsFixed(0)}",
            subtitle: "per day",
          ),
        ),
        const SizedBox(width: 8),

        // Top Category
        Expanded(
          child: _buildMiniStatCard(
            isDark: isDark,
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFFF7A00),
            title: "Top Category",
            value: topCategory.length > 7 ? "${topCategory.substring(0, 7)}.." : topCategory,
            subtitle: "$topCategoryPct% of total",
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
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
    final typeName = _isExpenseView ? "Expenses" : "Income";
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
            "No $typeName in $_selectedPeriod",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Add $typeName to view category breakdowns and analytics graphs.",
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
            label: Text(
              "Add $typeName",
              style: const TextStyle(fontWeight: FontWeight.w700),
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
