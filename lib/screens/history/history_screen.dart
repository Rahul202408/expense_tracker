import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../home/widgets/transaction_tile.dart';
import '../../widgets/three_d_tilt_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController searchController = TextEditingController();
  final TransactionService _transactionService = TransactionService();
  String searchText = "";
  String selectedCategory = "All";
  String selectedDateFilter = "All";

  final List<String> dateFilters = ["All", "Today", "This Week", "This Month"];
  final List<String> categories = [
    "All",
    "Food",
    "Shopping",
    "Travel",
    "Bills",
    "Salary",
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xff1A202C);
    final cardBgColor = isDark ? const Color(0xff1E293B) : Colors.white;
    final inputTextColor = isDark ? Colors.white : const Color(0xff2D3748);
    final chipUnselectedTextColor = isDark ? Colors.grey.shade300 : const Color(0xff4A5568);
    final chipUnselectedBorderColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300;

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
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3D Glass Search Field
            Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
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
                  hintText: "Search by title or category...",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? const Color(0xff38EF7D) : const Color(0xff1E3C72),
                  ),
                  suffixIcon: searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
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
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Category Filter Pills
            Text(
              "Categories",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.grey.shade400 : Colors.grey,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xff1E3C72), Color(0xff2A5298)],
                              )
                            : null,
                        color: isSelected ? null : cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : chipUnselectedBorderColor,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xff1E3C72).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : chipUnselectedTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // Date Range Filter Pills
            Text(
              "Date Range",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.grey.shade400 : Colors.grey,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: dateFilters.length,
                itemBuilder: (context, index) {
                  final filter = dateFilters[index];
                  final isSelected = selectedDateFilter == filter;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDateFilter = filter;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xff11998E), Color(0xff38EF7D)],
                              )
                            : null,
                        color: isSelected ? null : cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : chipUnselectedBorderColor,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xff11998E).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : chipUnselectedTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Filtered Transactions List
            Expanded(
              child: StreamBuilder<List<TransactionModel>>(
                stream: _transactionService.getTransactions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState("No Transactions Found");
                  }

                  final transactions = snapshot.data!;
                  final now = DateTime.now();

                  final filteredTransactions = transactions.where((
                    transaction,
                  ) {
                    final matchesSearch =
                        transaction.title.toLowerCase().contains(searchText) ||
                        transaction.category.toLowerCase().contains(searchText);

                    final matchesCategory =
                        selectedCategory == "All" ||
                        transaction.category == selectedCategory;

                    bool matchesDate = true;

                    if (selectedDateFilter == "Today") {
                      matchesDate =
                          transaction.date.year == now.year &&
                          transaction.date.month == now.month &&
                          transaction.date.day == now.day;
                    } else if (selectedDateFilter == "This Week") {
                      final startOfWeek = now.subtract(
                        Duration(days: now.weekday - 1),
                      );
                      final endOfWeek = startOfWeek.add(
                        const Duration(days: 6),
                      );

                      matchesDate =
                          !transaction.date.isBefore(startOfWeek) &&
                          !transaction.date.isAfter(endOfWeek);
                    } else if (selectedDateFilter == "This Month") {
                      matchesDate =
                          transaction.date.year == now.year &&
                          transaction.date.month == now.month;
                    }

                    return matchesSearch && matchesCategory && matchesDate;
                  }).toList();

                  if (filteredTransactions.isEmpty) {
                    return _buildEmptyState("No matching transactions found");
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];

                      return TransactionTile(
                        icon: transaction.isExpense
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        iconColor: transaction.isExpense
                            ? const Color(0xffE53935)
                            : const Color(0xff43A047),
                        title: transaction.title,
                        category: transaction.category,
                        amount: transaction.amount.toStringAsFixed(2),
                        isExpense: transaction.isExpense,
                        date: transaction.date,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: ThreeDTiltCard(
        maxTiltAngle: 0.08,
        elevation: 6,
        margin: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff4A5568),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
