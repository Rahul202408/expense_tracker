import 'package:flutter/material.dart';
import '../../services/security_service.dart';
import '../../widgets/three_d_tilt_card.dart';
import '../main_screen.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AppLockScreen({super.key, this.onSuccess});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen>
    with SingleTickerProviderStateMixin {
  final SecurityService _securityService = SecurityService();
  String _enteredPin = "";
  bool _isError = false;
  bool _canUseBiometrics = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    _initBiometricsAndPrompt();
  }

  Future<void> _initBiometricsAndPrompt() async {
    final isBioEnabled = await _securityService.isBiometricEnabled();
    final isBioAvail = await _securityService.isBiometricAvailable();

    if (mounted) {
      setState(() {
        _canUseBiometrics = isBioEnabled && isBioAvail;
      });
    }

    if (isBioEnabled && isBioAvail) {
      _triggerBiometricAuth();
    }
  }

  Future<void> _triggerBiometricAuth() async {
    final authenticated = await _securityService.authenticateWithBiometrics(
      reason: "Authenticate with Fingerprint or Face ID to unlock Expense Tracker",
    );

    if (authenticated && mounted) {
      _unlockApp();
    }
  }

  void _onKeyPress(String val) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += val;
        _isError = false;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _isError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    final isValid = await _securityService.verifyPin(_enteredPin);

    if (isValid) {
      _unlockApp();
    } else {
      _shakeController.forward(from: 0.0);
      setState(() {
        _isError = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _enteredPin = "";
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Incorrect PIN. Please try again."),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _unlockApp() {
    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff0F172A) : const Color(0xffF4F6FB);
    final cardBgColor = isDark ? const Color(0xff1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xff1A202C);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // 3D Super View Security Header Card
            ThreeDTiltCard(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              maxTiltAngle: 0.08,
              elevation: isDark ? 8 : 12,
              shadowColor: const Color(0xff11998E),
              borderRadius: BorderRadius.circular(28),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xff0F2027),
                            const Color(0xff203A43),
                            const Color(0xff2C5364),
                          ]
                        : [
                            const Color(0xff11998E),
                            const Color(0xff00B4DB),
                            const Color(0xff0083B0),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "App Locked",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Enter 4-Digit Security PIN or Scan Biometrics",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),

            // Animated PIN Indicator Dots
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value * (_isError ? 1 : 0), 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _enteredPin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isError
                              ? Colors.redAccent
                              : (isFilled
                                  ? const Color(0xff11998E)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.grey.shade300)),
                          border: Border.all(
                            color: _isError
                                ? Colors.redAccent
                                : (isFilled
                                    ? const Color(0xff11998E)
                                    : Colors.grey.shade400),
                            width: 2,
                          ),
                          boxShadow: isFilled && !_isError
                              ? [
                                  BoxShadow(
                                    color:
                                        const Color(0xff11998E).withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                      );
                    }),
                  ),
                );
              },
            ),

            const Spacer(),

            // Custom 3D Keypad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeypadButton("1", textColor, isDark),
                      _buildKeypadButton("2", textColor, isDark),
                      _buildKeypadButton("3", textColor, isDark),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeypadButton("4", textColor, isDark),
                      _buildKeypadButton("5", textColor, isDark),
                      _buildKeypadButton("6", textColor, isDark),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeypadButton("7", textColor, isDark),
                      _buildKeypadButton("8", textColor, isDark),
                      _buildKeypadButton("9", textColor, isDark),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Biometric Trigger Button
                      IconButton(
                        iconSize: 32,
                        icon: Icon(
                          Icons.fingerprint_rounded,
                          color: _canUseBiometrics
                              ? const Color(0xff11998E)
                              : Colors.grey.shade400,
                        ),
                        onPressed: _canUseBiometrics ? _triggerBiometricAuth : null,
                        tooltip: "Scan Biometrics (Fingerprint/Face)",
                      ),
                      _buildKeypadButton("0", textColor, isDark),
                      // Backspace Button
                      IconButton(
                        iconSize: 28,
                        icon: Icon(
                          Icons.backspace_outlined,
                          color: isDark ? Colors.grey.shade300 : const Color(0xff4A5568),
                        ),
                        onPressed: _onDelete,
                        tooltip: "Delete",
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String label, Color textColor, bool isDark) {
    return InkWell(
      onTap: () => _onKeyPress(label),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 65,
        height: 65,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade100,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
