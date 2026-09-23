import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const AppLogo({
    super.key,
    this.size = 120.0,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.24);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: const Color(0xff10B981).withValues(alpha: 0.25),
                  blurRadius: size * 0.2,
                  offset: Offset(0, size * 0.08),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: const Color(0xff0F172A).withValues(alpha: 0.35),
                  blurRadius: size * 0.3,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Image.asset(
          'assets/images/app-logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xff0A0F1D),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: size * 0.5,
                color: const Color(0xff10B981),
              ),
            );
          },
        ),
      ),
    );
  }
}
