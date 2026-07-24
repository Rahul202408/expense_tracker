import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String fullName;
  final String phone;

  const EditProfileScreen({
    super.key,
    required this.fullName,
    required this.phone,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService authService = AuthService();

  late TextEditingController nameController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.fullName);

    phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Phone Number"),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () async {
                  await authService.updateProfile(
                    fullName: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                  );

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Profile Updated Successfully"),
                    ),
                  );

                  Navigator.pop(context, true);
                },

                child: const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
