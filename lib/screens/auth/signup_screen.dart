import 'package:flutter/material.dart';

import '../../widgets/primary_button.dart';
import '../../widgets/three_d_tilt_card.dart';
import 'login_screen.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/password_strength_indicator.dart';
import '../../services/auth_service.dart';
import '../../utils/security_validator.dart';
import '../profile/terms_conditions_screen.dart';

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
  void initState() {
    super.initState();
    passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    passwordController.removeListener(_onPasswordChanged);
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

    // Sanitize inputs to prevent script injection / XSS
    final sanitizedName = SecurityValidator.sanitize(nameController.text);
    final sanitizedPhone = SecurityValidator.sanitize(phoneController.text);
    final sanitizedEmail = SecurityValidator.sanitize(emailController.text);

    setState(() => isLoading = true);

    final result = await _authService.signUp(
      fullName: sanitizedName,
      phone: sanitizedPhone,
      email: sanitizedEmail,
      password: passwordController.text,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account Created Successfully!"),
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
                          validator: SecurityValidator.validateName,
                        ),

                        const SizedBox(height: 16),

                        AuthTextField(
                          controller: phoneController,
                          hintText: "Phone Number",
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: SecurityValidator.validatePhone,
                        ),

                        const SizedBox(height: 16),

                        AuthTextField(
                          controller: emailController,
                          hintText: "Email Address",
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: SecurityValidator.validateEmail,
                        ),

                        const SizedBox(height: 16),

                        AuthTextField(
                          controller: passwordController,
                          hintText: "Password",
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          validator: SecurityValidator.validatePassword,
                        ),

                        // Interactive Password Strength Indicator & Requirements
                        PasswordStrengthIndicator(
                          password: passwordController.text,
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
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TermsConditionsScreen(),
                                    ),
                                  );
                                },
                                child: Text.rich(
                                  TextSpan(
                                    text: "I agree to the ",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : const Color(0xff2D3748),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: "Terms & Conditions",
                                        style: TextStyle(
                                          color: Color(0xff11998E),
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
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
