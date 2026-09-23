import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../providers/pro_provider.dart';
import '../../pro/pro_screen.dart';

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
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data();
        String name = "User";

        // Prioritize full name from Firestore database
        if (userData != null &&
            userData['fullName'] != null &&
            userData['fullName'].toString().trim().isNotEmpty) {
          name = userData['fullName'].toString().trim();
        } else if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
          name = user.displayName!.trim();
        }

        final photoUrl = (userData != null &&
                userData['photoUrl'] != null &&
                userData['photoUrl'].toString().isNotEmpty)
            ? userData['photoUrl'].toString()
            : (user.photoURL ?? '');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Branded 3D App Logo
                Container(
                  width: 46,
                  height: 46,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff10B981).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/app-logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
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

                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              "$name 👋",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Consumer<ProProvider>(
                            builder: (context, pro, _) {
                              if (pro.isPro) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xffF59E0B), Color(0xffD97706)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xffF59E0B).withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.white),
                                      SizedBox(width: 3),
                                      Text(
                                        "PRO",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ProScreen()),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffF59E0B).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xffF59E0B), width: 0.8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.workspace_premium_rounded, size: 13, color: Color(0xffF59E0B)),
                                      SizedBox(width: 3),
                                      Text(
                                        "GO PRO",
                                        style: TextStyle(
                                          color: Color(0xffF59E0B),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
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
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
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
      },
    );
  }
}
