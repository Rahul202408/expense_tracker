import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_prompt_service.dart';

class GoogleReviewDialog extends StatefulWidget {
  const GoogleReviewDialog({super.key});

  @override
  State<GoogleReviewDialog> createState() => _GoogleReviewDialogState();
}

class _GoogleReviewDialogState extends State<GoogleReviewDialog>
    with SingleTickerProviderStateMixin {
  int _selectedStars = 5;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onStarTap(int stars) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedStars = stars;
    });
  }

  Future<void> _submitReview() async {
    HapticFeedback.mediumImpact();
    Navigator.of(context, rootNavigator: true).pop();

    // Open Google Play Store
    await AppPromptService().openPlayStore();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Thank you so much for your support! ❤️",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xff1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _dismissLater() {
    HapticFeedback.selectionClick();
    // Closes without marking as rated, allowing 5th launch re-prompt
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xff0F172A),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xff10B981).withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff10B981).withValues(alpha: 0.2),
                blurRadius: 32,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Top Right Dismiss Button
              Positioned(
                top: 14,
                right: 14,
                child: InkWell(
                  onTap: _dismissLater,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xff94A3B8),
                      size: 20,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge Header Icon with Glow
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xff10B981), Color(0xff059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff10B981).withValues(alpha: 0.45),
                            blurRadius: 24,
                            spreadRadius: 3,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.rate_review_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dialog Title
                    const Text(
                      "Enjoying Expense Tracker?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Dialog Subtitle
                    Text(
                      "Your feedback means the world to our indie project! Please take 5 seconds to rate us on Google Play.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xff94A3B8).withValues(alpha: 0.95),
                        fontSize: 13.5,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Interactive 5 Star Rating Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xff1E293B).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xff334155),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starNumber = index + 1;
                          final isFilled = starNumber <= _selectedStars;
                          return GestureDetector(
                            onTap: () => _onStarTap(starNumber),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: AnimatedScale(
                                scale: isFilled ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 150),
                                child: Icon(
                                  isFilled
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: isFilled
                                      ? const Color(0xffFBBF24)
                                      : const Color(0xff64748B),
                                  size: 34,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Rating description text
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _selectedStars == 5
                            ? "⭐⭐⭐⭐⭐ Outstanding! Thank you!"
                            : _selectedStars >= 4
                                ? "⭐⭐⭐⭐ Great! We appreciate your support!"
                                : "Help us improve with your feedback",
                        key: ValueKey<int>(_selectedStars),
                        style: const TextStyle(
                          color: Color(0xffFBBF24),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Primary Action: Rate on Google Play
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xff10B981), Color(0xff059669)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xff10B981).withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Rate on Google Play ⭐",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Secondary Action: Maybe Later
                    TextButton(
                      onPressed: _dismissLater,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xff94A3B8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        "Maybe Later",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff94A3B8),
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
