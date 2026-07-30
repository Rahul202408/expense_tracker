class SecurityValidator {
  /// Sanitizes input text to prevent XSS / Script Injection attacks.
  static String sanitize(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Strip HTML tags
        .replaceAll(RegExp(r'[<>]'), '') // Strip standalone < and >
        .trim();
  }

  /// Validates full name and checks for malicious scripts
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your full name";
    }
    final sanitized = sanitize(value);
    if (sanitized.length < 2) {
      return "Name must be at least 2 characters";
    }
    if (RegExp(r'[<>{}\\]').hasMatch(value)) {
      return "Special script characters are not allowed";
    }
    return null;
  }

  /// Strict Email Validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your email address";
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return "Please enter a valid email address";
    }
    return null;
  }

  /// Real Mobile Phone Number Validation
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your phone number";
    }
    final phone = value.trim();

    // Must be exactly 10 digits
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      return "Enter a valid 10-digit phone number";
    }

    // Must start with valid mobile digits (6, 7, 8, or 9)
    if (!RegExp(r'^[6-9]').hasMatch(phone)) {
      return "Phone number must start with 6, 7, 8, or 9";
    }

    // Reject dummy repeated numbers (e.g., 9999999999, 8888888888, 7777777777)
    if (RegExp(r'^(\d)\1{9}$').hasMatch(phone)) {
      return "Please enter a valid mobile number";
    }

    // Reject dummy sequential numbers (e.g., 1234567890, 9876543210)
    final dummyNumbers = [
      '1234567890',
      '0123456789',
      '9876543210',
      '0987654321',
      '6789012345',
      '7890123456',
      '8901234567',
      '9012345678',
    ];
    if (dummyNumbers.contains(phone)) {
      return "Please enter a valid mobile number";
    }

    return null;
  }

  /// Strong Password Criteria Validator (8 to 12 characters)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter a password";
    }
    if (value.length < 8) {
      return "Password must be at least 8 characters long";
    }
    if (value.length > 12) {
      return "Password cannot exceed 12 characters";
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "Password must include at least 1 uppercase letter (A-Z)";
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return "Password must include at least 1 lowercase letter (a-z)";
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return "Password must include at least 1 number (0-9)";
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(value)) {
      return "Password must include at least 1 special character (!@#\$%)";
    }
    return null;
  }

  /// Evaluates password strength breakdown for UI indicators
  static PasswordStrengthResult evaluatePasswordStrength(String password) {
    final hasMinLength = password.length >= 8 && password.length <= 12;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(password);

    int score = 0;
    if (hasMinLength) score++;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasNumber) score++;
    if (hasSpecialChar) score++;

    double percent = score / 5.0;
    String label = "Weak";
    if (score >= 5) {
      label = "Very Strong";
    } else if (score == 4) {
      label = "Strong";
    } else if (score == 3) {
      label = "Medium";
    } else if (score > 0) {
      label = "Weak";
    } else {
      label = "";
    }

    return PasswordStrengthResult(
      score: score,
      percent: percent,
      label: label,
      hasMinLength: hasMinLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasNumber: hasNumber,
      hasSpecialChar: hasSpecialChar,
    );
  }
}

class PasswordStrengthResult {
  final int score;
  final double percent;
  final String label;
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecialChar;

  PasswordStrengthResult({
    required this.score,
    required this.percent,
    required this.label,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecialChar,
  });
}
