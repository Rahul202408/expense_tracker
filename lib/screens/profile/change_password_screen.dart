import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../utils/security_validator.dart';
import '../auth/widgets/password_strength_indicator.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool currentObscure = true;
  bool newObscure = true;
  bool confirmObscure = true;
  bool isLoading = false;
  bool isResetSending = false;

  bool get _hasPasswordProvider {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  @override
  void initState() {
    super.initState();
    newPasswordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  Future<void> _sendPasswordResetEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    setState(() => isResetSending = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password reset email sent to ${user.email}! Check your inbox."),
          backgroundColor: const Color(0xff10B981),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send reset email: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isResetSending = false);
    }
  }

  Future<void> submitPassword() async {
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    // If user already has a password, current password is required
    if (_hasPasswordProvider) {
      final currentPass = currentPasswordController.text.trim();
      if (currentPass.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter your current password")),
        );
        return;
      }
    }

    final passwordError = SecurityValidator.validatePassword(newPass);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passwordError), backgroundColor: Colors.red),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New passwords do not match")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      if (_hasPasswordProvider) {
        // User already has a password -> reauthenticate and update
        final currentPass = currentPasswordController.text.trim();
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPass,
        );

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPass);

        if (!mounted) return;
        setState(() => isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password updated successfully! 🎉"),
            backgroundColor: Color(0xff10B981),
          ),
        );
        Navigator.pop(context);
      } else {
        // User signed up with Google -> Link email/password credential so both methods work
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: newPass,
        );

        await user.linkWithCredential(credential);

        if (!mounted) return;
        setState(() => isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password linked successfully! You can now log in with either Google or Password. 🎉"),
            backgroundColor: Color(0xff10B981),
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      String msg = e.message ?? "Authentication failed";
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        msg = "Current password is incorrect. You can use 'Forgot Password' below.";
      } else if (e.code == 'requires-recent-login') {
        msg = "This operation is sensitive and requires recent login. Please log in again.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    newPasswordController.removeListener(_onPasswordChanged);
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xff1E293B) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xff0F172A);
    final subtitleColor = isDark ? const Color(0xff94A3B8) : const Color(0xff64748B);
    final user = FirebaseAuth.instance.currentUser;
    final hasPassword = _hasPasswordProvider;

    return Scaffold(
      appBar: AppBar(
        title: Text(hasPassword ? "Change Password" : "Set Account Password"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasPassword
                      ? (isDark ? Colors.white12 : Colors.grey.shade300)
                      : const Color(0xff10B981).withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xff10B981).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasPassword ? Icons.security_rounded : Icons.link_rounded,
                      color: const Color(0xff10B981),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasPassword ? "Password Authentication" : "Google Linked Account",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasPassword
                              ? "Enter your current password to set a new password for ${user?.email ?? 'your account'}."
                              : "You are currently signed in with Google (${user?.email ?? ''}). Create a password below so you can sign in using EITHER Google OR Email & Password!",
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Current Password (only shown if user already has a password)
            if (hasPassword) ...[
              TextField(
                controller: currentPasswordController,
                obscureText: currentObscure,
                decoration: InputDecoration(
                  labelText: "Current Password",
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      currentObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    ),
                    onPressed: () => setState(() => currentObscure = !currentObscure),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isResetSending ? null : _sendPasswordResetEmail,
                  child: isResetSending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Forgot Current Password? Send reset email",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xff10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // New Password Field
            TextField(
              controller: newPasswordController,
              obscureText: newObscure,
              decoration: InputDecoration(
                labelText: hasPassword ? "New Password" : "Create Password",
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    newObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  ),
                  onPressed: () => setState(() => newObscure = !newObscure),
                ),
              ),
            ),

            PasswordStrengthIndicator(
              password: newPasswordController.text,
            ),

            const SizedBox(height: 20),

            // Confirm New Password Field
            TextField(
              controller: confirmPasswordController,
              obscureText: confirmObscure,
              decoration: InputDecoration(
                labelText: hasPassword ? "Confirm New Password" : "Confirm Password",
                prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    confirmObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  ),
                  onPressed: () => setState(() => confirmObscure = !confirmObscure),
                ),
              ),
            ),

            const SizedBox(height: 35),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff10B981),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                onPressed: isLoading ? null : submitPassword,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        hasPassword ? "Update Password" : "Set Account Password",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
