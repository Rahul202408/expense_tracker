import 'package:flutter/material.dart';

/// AppShimmer provides a lightweight, GPU-accelerated shimmer effect
/// for loading states. Automatically adapts between light and dark modes.
class AppShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AppShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlidingGradientTransform(slidePercent: _animation.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Reusable shimmer placeholder box
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton UI for Home Dashboard
class HomeDashboardSkeleton extends StatelessWidget {
  const HomeDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card Skeleton (3D credit card size)
            const ShimmerBox(
              width: double.infinity,
              height: 190,
              borderRadius: 24,
            ),
            const SizedBox(height: 18),

            // Quick Actions Bar Skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (index) => Column(
                  children: const [
                    ShimmerBox(width: 58, height: 58, borderRadius: 18),
                    SizedBox(height: 8),
                    ShimmerBox(width: 48, height: 10, borderRadius: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Budget Health Meter Skeleton
            const ShimmerBox(
              width: double.infinity,
              height: 110,
              borderRadius: 20,
            ),
            const SizedBox(height: 22),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerBox(width: 170, height: 22, borderRadius: 6),
                ShimmerBox(width: 60, height: 16, borderRadius: 6),
              ],
            ),
            const SizedBox(height: 14),

            // Recent Transactions Skeletons (3 items)
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const ShimmerBox(
                      width: 50,
                      height: 50,
                      borderRadius: 16,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerBox(width: 140, height: 16, borderRadius: 4),
                          SizedBox(height: 8),
                          ShimmerBox(width: 80, height: 12, borderRadius: 4),
                        ],
                      ),
                    ),
                    const ShimmerBox(width: 70, height: 18, borderRadius: 6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton UI for History Screen
class HistoryListSkeleton extends StatelessWidget {
  const HistoryListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar Skeleton
            const ShimmerBox(
              width: double.infinity,
              height: 50,
              borderRadius: 16,
            ),
            const SizedBox(height: 14),

            // Filter Chips Skeleton
            Row(
              children: List.generate(
                3,
                (index) => const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: ShimmerBox(width: 80, height: 34, borderRadius: 20),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Summary Card Skeleton
            const ShimmerBox(
              width: double.infinity,
              height: 85,
              borderRadius: 18,
            ),
            const SizedBox(height: 20),

            // List Items Skeleton (5 items)
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      const ShimmerBox(
                        width: 52,
                        height: 52,
                        borderRadius: 16,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            ShimmerBox(width: 150, height: 16, borderRadius: 4),
                            SizedBox(height: 8),
                            ShimmerBox(width: 90, height: 12, borderRadius: 4),
                          ],
                        ),
                      ),
                      const ShimmerBox(width: 75, height: 18, borderRadius: 6),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton UI for Analytics Screen
class AnalyticsSkeleton extends StatelessWidget {
  const AnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: const [
            ShimmerBox(width: double.infinity, height: 85, borderRadius: 20),
            SizedBox(height: 14),
            ShimmerBox(width: double.infinity, height: 85, borderRadius: 20),
            SizedBox(height: 14),
            ShimmerBox(width: double.infinity, height: 85, borderRadius: 20),
            SizedBox(height: 24),
            ShimmerBox(width: double.infinity, height: 220, borderRadius: 24),
            SizedBox(height: 20),
            ShimmerBox(width: double.infinity, height: 150, borderRadius: 20),
          ],
        ),
      ),
    );
  }
}
