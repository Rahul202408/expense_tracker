import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 120.0});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.28);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff1E3C72),
            Color(0xff2A5298),
            Color(0xff11998E),
            Color(0xff38EF7D),
          ],
          stops: [0.0, 0.4, 0.8, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff11998E).withValues(alpha: 0.4),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.1),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xff1E3C72).withValues(alpha: 0.2),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.18),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            // Background 3D glass shine circle
            Positioned(
              right: -size * 0.2,
              top: -size * 0.2,
              child: Container(
                width: size * 0.7,
                height: size * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),

            // Icon graphics
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glowing ring
                  Container(
                    width: size * 0.62,
                    height: size * 0.62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                  ),

                  // Wallet icon with trend overlay
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: size * 0.42,
                  ),

                  Positioned(
                    right: size * 0.08,
                    top: size * 0.08,
                    child: Container(
                      padding: EdgeInsets.all(size * 0.04),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xff00E676),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: size * 0.18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
