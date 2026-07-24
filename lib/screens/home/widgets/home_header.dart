import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback? onProfileTap;

  const HomeHeader({super.key, this.onProfileTap});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning ☀️";
    } else if (hour < 17) {
      return "Good Afternoon 🌤️";
    } else {
      return "Good Evening 🌙";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xff1A202C);

    final user = FirebaseAuth.instance.currentUser;
    String name = "User";

    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      name = user.displayName!;
    } else if (user?.email != null) {
      name = user!.email!.split("@")[0];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xff38EF7D).withValues(alpha: 0.15)
                          : const Color(0xff1E3C72).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getGreeting(),
                      style: TextStyle(
                        color: isDark ? const Color(0xff38EF7D) : const Color(0xff1E3C72),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "$name 👋",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Glowing User Avatar (Clickable to open Profile)
            GestureDetector(
              onTap: onProfileTap,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xff11998E), Color(0xff38EF7D)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff11998E).withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.photoURL != null &&
                              user!.photoURL!.isNotEmpty
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: user?.photoURL == null || user!.photoURL!.isEmpty
                          ? const Icon(
                              Icons.person_rounded,
                              size: 28,
                              color: Color(0xff1E3C72),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xff00E676),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
