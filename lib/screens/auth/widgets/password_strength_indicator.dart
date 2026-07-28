import 'package:flutter/material.dart';
import '../../../utils/security_validator.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  Color _getStrengthColor(int score) {
    switch (score) {
      case 1:
      case 2:
        return Colors.redAccent;
      case 3:
        return Colors.orangeAccent;
      case 4:
        return const Color(0xff11998E);
      case 5:
        return const Color(0xff38EF7D);
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final result = SecurityValidator.evaluatePasswordStrength(password);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getStrengthColor(result.score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Password Strength",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            Text(
              result.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: result.percent,
            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildRequirementChip("8+ Chars", result.hasMinLength, isDark),
            _buildRequirementChip("Uppercase (A-Z)", result.hasUppercase, isDark),
            _buildRequirementChip("Lowercase (a-z)", result.hasLowercase, isDark),
            _buildRequirementChip("Number (0-9)", result.hasNumber, isDark),
            _buildRequirementChip("Special (!@#\$)", result.hasSpecialChar, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirementChip(String label, bool fulfilled, bool isDark) {
    final chipColor = fulfilled
        ? (isDark ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.green.shade50)
        : (isDark ? Colors.white10 : Colors.grey.shade100);

    final textColor = fulfilled
        ? (isDark ? Colors.greenAccent : Colors.green.shade700)
        : (isDark ? Colors.grey.shade500 : Colors.grey.shade600);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: fulfilled
              ? (isDark ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.green.shade300)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            fulfilled ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: fulfilled ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
