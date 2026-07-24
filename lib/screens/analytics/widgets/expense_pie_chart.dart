import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../widgets/three_d_tilt_card.dart';

class ExpensePieChart extends StatefulWidget {
  final Map<String, double> categoryData;

  const ExpensePieChart({super.key, required this.categoryData});

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int touchedIndex = -1;

  static const List<Color> sectionColors = [
    Color(0xff11998E),
    Color(0xffFF5252),
    Color(0xff1E3C72),
    Color(0xffFF9800),
    Color(0xff6A11CB),
    Color(0xff00BCD4),
    Color(0xff9C27B0),
    Color(0xffFFC107),
    Color(0xff43A047),
    Color(0xffE91E63),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.categoryData.isEmpty) {
      return Container(
        height: 240,
        alignment: Alignment.center,
        child: Text(
          "No expense data available",
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final entries = widget.categoryData.entries.toList();
    final double totalSum = widget.categoryData.values.fold(
      0.0,
      (sum, val) => sum + val,
    );

    String centerLabel = "Total Expense";
    String centerValue = "₹${totalSum.toStringAsFixed(0)}";
    String centerSubText = "${entries.length} Categories";

    if (touchedIndex >= 0 && touchedIndex < entries.length) {
      final touchedEntry = entries[touchedIndex];
      final pct = totalSum > 0 ? (touchedEntry.value / totalSum * 100) : 0.0;
      centerLabel = touchedEntry.key;
      centerValue = "₹${touchedEntry.value.toStringAsFixed(0)}";
      centerSubText = "${pct.toStringAsFixed(1)}%";
    }

    final cardBgColor = isDark ? const Color(0xff1E293B) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.shade200;

    return ThreeDTiltCard(
      margin: const EdgeInsets.symmetric(vertical: 12),
      maxTiltAngle: 0.10,
      elevation: isDark ? 4 : 10,
      shadowColor: touchedIndex >= 0
          ? sectionColors[touchedIndex % sectionColors.length]
          : const Color(0xff11998E),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: 1.5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xff1E293B),
                    const Color(0xff151D2A),
                  ]
                : [
                    Colors.white,
                    const Color(0xffF8FAFC),
                  ],
          ),
        ),
        child: SizedBox(
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ambient Glow Ring
              Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xff11998E).withValues(alpha: 0.05)
                      : const Color(0xff1E3C72).withValues(alpha: 0.03),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xff11998E).withValues(alpha: 0.15)
                        : const Color(0xff1E3C72).withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
              ),

              // Pie Chart
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 4,
                  centerSpaceRadius: 62,
                  sections: List.generate(entries.length, (i) {
                    final isTouched = i == touchedIndex;
                    final radius = isTouched ? 88.0 : 74.0;
                    final item = entries[i];
                    final color = sectionColors[i % sectionColors.length];
                    final pct = totalSum > 0 ? (item.value / totalSum * 100) : 0.0;

                    return PieChartSectionData(
                      color: color,
                      value: item.value,
                      title: isTouched
                          ? "${pct.toStringAsFixed(0)}%"
                          : pct >= 8
                              ? "${pct.toStringAsFixed(0)}%"
                              : "",
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: isTouched ? 16 : 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      badgeWidget: isTouched
                          ? _buildBadgeWidget(color)
                          : null,
                      badgePositionPercentageOffset: .98,
                    );
                  }),
                ),
              ),

              // Center Glass Info Hub
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: 110,
                height: 110,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xff0F172A).withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.95),
                  boxShadow: [
                    BoxShadow(
                      color: touchedIndex >= 0
                          ? sectionColors[touchedIndex % sectionColors.length]
                              .withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(
                    color: touchedIndex >= 0
                        ? sectionColors[touchedIndex % sectionColors.length]
                        : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      centerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        centerValue,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xff1A202C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: touchedIndex >= 0
                            ? sectionColors[touchedIndex % sectionColors.length]
                                .withValues(alpha: 0.2)
                            : const Color(0xff11998E).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        centerSubText,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: touchedIndex >= 0
                              ? sectionColors[touchedIndex % sectionColors.length]
                              : const Color(0xff11998E),
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

  Widget _buildBadgeWidget(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
