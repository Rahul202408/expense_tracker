import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:provider/provider.dart';

import 'widgets/balance_card.dart';
import 'widgets/home_header.dart';
import 'widgets/quick_actions_bar.dart';
import 'widgets/budget_progress_card.dart';
import 'widgets/transaction_tile.dart';
import '../profile/profile_screen.dart';
import '../pro/pro_screen.dart';
import '../../providers/pro_provider.dart';

import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import 'widgets/empty_transaction.dart';
import '../../services/dashboard_service.dart';
import '../../services/notification_service.dart';
import '../transaction/add_transaction_screen.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/native_ad_widget.dart';
import '../../widgets/app_shimmer.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TransactionService _transactionService = TransactionService();
  final DashboardService _dashboardService = DashboardService();
  late Stream<List<TransactionModel>> _transactionStream;
  double _lastCheckedIncome = -1;
  double _lastCheckedExpense = -1;
  bool _isTimeoutElapsed = false;
  Timer? _loadingTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _transactionStream = _transactionService.getTransactions();
    _startSafetyTimer();
  }

  void _startSafetyTimer() {
    _loadingTimeoutTimer?.cancel();
    _isTimeoutElapsed = false;
    // Failsafe: Ensures loading shimmer NEVER runs infinitely, max 3.5 seconds
    _loadingTimeoutTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && !_isTimeoutElapsed) {
        setState(() {
          _isTimeoutElapsed = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _loadingTimeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    _startSafetyTimer();
    await _transactionService.fetchTransactionsOnce();
    if (mounted) {
      setState(() {
        _transactionStream = _transactionService.getTransactions();
      });
    }
  }

  Future<bool> _showDeleteConfirmDialog(
    BuildContext context,
    String title,
    bool isDark,
  ) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.55),
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
                  side: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                elevation: 16,
                insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xffEF4444).withValues(alpha: 0.22),
                              const Color(0xffF43F5E).withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xffEF4444).withValues(alpha: 0.25),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: Color(0xffEF4444),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "Delete Transaction?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: isDark ? Colors.white : const Color(0xff0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xff0F172A) : const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white10 : const Color(0xffE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 18,
                              color: isDark ? Colors.white70 : const Color(0xff64748B),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : const Color(0xff1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "This entry will be permanently removed from your records.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : const Color(0xff64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
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
                                  colors: [Color(0xffEF4444), Color(0xffDC2626)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xffEF4444).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(ctx, true),
                                icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.white),
                                label: const Text(
                                  "Delete",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
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
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xff0F172A) : const Color(0xffF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xff1E293B);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: const Color(0xff10B981),
          backgroundColor: isDark ? const Color(0xff1E293B) : Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
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
                  stream: _transactionStream,
                  initialData: TransactionService.cachedTransactions,
                  builder: (context, snapshot) {
                    // Beautiful Shimmer UI while loading initial data from Firebase (strictly capped at max 3.5s)
                    final bool isWaiting =
                        !_isTimeoutElapsed &&
                        ((snapshot.connectionState == ConnectionState.waiting &&
                                !snapshot.hasData) ||
                            (snapshot.data == null &&
                                TransactionService.cachedTransactions == null &&
                                !snapshot.hasError));

                    if (isWaiting) {
                      return const HomeDashboardSkeleton();
                    }

                    // Friendly error state if database fetch failed and no cached data exists
                    if (snapshot.hasError &&
                        (snapshot.data == null || snapshot.data!.isEmpty) &&
                        (TransactionService.cachedTransactions == null ||
                            TransactionService.cachedTransactions!.isEmpty)) {
                      return _buildErrorState(context, isDark);
                    }

                    final transactions = snapshot.data ??
                        TransactionService.cachedTransactions ??
                        [];
                    final income = _dashboardService.totalIncome(transactions);
                    final expense = _dashboardService.totalExpense(transactions);
                    final balance = _dashboardService.totalBalance(transactions);

                  // Check budget threshold alerts (80% / 100%) only when values change
                  if (expense != _lastCheckedExpense || income != _lastCheckedIncome) {
                    _lastCheckedExpense = expense;
                    _lastCheckedIncome = income;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      NotificationService().checkAndTriggerBudgetAlert(
                        expense: expense,
                        income: income,
                      );
                    });
                  }

                  // Take only the top 6 most recent transactions for the dashboard to guarantee 120 FPS
                  final recentTransactions = transactions.take(6).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3D Credit Card Balance (isolated with RepaintBoundary for smooth scrolling)
                      RepaintBoundary(
                        child: BalanceCard(
                          income: income,
                          expense: expense,
                          balance: balance,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quick Action Shortcuts Bar
                      QuickActionsBar(onNavigateTab: widget.onNavigateTab),

                      const SizedBox(height: 10),

                      // Pro Banner (shown only for free users)
                      Consumer<ProProvider>(
                        builder: (context, pro, _) {
                          if (pro.isPro) return const SizedBox.shrink();
                          return _buildProBanner(context);
                        },
                      ),

                      const SizedBox(height: 12),

                      // Budget Health Liquid Meter
                      RepaintBoundary(
                        child: BudgetProgressCard(
                          income: income,
                          expense: expense,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // AdMob Banner Ad (automatically hidden when Pro)
                      const BannerAdWidget(),

                      const SizedBox(height: 14),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Recent Transactions",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                            if (transactions.length > 6)
                              InkWell(
                                onTap: () {
                                  if (widget.onNavigateTab != null) {
                                    widget.onNavigateTab!(2);
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        "See All (${transactions.length})",
                                        style: const TextStyle(
                                          color: Color(0xFF6366F1),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 11,
                                        color: Color(0xFF6366F1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (transactions.isEmpty)
                        const EmptyTransaction()
                      else
                        Column(
                          children: [
                            for (int index = 0; index < recentTransactions.length; index++) ...[
                              Builder(
                                builder: (context) {
                                  final transaction = recentTransactions[index];
                                  final tileWidget = RepaintBoundary(
                                    child: Dismissible(
                                      key: Key(transaction.id),
                                      background: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade400,
                                          borderRadius: BorderRadius.circular(22),
                                        ),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 25),
                                        child: const Icon(
                                          Icons.delete_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (direction) async {
                                        return await _showDeleteConfirmDialog(
                                          context,
                                          transaction.title,
                                          isDark,
                                        );
                                      },
                                      onDismissed: (_) async {
                                        await _transactionService.deleteTransaction(
                                          transaction.id,
                                        );

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Transaction Deleted"),
                                              backgroundColor: Colors.redAccent,
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
                                    ),
                                  );

                                  if (index == 2) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        tileWidget,
                                        const NativeAdWidget(),
                                      ],
                                    );
                                  }

                                  return tileWidget;
                                },
                              ),
                            ],
                            if (transactions.isNotEmpty && transactions.length <= 2)
                              const NativeAdWidget(),
                            if (transactions.length > 6)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                                child: InkWell(
                                  onTap: () {
                                    if (widget.onNavigateTab != null) {
                                      widget.onNavigateTab!(2);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFEEF2F6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFCBD5E1),
                                        width: 0.8,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "View All ${transactions.length} Transactions",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? const Color(0xFF818CF8)
                                                : const Color(0xFF4F46E5),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 16,
                                          color: isDark
                                              ? const Color(0xFF818CF8)
                                              : const Color(0xFF4F46E5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                      const SizedBox(height: 125),
                    ],
                  );
                },
              ),
            ],
          ),
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

  Widget _buildProBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff1E293B), Color(0xff0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xffF59E0B).withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffF59E0B).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xffFBBF24), Color(0xffD97706)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upgrade to PRO 👑",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Remove Ads & Unlock PDF Statement",
                      style: TextStyle(
                        color: Color(0xff94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xffF59E0B), Color(0xffD97706)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "UPGRADE",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xffEF4444).withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xffEF4444).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xffEF4444),
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "Unable to load transactions",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xff0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Please check your internet connection or tap below to retry.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white60 : const Color(0xff64748B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _transactionStream = _transactionService.getTransactions();
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Retry Connection"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
