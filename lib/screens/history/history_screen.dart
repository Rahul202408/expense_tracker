import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../home/widgets/transaction_tile.dart';
import '../../widgets/three_d_tilt_card.dart';
import '../transaction/add_transaction_screen.dart';
import '../../widgets/native_ad_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum SortOption { newest, oldest, highestAmount, lowestAmount }
enum TypeFilter { all, expense, income }

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController searchController = TextEditingController();
  final TransactionService _transactionService = TransactionService();
  String searchText = "";
  String selectedCategory = "All";
  String selectedDateFilter = "All";
  TypeFilter selectedTypeFilter = TypeFilter.all;
  SortOption selectedSortOption = SortOption.newest;

  final List<String> dateFilters = ["All", "Today", "This Week", "This Month"];
  final List<String> categories = [
    "All",
    "Food",
    "Shopping",
    "Travel",
    "Bills",
    "Salary",
    "Health",
    "Education",
    "Entertainment",
    "Other",
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

  void _showSortBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xff1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Sort Transactions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xff1A202C),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildSortOptionTile(
                "Newest First",
                Icons.schedule_rounded,
                SortOption.newest,
                isDark,
              ),
              _buildSortOptionTile(
                "Oldest First",
                Icons.history_rounded,
                SortOption.oldest,
                isDark,
              ),
              _buildSortOptionTile(
                "Highest Amount",
                Icons.arrow_upward_rounded,
                SortOption.highestAmount,
                isDark,
              ),
              _buildSortOptionTile(
                "Lowest Amount",
                Icons.arrow_downward_rounded,
                SortOption.lowestAmount,
                isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOptionTile(
    String title,
    IconData icon,
    SortOption option,
    bool isDark,
  ) {
    final isSelected = selectedSortOption == option;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? const Color(0xff11998E)
            : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? const Color(0xff11998E)
              : (isDark ? Colors.white : const Color(0xff2D3748)),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xff11998E))
          : null,
      onTap: () {
        setState(() {
          selectedSortOption = option;
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xff1A202C);
    final cardBgColor = isDark ? const Color(0xff1E293B) : Colors.white;
    final inputTextColor = isDark ? Colors.white : const Color(0xff2D3748);
    final chipUnselectedTextColor =
        isDark ? Colors.grey.shade300 : const Color(0xff4A5568);
    final chipUnselectedBorderColor =
        isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Transaction History",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.swap_vert_rounded,
              color: isDark ? const Color(0xff38EF7D) : const Color(0xff1E3C72),
            ),
            onPressed: () => _showSortBottomSheet(context, isDark),
            tooltip: "Sort",
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _transactionService.getTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = snapshot.data ?? [];
                final now = DateTime.now();

                // Filtering logic
                final filteredTransactions = transactions.where((t) {
                  final matchesSearch =
                      t.title.toLowerCase().contains(searchText) ||
                      t.category.toLowerCase().contains(searchText);

                  final matchesCategory =
                      selectedCategory == "All" || t.category == selectedCategory;

                  bool matchesType = true;
                  if (selectedTypeFilter == TypeFilter.expense) {
                    matchesType = t.isExpense;
                  } else if (selectedTypeFilter == TypeFilter.income) {
                    matchesType = !t.isExpense;
                  }

                  bool matchesDate = true;
                  if (selectedDateFilter == "Today") {
                    matchesDate =
                        t.date.year == now.year &&
                        t.date.month == now.month &&
                        t.date.day == now.day;
                  } else if (selectedDateFilter == "This Week") {
                    final startOfWeek =
                        now.subtract(Duration(days: now.weekday - 1));
                    final endOfWeek = startOfWeek.add(const Duration(days: 6));
                    matchesDate =
                        !t.date.isBefore(startOfWeek) &&
                        !t.date.isAfter(endOfWeek);
                  } else if (selectedDateFilter == "This Month") {
                    matchesDate =
                        t.date.year == now.year && t.date.month == now.month;
                  }

                  return matchesSearch &&
                      matchesCategory &&
                      matchesType &&
                      matchesDate;
                }).toList();

                // Sorting logic
                filteredTransactions.sort((a, b) {
                  switch (selectedSortOption) {
                    case SortOption.newest:
                      return b.date.compareTo(a.date);
                    case SortOption.oldest:
                      return a.date.compareTo(b.date);
                    case SortOption.highestAmount:
                      return b.amount.compareTo(a.amount);
                    case SortOption.lowestAmount:
                      return a.amount.compareTo(b.amount);
                  }
                });

                // Calculate Totals for Summary Banner
                double totalIncome = 0;
                double totalExpense = 0;
                for (var t in filteredTransactions) {
                  if (t.isExpense) {
                    totalExpense += t.amount;
                  } else {
                    totalIncome += t.amount;
                  }
                }
                double netBalance = totalIncome - totalExpense;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Summary Header Card - Super 3D View
                            ThreeDTiltCard(
                              margin: const EdgeInsets.only(bottom: 20),
                              maxTiltAngle: 0.08,
                              elevation: isDark ? 8 : 12,
                              shadowColor: isDark
                                  ? const Color(0xff11998E).withValues(alpha: 0.5)
                                  : const Color(0xff00B4DB).withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(26),
                              child: Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isDark
                                        ? [
                                            const Color(0xff0F2027),
                                            const Color(0xff203A43),
                                            const Color(0xff2C5364),
                                          ]
                                        : [
                                            const Color(0xff11998E),
                                            const Color(0xff00B4DB),
                                            const Color(0xff0083B0),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? const Color(0xff11998E).withValues(alpha: 0.3)
                                          : const Color(0xff0083B0).withValues(alpha: 0.35),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // 3D Background Glowing Orbs
                                    Positioned(
                                      right: -30,
                                      top: -30,
                                      child: Container(
                                        width: 140,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              Colors.white.withValues(alpha: 0.2),
                                              Colors.white.withValues(alpha: 0.0),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: -20,
                                      bottom: -40,
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              const Color(0xff38EF7D).withValues(alpha: 0.25),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Main Content
                                    Padding(
                                      padding: const EdgeInsets.all(20),
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
                                                      color: Colors.white.withValues(alpha: 0.2),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Colors.white.withValues(alpha: 0.3),
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.account_balance_wallet_rounded,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  const Text(
                                                    "Filtered Balance",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: Colors.white.withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Text(
                                                  "${filteredTransactions.length} Items",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            "₹${netBalance.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.6,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black26,
                                                  blurRadius: 8,
                                                  offset: Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Glassmorphic Income & Expense Box
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.25),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: _buildSummaryMetric(
                                                    "Income",
                                                    "+ ₹${totalIncome.toStringAsFixed(2)}",
                                                    const Color(0xff00E676),
                                                    Icons.arrow_downward_rounded,
                                                  ),
                                                ),
                                                Container(
                                                  width: 1,
                                                  height: 32,
                                                  color: Colors.white.withValues(alpha: 0.25),
                                                ),
                                                Expanded(
                                                  child: _buildSummaryMetric(
                                                    "Expenses",
                                                    "- ₹${totalExpense.toStringAsFixed(2)}",
                                                    const Color(0xffFF5252),
                                                    Icons.arrow_upward_rounded,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 2. Search Field
                            Container(
                              decoration: BoxDecoration(
                                color: cardBgColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: isDark ? 0.2 : 0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: TextField(
                                controller: searchController,
                                onChanged: (value) {
                                  setState(() {
                                    searchText = value.toLowerCase();
                                  });
                                },
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: inputTextColor,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Search title or category...",
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: isDark
                                        ? const Color(0xff38EF7D)
                                        : const Color(0xff1E3C72),
                                  ),
                                  suffixIcon: searchText.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded,
                                              size: 18),
                                          onPressed: () {
                                            searchController.clear();
                                            setState(() {
                                              searchText = "";
                                            });
                                          },
                                        )
                                      : null,
                                  filled: false,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // 3. Type Segment Filter (All, Expense, Income)
                            Row(
                              children: [
                                _buildTypeFilterChip(
                                  "All",
                                  TypeFilter.all,
                                  isDark,
                                ),
                                const SizedBox(width: 8),
                                _buildTypeFilterChip(
                                  "Expenses",
                                  TypeFilter.expense,
                                  isDark,
                                ),
                                const SizedBox(width: 8),
                                _buildTypeFilterChip(
                                  "Income",
                                  TypeFilter.income,
                                  isDark,
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // 4. Categories Filter Pills
                            Text(
                              "Categories",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color:
                                    isDark ? Colors.grey.shade400 : Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),

                            const SizedBox(height: 8),

                            SizedBox(
                              height: 38,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  final isSelected =
                                      selectedCategory == category;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedCategory = category;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xff1E3C72),
                                                  Color(0xff2A5298)
                                                ],
                                              )
                                            : null,
                                        color: isSelected ? null : cardBgColor,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.transparent
                                              : chipUnselectedBorderColor,
                                        ),
                                      ),
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : chipUnselectedTextColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 14),

                            // 5. Date Range Filter Pills
                            Text(
                              "Date Range",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color:
                                    isDark ? Colors.grey.shade400 : Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),

                            const SizedBox(height: 8),

                            SizedBox(
                              height: 38,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: dateFilters.length,
                                itemBuilder: (context, index) {
                                  final filter = dateFilters[index];
                                  final isSelected =
                                      selectedDateFilter == filter;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedDateFilter = filter;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xff11998E),
                                                  Color(0xff38EF7D)
                                                ],
                                              )
                                            : null,
                                        color: isSelected ? null : cardBgColor,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.transparent
                                              : chipUnselectedBorderColor,
                                        ),
                                      ),
                                      child: Text(
                                        filter,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : chipUnselectedTextColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // List of Filtered Transactions
                    if (filteredTransactions.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(
                          transactions.isEmpty
                              ? "No History Yet"
                              : "No Matching Transactions",
                          transactions.isEmpty
                              ? "You haven't added any transactions yet. Tap the button below to start tracking your expenses!"
                              : "No transactions found matching your selected search or filter criteria.",
                          isDark,
                          isNewUser: transactions.isEmpty,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final transaction = filteredTransactions[index];

                              final tileWidget = Dismissible(
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
                                onDismissed: (_) async {
                                  await _transactionService
                                      .deleteTransaction(transaction.id);
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
                                      ? const Color(0xffE53935)
                                      : const Color(0xff43A047),
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

                              // Insert Native Ad after 3rd item or at the end if fewer items
                              if (index == 2 ||
                                  (index == filteredTransactions.length - 1 &&
                                      filteredTransactions.length <= 2)) {
                                return Column(
                                  children: [
                                    tileWidget,
                                    const NativeAdWidget(),
                                  ],
                                );
                              }

                              return tileWidget;
                            },
                            childCount: filteredTransactions.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFilterChip(String label, TypeFilter filter, bool isDark) {
    final isSelected = selectedTypeFilter == filter;
    Color activeColor = const Color(0xff11998E);
    if (filter == TypeFilter.expense) activeColor = const Color(0xffE53935);
    if (filter == TypeFilter.income) activeColor = const Color(0xff43A047);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTypeFilter = filter;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor
                : (isDark ? const Color(0xff1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.grey.shade300),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey.shade300 : const Color(0xff4A5568)),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, bool isDark, {required bool isNewUser}) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 60, left: 24, right: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xff1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xff11998E).withValues(alpha: 0.25),
                            const Color(0xff38EF7D).withValues(alpha: 0.1),
                          ]
                        : [
                            const Color(0xffE0F2FE),
                            const Color(0xffBAE6FD),
                          ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xff38EF7D).withValues(alpha: 0.3)
                        : const Color(0xff0284C7).withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  isNewUser
                      ? Icons.receipt_long_rounded
                      : Icons.filter_alt_off_rounded,
                  size: 44,
                  color: isDark ? const Color(0xff38EF7D) : const Color(0xff0284C7),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xff1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              if (isNewUser) ...[
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddTransactionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    "Add First Transaction",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    backgroundColor: const Color(0xff11998E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
