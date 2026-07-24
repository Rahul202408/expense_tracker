import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> changePassword() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      if (newPasswordController.text.trim() !=
          confirmPasswordController.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New passwords do not match")),
        );
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text.trim(),
      );

      // Re-authenticate user
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPasswordController.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully")),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Something went wrong")),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to change password")),
      );
    }
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),

      body: Padding(
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
              height: 50,

              child: ElevatedButton(
                onPressed: () async {
                  await changePassword();
                },

                child: const Text("Update Password"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
