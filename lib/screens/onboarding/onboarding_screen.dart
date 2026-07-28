import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/custom_page_indicator.dart';
import '../../widgets/primary_button.dart';
import 'onboarding_data.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int currentPage = 0;

  Future<void> finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool("onboarding", true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void nextPage() {
    if (currentPage < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      finishOnboarding();
    }
  }

  void skip() {
    _pageController.animateToPage(
      onboardingData.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [
              /// Skip
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: skip,
                  child: Text(
                    "Skip",
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              /// Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,

                  itemCount: onboardingData.length,

                  onPageChanged: (index) {
                    setState(() {
                      currentPage = index;
                    });
                  },

                  itemBuilder: (context, index) {
                    final page = onboardingData[index];

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Image.asset(page.image, height: 320),

                        const SizedBox(height: 40),

                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title,
                        ),

                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            page.description,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              /// Indicator
              CustomPageIndicator(
                controller: _pageController,
                count: onboardingData.length,
              ),

              const SizedBox(height: 30),

              /// Button
              PrimaryButton(
                text: currentPage == onboardingData.length - 1
                    ? "Get Started"
                    : "Next",
                onPressed: nextPage,
              ),

              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
