import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/transaction_model.dart';
import '../../../../widgets/three_d_tilt_card.dart';

class SpendingTrendBarChart extends StatefulWidget {
  final List<TransactionModel> transactions;
  final String period;
  final bool isExpense;
  final String currencySymbol;

  const SpendingTrendBarChart({
    super.key,
    required this.transactions,
    required this.period,
    required this.isExpense,
    required this.currencySymbol,
  });

  @override
  State<SpendingTrendBarChart> createState() => _SpendingTrendBarChartState();
}

class _SpendingTrendBarChartState extends State<SpendingTrendBarChart> {
  int? touchedGroupIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final symbol = widget.currencySymbol;

    final filtered = widget.transactions
        .where((t) => t.isExpense == widget.isExpense)
        .toList();

    // Generate bar data points based on period
    final trendPoints = _calculateTrend(filtered, widget.period);

    if (trendPoints.isEmpty || trendPoints.every((p) => p.amount == 0)) {
      return Container(
        height: 240,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.85),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 40,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              "No trend data available for ${widget.period}",
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    double maxAmount = 0.0;
    int peakIndex = 0;
    for (int i = 0; i < trendPoints.length; i++) {
      if (trendPoints[i].amount > maxAmount) {
        maxAmount = trendPoints[i].amount;
        peakIndex = i;
      }
    }
    final maxY = maxAmount == 0 ? 100.0 : maxAmount * 1.25;

    final cardBgColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.65);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.85);

    final primaryBarColor = widget.isExpense
        ? const Color(0xffEF4444)
        : const Color(0xff10B981);
    final secondaryBarColor = widget.isExpense
        ? const Color(0xffF43F5E)
        : const Color(0xff059669);

    return ThreeDTiltCard(
      margin: const EdgeInsets.symmetric(vertical: 12),
      maxTiltAngle: 0.08,
      elevation: isDark ? 3 : 8,
      shadowColor: primaryBarColor.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor, width: 1.5),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.07),
                        Colors.white.withValues(alpha: 0.02),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.85),
                        Colors.white.withValues(alpha: 0.40),
                      ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header with Peak Callout
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: primaryBarColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.trending_up_rounded,
                        size: 16,
                        color: primaryBarColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isExpense ? "Spending Trend" : "Income Trend",
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : const Color(0xff0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Spacer(),
                    if (maxAmount > 0)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryBarColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: primaryBarColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            "Peak: ${trendPoints[peakIndex].shortLabel} ($symbol${maxAmount.toStringAsFixed(0)})",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: primaryBarColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bar Chart Area
                SizedBox(
                  height: 190,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) =>
                              isDark ? const Color(0xff1E293B) : Colors.black87,
                          tooltipRoundedRadius: 10,
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final point = trendPoints[group.x.toInt()];
                            return BarTooltipItem(
                              "${point.label}\n",
                              const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                              children: [
                                TextSpan(
                                  text: "$symbol${rod.toY.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        touchCallback: (event, response) {
                          setState(() {
                            if (response?.spot != null) {
                              touchedGroupIndex = response!.spot!.touchedBarGroupIndex;
                            } else {
                              touchedGroupIndex = null;
                            }
                          });
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= trendPoints.length) {
                                return const SizedBox.shrink();
                              }
                              final isSelected = touchedGroupIndex == index;
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 4,
                                child: Text(
                                  trendPoints[index].shortLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected
                                        ? primaryBarColor
                                        : (isDark ? Colors.white70 : const Color(0xff475569)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 3,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(trendPoints.length, (i) {
                        final point = trendPoints[i];
                        final isTouched = touchedGroupIndex == i;
                        final isPeak = i == peakIndex && maxAmount > 0;

                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: point.amount,
                              width: trendPoints.length > 7 ? 12 : 20,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              gradient: LinearGradient(
                                colors: isTouched || isPeak
                                    ? [primaryBarColor, secondaryBarColor]
                                    : [
                                        primaryBarColor.withValues(alpha: 0.75),
                                        secondaryBarColor.withValues(alpha: 0.5),
                                      ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.black.withValues(alpha: 0.03),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_TrendPoint> _calculateTrend(List<TransactionModel> list, String period) {
    final now = DateTime.now();

    if (period == "This Week") {
      // 7 Days: Mon (1) to Sun (7)
      final weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      final Map<int, double> sums = {for (int i = 1; i <= 7; i++) i: 0.0};
      for (final t in list) {
        sums[t.date.weekday] = (sums[t.date.weekday] ?? 0.0) + t.amount;
      }
      return List.generate(7, (i) {
        final weekday = i + 1;
        return _TrendPoint(
          label: weekDays[i],
          shortLabel: weekDays[i],
          amount: sums[weekday] ?? 0.0,
        );
      });
    } else if (period == "This Month") {
      final monthName = DateFormat('MMM').format(now);
      final weekRanges = [
        {"name": "1 - 7 $monthName", "short": "1-7", "start": 1, "end": 7},
        {"name": "8 - 14 $monthName", "short": "8-14", "start": 8, "end": 14},
        {"name": "15 - 21 $monthName", "short": "15-21", "start": 15, "end": 21},
        {"name": "22 - 28 $monthName", "short": "22-28", "start": 22, "end": 28},
        {"name": "29 - 31 $monthName", "short": "29-31", "start": 29, "end": 31},
      ];
      final Map<int, double> sums = {0: 0.0, 1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0};
      for (final t in list) {
        final day = t.date.day;
        if (day <= 7) {
          sums[0] = (sums[0] ?? 0) + t.amount;
        } else if (day <= 14) {
          sums[1] = (sums[1] ?? 0) + t.amount;
        } else if (day <= 21) {
          sums[2] = (sums[2] ?? 0) + t.amount;
        } else if (day <= 28) {
          sums[3] = (sums[3] ?? 0) + t.amount;
        } else {
          sums[4] = (sums[4] ?? 0) + t.amount;
        }
      }
      return List.generate(weekRanges.length, (i) {
        return _TrendPoint(
          label: weekRanges[i]["name"] as String,
          shortLabel: weekRanges[i]["short"] as String,
          amount: sums[i] ?? 0.0,
        );
      });
    } else if (period == "This Year") {
      // 12 Months
      final monthNames = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
      ];
      final Map<int, double> sums = {for (int i = 1; i <= 12; i++) i: 0.0};
      for (final t in list) {
        if (t.date.year == now.year) {
          sums[t.date.month] = (sums[t.date.month] ?? 0.0) + t.amount;
        }
      }
      return List.generate(12, (i) {
        final month = i + 1;
        return _TrendPoint(
          label: monthNames[i],
          shortLabel: monthNames[i],
          amount: sums[month] ?? 0.0,
        );
      });
    } else {
      // "All Time" or Custom - Last 6 months aggregate
      final List<_TrendPoint> points = [];
      for (int i = 5; i >= 0; i--) {
        final targetDate = DateTime(now.year, now.month - i, 1);
        final monthName = [
          "Jan", "Feb", "Mar", "Apr", "May", "Jun",
          "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
        ][targetDate.month - 1];
        double sum = 0.0;
        for (final t in list) {
          if (t.date.year == targetDate.year && t.date.month == targetDate.month) {
            sum += t.amount;
          }
        }
        points.add(_TrendPoint(
          label: "$monthName ${targetDate.year % 100}",
          shortLabel: monthName,
          amount: sum,
        ));
      }
      return points;
    }
  }
}

class _TrendPoint {
  final String label;
  final String shortLabel;
  final double amount;

  const _TrendPoint({
    required this.label,
    required this.shortLabel,
    required this.amount,
  });
}
