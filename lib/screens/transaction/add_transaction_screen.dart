import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../widgets/three_d_tilt_card.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;
  final bool? initialIsExpense;

  const AddTransactionScreen({
    super.key,
    this.transaction,
    this.initialIsExpense,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TransactionService _transactionService = TransactionService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  final Map<String, IconData> categoryIcons = {
    "Food": Icons.restaurant_rounded,
    "Shopping": Icons.shopping_bag_rounded,
    "Travel": Icons.flight_takeoff_rounded,
    "Salary": Icons.account_balance_wallet_rounded,
    "Bills": Icons.receipt_long_rounded,
    "Health": Icons.medical_services_rounded,
    "Education": Icons.school_rounded,
    "Entertainment": Icons.movie_rounded,
    "Other": Icons.category_rounded,
  };

  String selectedCategory = "Food";
  bool isExpense = true;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    if (widget.transaction != null) {
      titleController.text = widget.transaction!.title;
      amountController.text = widget.transaction!.amount.toString();
      selectedCategory = widget.transaction!.category;
      isExpense = widget.transaction!.isExpense;
      selectedDate = widget.transaction!.date;
    } else if (widget.initialIsExpense != null) {
      isExpense = widget.initialIsExpense!;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final title = titleController.text.trim();
      final amount = double.parse(amountController.text.trim());

      if (widget.transaction == null) {
        final transaction = TransactionModel(
          id: '',
          title: title,
          category: selectedCategory,
          amount: amount,
          isExpense: isExpense,
          date: selectedDate,
        );
        await _transactionService.addTransaction(transaction);
      } else {
        final updatedTransaction = TransactionModel(
          id: widget.transaction!.id,
          title: title,
          category: selectedCategory,
          amount: amount,
          isExpense: isExpense,
          date: selectedDate,
        );
        await _transactionService.updateTransaction(updatedTransaction);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Transaction Saved Successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xff1E293B) : Colors.white;
    final inputTextColor = isDark ? Colors.white : const Color(0xff2D3748);
    final headingColor = isDark ? Colors.white : const Color(0xff1A202C);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
          widget.transaction == null ? "Add Transaction" : "Edit Transaction",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: headingColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),

        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3D Type Selector Toggle (Expense vs Income)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff1E293B) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isExpense = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isExpense
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xffFF5252),
                                      Color(0xffFF1744),
                                    ],
                                  )
                                : null,
                            color: isExpense ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: isExpense
                                ? [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                color: isExpense
                                    ? Colors.white
                                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Expense",
                                style: TextStyle(
                                  color: isExpense
                                      ? Colors.white
                                      : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isExpense = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: !isExpense
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xff00E676),
                                      Color(0xff00C853),
                                    ],
                                  )
                                : null,
                            color: !isExpense ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: !isExpense
                                ? [
                                    BoxShadow(
                                      color: Colors.green.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                color: !isExpense
                                    ? Colors.white
                                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Income",
                                style: TextStyle(
                                  color: !isExpense
                                      ? Colors.white
                                      : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Title Field
              _buildInputCard(
                label: "Title",
                isDark: isDark,
                cardBgColor: cardBgColor,
                borderColor: borderColor,
                child: TextFormField(
                  controller: titleController,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: inputTextColor,
                  ),
                  decoration: InputDecoration(
                    hintText: "e.g. Grocery Shopping",
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                      fontWeight: FontWeight.normal,
                    ),
                    prefixIcon: Icon(
                      Icons.title_rounded,
                      color: isDark ? const Color(0xff38EF7D) : const Color(0xff1E3C72),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter a title";
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Amount Field
              _buildInputCard(
                label: "Amount",
                isDark: isDark,
                cardBgColor: cardBgColor,
                borderColor: borderColor,
                child: TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: isDark ? const Color(0xff38EF7D) : const Color(0xff1E3C72),
                  ),
                  decoration: InputDecoration(
                    hintText: "0.00",
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                      fontWeight: FontWeight.normal,
                      fontSize: 18,
                    ),
                    prefixIcon: Icon(
                      Icons.currency_rupee_rounded,
                      color: isDark ? const Color(0xff38EF7D) : const Color(0xff1E3C72),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter amount";
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return "Enter a valid number";
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Category Selector Header
              Text(
                "Select Category",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 10),

              // Category Icon Grid / Scroll
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categoryIcons.entries.map((entry) {
                  final catName = entry.key;
                  final catIcon = entry.value;
                  final isSelected = selectedCategory == catName;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = catName;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xff1E3C72), Color(0xff2A5298)],
                              )
                            : null,
                        color: isSelected ? null : cardBgColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xff1E3C72).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            catIcon,
                            size: 18,
                            color: isSelected
                                ? Colors.amberAccent
                                : (isDark ? const Color(0xff38EF7D) : const Color(0xff1E3C72)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            catName,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.grey.shade300 : const Color(0xff2D3748)),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Date Picker Card
              ThreeDTiltCard(
                maxTiltAngle: 0.04,
                elevation: isDark ? 2 : 4,
                borderRadius: BorderRadius.circular(20),
                onTap: pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xff38EF7D).withValues(alpha: 0.15)
                              : const Color(0xff1E3C72).withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: isDark ? const Color(0xff38EF7D) : const Color(0xff1E3C72),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Date",
                              style: TextStyle(
                                color: isDark ? Colors.grey.shade400 : Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                              style: TextStyle(
                                color: inputTextColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_calendar_rounded,
                        color: isDark ? const Color(0xff38EF7D) : const Color(0xff1E3C72),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff1E3C72),
                      Color(0xff2A5298),
                      Color(0xff11998E),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff1E3C72).withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    widget.transaction == null
                        ? "Save Transaction"
                        : "Update Transaction",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required String label,
    required Widget child,
    required bool isDark,
    required Color cardBgColor,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
