import 'package:flutter/material.dart';
import '../../transaction/add_transaction_screen.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navItems = [
      const _NavItemData(
        icon: Icons.home_rounded,
        label: "Home",
        gradient: [Color(0xff11998E), Color(0xff38EF7D)],
        shadowColor: Color(0xff11998E),
      ),
      const _NavItemData(
        icon: Icons.bar_chart_rounded,
        label: "Analytics",
        gradient: [Color(0xff1E3C72), Color(0xff2A5298)],
        shadowColor: Color(0xff1E3C72),
      ),
      const _NavItemData(
        icon: Icons.history_rounded,
        label: "History",
        gradient: [Color(0xff6A11CB), Color(0xff2575FC)],
        shadowColor: Color(0xff6A11CB),
      ),
      const _NavItemData(
        icon: Icons.person_rounded,
        label: "Profile",
        gradient: [Color(0xff0DA699), Color(0xff11998E)],
        shadowColor: Color(0xff0DA699),
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(left: 14, right: 14, bottom: 20, top: 4),
      height: 72,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xff1E293B).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: const Color(0xff11998E).withValues(alpha: isDark ? 0.15 : 0.1),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Tab 0: Home
            _buildNavItem(context, 0, navItems[0]),

            // Tab 1: Analytics
            _buildNavItem(context, 1, navItems[1]),

            // Central 3D Glass + Action Button
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen(),
                  ),
                );
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xff11998E),
                      Color(0xff38EF7D),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff11998E).withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),

            // Tab 2: History
            _buildNavItem(context, 2, navItems[2]),

            // Tab 3: Profile
            _buildNavItem(context, 3, navItems[3]),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, _NavItemData item) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: item.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: item.shadowColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.15 : 1.0,
              child: Icon(
                item.icon,
                color: isSelected
                    ? Colors.white
                    : Colors.grey.shade400,
                size: 22,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final Color shadowColor;

  const _NavItemData({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.shadowColor,
  });
}
