import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/primary_button.dart';
import '../../widgets/three_d_tilt_card.dart';
import 'signup_screen.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import '../../services/auth_service.dart';
import '../main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool rememberMe = true;
  bool isLoading = false;
  bool isGoogleLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleGoogleSignIn() async {
    setState(() => isGoogleLoading = true);

    try {
      final result = await _authService.googleSignIn();

      if (!mounted) return;

      if (result == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _authService.recordUserLoginSession(user);
        }

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      } else if (result != "Google Sign-In Cancelled") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google Sign-In Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isGoogleLoading = false);
      }
    }
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final result = await _authService.login(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _authService.recordUserLoginSession(user);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login Successful"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.red),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: emailController.text.trim(),
    );
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: isDark ? const Color(0xff1E293B) : Colors.white,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xff11998E).withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Color(0xff11998E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Reset Password",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : const Color(0xff1A202C),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Enter your registered email address and we'll send you a link to reset your password via Firebase.",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: resetEmailController,
                    hintText: "Email Address",
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff11998E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isResetting
                      ? null
                      : () async {
                          final email = resetEmailController.text.trim();
                          if (email.isEmpty || !email.contains("@")) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please enter a valid email address"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isResetting = true);

                          final result = await _authService.resetPassword(email: email);

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (!context.mounted) return;

                          if (result == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Password reset email sent to $email! Please check your Inbox or Spam folder."),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: $result"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isResetting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Send Link"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xff1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

          child: Column(
            children: [
              const SizedBox(height: 20),

              // 3D Header
              const AuthHeader(
                title: "Welcome Back",
                subtitle: "Track your expenses and save more every month.",
              ),

              const SizedBox(height: 32),

              // 3D Perspective Hero Card
              ThreeDTiltCard(
                maxTiltAngle: 0.05,
                elevation: isDark ? 4 : 12,
                shadowColor: const Color(0xff1E3C72),
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthTextField(
                          controller: emailController,
                          hintText: "Email Address",
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter email";
                            }
                            if (!value.contains("@")) {
                              return "Enter valid email";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        AuthTextField(
                          controller: passwordController,
                          hintText: "Password",
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          maxLength: 12,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter password";
                            }
                            if (value.length < 8) {
                              return "Minimum 8 characters";
                            }
                            if (value.length > 12) {
                              return "Maximum 12 characters";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              activeColor: const Color(0xff11998E),
                              onChanged: (value) {
                                setState(() {
                                  rememberMe = value!;
                                });
                              },
                            ),

                            Text(
                              "Remember Me",
                              style: TextStyle(
                                color: isDark ? Colors.grey.shade300 : const Color(0xff2D3748),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const Spacer(),

                            TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: isDark ? const Color(0xff38EF7D) : const Color(0xff1E3C72),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        PrimaryButton(
                          text: "Login",
                          isLoading: isLoading,
                          onPressed: login,
                        ),

                        const SizedBox(height: 18),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white12 : Colors.grey.shade300,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                "OR",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white12 : Colors.grey.shade300,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Continue with Google Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: (isLoading || isGoogleLoading) ? null : handleGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xff162032) : Colors.white,
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.grey.shade300,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: isDark ? 0 : 1,
                              shadowColor: Colors.black.withValues(alpha: 0.05),
                            ),
                            child: isGoogleLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xff11998E),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/google.png',
                                        height: 22,
                                        width: 22,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.g_mobiledata, size: 28),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Continue with Google",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xff1E293B),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignupScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: isDark ? const Color(0xff38EF7D) : const Color(0xff1E3C72),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
