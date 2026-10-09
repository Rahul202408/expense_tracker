import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/three_d_tilt_card.dart';
import '../../providers/pro_provider.dart';
import '../../providers/currency_provider.dart';
import '../../services/firebase_analytics_service.dart';
import '../auth/login_screen.dart';
import '../pro/pro_screen.dart';

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

    // Proactively restore session in background if cold boot
    if (FirebaseAuth.instance.currentUser == null) {
      AuthService().trySilentGoogleSignIn();
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
      firstDate: DateTime(2020),
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
      final amountCleaned = amountController.text.trim().replaceAll(',', '');
      final amount = double.parse(amountCleaned);

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

      FirebaseAnalyticsService().logAddTransaction(
        category: selectedCategory,
        amount: amount,
        isExpense: isExpense,
      );

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

      final errorStr = e.toString().toLowerCase();
      final isAuthError = errorStr.contains("authentication required") ||
          errorStr.contains("permission-denied") ||
          errorStr.contains("user authentication");

      if (isAuthError) {
        // 1. Attempt immediate silent Google recovery
        final restoredUser = await AuthService().trySilentGoogleSignIn();
        if (restoredUser != null && mounted) {
          try {
            final title = titleController.text.trim();
            final amountCleaned = amountController.text.trim().replaceAll(',', '');
            final amount = double.parse(amountCleaned);

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
            return;
          } catch (_) {}
        }

        // 2. If recovery not possible, show user-friendly Auth Required modal dialog
        if (mounted) {
          _showAuthRequiredDialog();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAuthRequiredDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xff1E293B) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xff1E293B);
    final subtitleColor = isDark ? const Color(0xff94A3B8) : const Color(0xff64748B);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xffF59E0B), Color(0xffD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffF59E0B).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Authentication Required",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Please sign in with your account to securely save and back up your transactions to the cloud.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: subtitleColor,
                        fontWeight: FontWeight.w600,
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
                        colors: [Color(0xff1E3C72), Color(0xff2A5298)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff1E3C72).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Sign In",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = Provider.of<CurrencyProvider>(context).symbol;
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
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: Center(
                        widthFactor: 1.0,
                        child: Text(
                          currencySymbol,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xff38EF7D) : const Color(0xff1E3C72),
                          ),
                        ),
                      ),
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
                    final cleaned = value.trim().replaceAll(',', '');
                    final parsed = double.tryParse(cleaned);
                    if (parsed == null) {
                      return "Enter a valid number";
                    }
                    if (parsed <= 0) {
                      return "Amount must be greater than 0";
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
                children: [
                  ...categoryIcons.entries.map((entry) {
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
                  }),
                  GestureDetector(
                    onTap: () => _showAddCustomCategoryDialog(context, isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xffF59E0B).withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            size: 18,
                            color: Color(0xffF59E0B),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Add New",
                            style: TextStyle(
                              color: Color(0xffF59E0B),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Date Picker Card
              ThreeDTiltCard(
                enableTilt: false,
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

  Future<void> _showAddCustomCategoryDialog(BuildContext context, bool isDark) async {
    final proProvider = Provider.of<ProProvider>(context, listen: false);
    if (!proProvider.isPro) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xff0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xffF59E0B), width: 1.2),
          ),
          title: const Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: Color(0xffF59E0B), size: 28),
              SizedBox(width: 8),
              Text(
                "PRO Feature",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            "Custom categories are only available for PRO members.\n\nUpgrade now to create unlimited custom categories, remove all ads, and export reports!",
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffF59E0B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Upgrade to PRO 👑",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    IconData selectedIcon = Icons.star_rounded;

    final availableIcons = [
      Icons.star_rounded,
      Icons.fitness_center_rounded,
      Icons.pets_rounded,
      Icons.savings_rounded,
      Icons.car_rental_rounded,
      Icons.card_giftcard_rounded,
      Icons.work_rounded,
      Icons.child_care_rounded,
      Icons.coffee_rounded,
    ];

    try {
      await showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: isDark ? const Color(0xff1E293B) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(
                  "New Custom Category 🏷️",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xff1A202C),
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "Category Name (e.g. Gym, EMI)",
                        filled: true,
                        fillColor: isDark ? const Color(0xff0F172A) : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Select Icon:", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: availableIcons.map((ic) {
                        final isChosen = selectedIcon == ic;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedIcon = ic),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isChosen ? const Color(0xff1E3C72) : Colors.grey.withValues(alpha: 0.15),
                            ),
                            child: Icon(ic, color: isChosen ? Colors.amber : Colors.grey, size: 20),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                  ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isNotEmpty) {
                        setState(() {
                          categoryIcons[name] = selectedIcon;
                          selectedCategory = name;
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text("Add Category"),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
    }
  }
}
