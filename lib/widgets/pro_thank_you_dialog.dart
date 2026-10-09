import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class ProThankYouDialog extends StatefulWidget {
  final String? planId;

  const ProThankYouDialog({
    super.key,
    this.planId,
  });

  static Future<void> show(BuildContext context, {String? planId}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProThankYouDialog(planId: planId),
    );
  }

  @override
  State<ProThankYouDialog> createState() => _ProThankYouDialogState();
}

class _ProThankYouDialogState extends State<ProThankYouDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOut,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _getPlanTitle() {
    final id = widget.planId ?? '';
    if (id.contains('monthly')) return 'Monthly VIP';
    if (id.contains('yearly')) return 'Annual VIP';
    return 'Lifetime VIP Access';
  }

  @override
  Widget build(BuildContext context) {
    final userName = FirebaseAuth.instance.currentUser?.displayName ??
        AuthService.cachedName ??
        "Valued VIP Member";

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xff0B1329),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xffF59E0B),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffF59E0B).withValues(alpha: 0.35),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Glowing Crown Header
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xffF59E0B), Color(0xffFFD700), Color(0xffD97706)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xffFFD700).withValues(alpha: 0.5 * _glowAnimation.value),
                            blurRadius: 25 * _glowAnimation.value,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "👑",
                          style: TextStyle(fontSize: 44),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),

                // 2. Congratulations & Thank You Titles
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xffF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xffF59E0B).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, color: Color(0xffF59E0B), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _getPlanTitle().toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xffF59E0B),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Thank You So Much! 🎉",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "You are now an honored VIP Member of Expense Tracker, $userName!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff38EF7D),
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "Payment Successful • All Premium Superpowers Unlocked Instantly ✨",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Unlocked Superpowers Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildPerkRow("🚫", "100% Ad-Free Experience", "Zero banners or popups forever"),
                      const SizedBox(height: 10),
                      _buildPerkRow("📊", "Unlimited PDF & Excel Exports", "Detailed branded financial statements"),
                      const SizedBox(height: 10),
                      _buildPerkRow("🏷️", "Unlimited Custom Categories", "Personalize icons and spend tags"),
                      const SizedBox(height: 10),
                      _buildPerkRow("🔒", "Biometric & 4-Digit PIN Lock", "Maximum privacy protection"),
                      const SizedBox(height: 10),
                      _buildPerkRow("⚡", "Priority Cloud Sync", "Real-time instant multi-device backup"),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 4. Energetic Action Button
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xffF59E0B), Color(0xffFFD700), Color(0xffD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffF59E0B).withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context); // close dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Explore VIP Features 🚀",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 18),
                      ],
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

  Widget _buildPerkRow(String emoji, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xffF59E0B).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded, color: Color(0xff10B981), size: 16),
      ],
    );
  }
}
