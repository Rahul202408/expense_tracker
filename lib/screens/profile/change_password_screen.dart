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

  @override
  void initState() {
    super.initState();
    newPasswordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  Future<void> changePassword() async {
    final currentPass = currentPasswordController.text.trim();
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (currentPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your current password")),
      );
      return;
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

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPass,
      );

      // Re-authenticate user
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPass);

      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password changed successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Authentication failed"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to change password"),
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
    return Scaffold(

      appBar: AppBar(
        title: const Text("Change Password"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: currentObscure,
              decoration: InputDecoration(
                labelText: "Current Password",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    currentObscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      currentObscure = !currentObscure;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: newPasswordController,
              obscureText: newObscure,
              decoration: InputDecoration(
                labelText: "New Password",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    newObscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      newObscure = !newObscure;
                    });
                  },
                ),
              ),
            ),

            PasswordStrengthIndicator(
              password: newPasswordController.text,
            ),

            const SizedBox(height: 20),

            TextField(
              controller: confirmPasswordController,
              obscureText: confirmObscure,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                prefixIcon: const Icon(Icons.lock_reset),
                suffixIcon: IconButton(
                  icon: Icon(
                    confirmObscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      confirmObscure = !confirmObscure;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff11998E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: isLoading ? null : changePassword,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Update Password",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

