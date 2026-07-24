import 'package:flutter/material.dart';

import '../../widgets/primary_button.dart';
import '../../widgets/three_d_tilt_card.dart';
import 'login_screen.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool agree = false;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept Terms & Conditions")),
      );
      return;
    }

    setState(() => isLoading = true);

    final result = await _authService.signUp(
      fullName: nameController.text.trim(),
      phone: phoneController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account Created Successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.red),
      );
    }
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
                title: "Create Account",
                subtitle: "Start managing your money smartly today.",
              ),

              const SizedBox(height: 28),

              // 3D Hero Form Card
              ThreeDTiltCard(
                maxTiltAngle: 0.05,
                elevation: isDark ? 4 : 12,
                shadowColor: const Color(0xff11998E),
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
                          controller: nameController,
                          hintText: "Full Name",
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter your name";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        AuthTextField(
                          controller: phoneController,
                          hintText: "Phone Number",
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.length != 10) {
                              return "Enter valid 10-digit phone number";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        AuthTextField(
                          controller: emailController,
                          hintText: "Email Address",
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || !value.contains("@")) {
                              return "Enter valid email";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        AuthTextField(
                          controller: passwordController,
                          hintText: "Password",
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return "Minimum 6 characters";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        AuthTextField(
                          controller: confirmPasswordController,
                          hintText: "Confirm Password",
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          validator: (value) {
                            if (value != passwordController.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Checkbox(
                              value: agree,
                              activeColor: const Color(0xff11998E),
                              onChanged: (value) {
                                setState(() {
                                  agree = value!;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                "I agree to the Terms & Conditions",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade300
                                      : const Color(0xff2D3748),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        PrimaryButton(
                          text: "Create Account",
                          isLoading: isLoading,
                          onPressed: signup,
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
                    "Already have an account?",
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Login",
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
