import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../core/theme/app_colors.dart';

class CustomPageIndicator extends StatelessWidget {
  final PageController controller;
  final int count;

  const CustomPageIndicator({
    super.key,
    required this.controller,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return SmoothPageIndicator(
      controller: controller,
      count: count,
      effect: ExpandingDotsEffect(
        activeDotColor: AppColors.primary,
        dotColor: AppColors.lightGrey,
        dotHeight: 10,
        dotWidth: 10,
        expansionFactor: 3,
        spacing: 8,
      ),
    );
  }
}
