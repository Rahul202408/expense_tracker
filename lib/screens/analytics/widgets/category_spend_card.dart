import 'dart:ui';
import 'package:flutter/material.dart';

class CategorySpendCard extends StatelessWidget {
  final String category;
  final double amount;
  final double totalExpense;
  final int count;
  final String currencySymbol;
  final int rank;
  final bool isExpense;

  const CategorySpendCard({
    super.key,
    required this.category,
    required this.amount,
    required this.totalExpense,
    required this.count,
    required this.currencySymbol,
    required this.rank,
    this.isExpense = true,
  });

  static IconData getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'groceries':
        return Icons.restaurant_rounded;
      case 'shopping':
      case 'clothes':
        return Icons.shopping_bag_rounded;
      case 'travel':
      case 'transport':
      case 'fuel':
        return Icons.directions_car_rounded;
      case 'bills':
      case 'utilities':
        return Icons.receipt_long_rounded;
      case 'entertainment':
      case 'movies':
        return Icons.movie_filter_rounded;
      case 'health':
      case 'medical':
        return Icons.medical_services_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      case 'salary':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  static Color getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'groceries':
        return const Color(0xFFFF7A00); // Warm Orange
      case 'shopping':
      case 'clothes':
        return const Color(0xFF8B5CF6); // Royal Violet
      case 'travel':
      case 'transport':
      case 'fuel':
        return const Color(0xFF06B6D4); // Cyan
      case 'bills':
      case 'utilities':
        return const Color(0xFFEF4444); // Crimson Red
      case 'entertainment':
      case 'movies':
        return const Color(0xFFEC4899); // Pink
      case 'health':
      case 'medical':
        return const Color(0xFF10B981); // Emerald
      case 'education':
        return const Color(0xFFF59E0B); // Amber
      case 'investment':
        return const Color(0xFF3B82F6); // Blue
      case 'salary':
        return const Color(0xFF22C55E); // Green
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = getCategoryColor(category);
    final catIcon = getCategoryIcon(category);

    final percentage = totalExpense > 0 ? (amount / totalExpense) * 100 : 0.0;
    final progressFraction = totalExpense > 0 ? (amount / totalExpense).clamp(0.0, 1.0) : 0.0;

    final cardBgColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.70);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.85);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : const Color(0xFF6366F1).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
          Row(
            children: [
              // Icon Badge with Glowing Aura
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: catColor.withValues(alpha: isDark ? 0.18 : 0.12),
                  border: Border.all(
                    color: catColor.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Icon(catIcon, color: catColor, size: 22),
              ),
              const SizedBox(width: 14),

              // Category Name & Transaction count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (rank <= 3) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: rank == 1
                                  ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                                  : rank == 2
                                      ? Colors.grey.withValues(alpha: 0.2)
                                      : const Color(0xFFCD7F32).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "#$rank",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: rank == 1
                                    ? const Color(0xFFFFD700)
                                    : rank == 2
                                        ? Colors.grey.shade400
                                        : const Color(0xFFCD7F32),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$count ${count == 1 ? 'transaction' : 'transactions'}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount & Percentage Pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$currencySymbol ${amount.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${percentage.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: catColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Custom Gradient Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                // Track
                Container(
                  height: 6,
                  width: double.infinity,
                  color: isDark
                      ? const Color(0xFF334155).withValues(alpha: 0.5)
                      : const Color(0xFFE2E8F0),
                ),
                // Indicator
                FractionallySizedBox(
                  widthFactor: progressFraction,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: [
                          catColor.withValues(alpha: 0.8),
                          catColor,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: catColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}
