import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../providers/pro_provider.dart';
import '../../../services/auth_service.dart';
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
    final currentUid = user?.uid ?? AuthService.cachedUid;
    if (currentUid == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data();

        // Robust multi-tier name resolution cascade: Firestore -> FirebaseAuth -> Local Cache -> Email -> Fallback
        String resolvedName = "";
        if (userData != null &&
            userData['fullName'] != null &&
            userData['fullName'].toString().trim().isNotEmpty) {
          resolvedName = userData['fullName'].toString().trim();
        } else if (userData != null &&
            userData['displayName'] != null &&
            userData['displayName'].toString().trim().isNotEmpty) {
          resolvedName = userData['displayName'].toString().trim();
        } else if (userData != null &&
            userData['name'] != null &&
            userData['name'].toString().trim().isNotEmpty) {
          resolvedName = userData['name'].toString().trim();
        } else if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
          resolvedName = user.displayName!.trim();
        } else if (FirebaseAuth.instance.currentUser?.displayName != null &&
            FirebaseAuth.instance.currentUser!.displayName!.trim().isNotEmpty) {
          resolvedName = FirebaseAuth.instance.currentUser!.displayName!.trim();
        } else if (AuthService.cachedName != null &&
            AuthService.cachedName!.trim().isNotEmpty) {
          resolvedName = AuthService.cachedName!.trim();
        } else if (user?.email != null && user!.email!.isNotEmpty) {
          resolvedName = user.email!.split('@')[0];
        } else if (FirebaseAuth.instance.currentUser?.email != null &&
            FirebaseAuth.instance.currentUser!.email!.isNotEmpty) {
          resolvedName = FirebaseAuth.instance.currentUser!.email!.split('@')[0];
        } else if (userData != null &&
            userData['email'] != null &&
            userData['email'].toString().isNotEmpty) {
          resolvedName = userData['email'].toString().split('@')[0];
        } else if (AuthService.cachedEmail != null &&
            AuthService.cachedEmail!.isNotEmpty) {
          resolvedName = AuthService.cachedEmail!.split('@')[0];
        }

        final name = resolvedName.isNotEmpty ? resolvedName : "User";

        // Keep local in-memory cache synchronized with the latest resolved name
        if (resolvedName.isNotEmpty &&
            (AuthService.cachedName == null || AuthService.cachedName!.isEmpty)) {
          AuthService.cachedName = resolvedName;
        }

        // Robust multi-tier avatar photo resolution cascade
        String photoUrl = "";
        if (userData != null &&
            userData['photoUrl'] != null &&
            userData['photoUrl'].toString().trim().isNotEmpty) {
          photoUrl = userData['photoUrl'].toString().trim();
        } else if (user?.photoURL != null && user!.photoURL!.trim().isNotEmpty) {
          photoUrl = user.photoURL!.trim();
        } else if (FirebaseAuth.instance.currentUser?.photoURL != null &&
            FirebaseAuth.instance.currentUser!.photoURL!.trim().isNotEmpty) {
          photoUrl = FirebaseAuth.instance.currentUser!.photoURL!.trim();
        } else if (AuthService.cachedPhotoUrl != null &&
            AuthService.cachedPhotoUrl!.trim().isNotEmpty) {
          photoUrl = AuthService.cachedPhotoUrl!.trim();
        }

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
                      Consumer<ProProvider>(
                        builder: (context, pro, _) {
                          final isPro = pro.isPro;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPro
                                  ? const Color(0xffF59E0B).withValues(alpha: 0.15)
                                  : (isDark
                                      ? const Color(0xff38EF7D).withValues(alpha: 0.15)
                                      : const Color(0xff1E3C72).withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(12),
                              border: isPro
                                  ? Border.all(
                                      color: const Color(0xffF59E0B).withValues(alpha: 0.4),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Text(
                              isPro ? "${_getGreeting()} • VIP ✨" : _getGreeting(),
                              style: TextStyle(
                                color: isPro
                                    ? const Color(0xffF59E0B)
                                    : (isDark ? const Color(0xff38EF7D) : const Color(0xff1E3C72)),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        },
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
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xffF59E0B), Color(0xffFFD700), Color(0xffD97706)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xffF59E0B).withValues(alpha: 0.45),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("👑", style: TextStyle(fontSize: 12)),
                                      SizedBox(width: 4),
                                      Text(
                                        "VIP PRO",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.6,
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

                // Glowing User Avatar (Clickable to open Profile with Pro Aura)
                Consumer<ProProvider>(
                  builder: (context, pro, _) {
                    final isPro = pro.isPro;
                    return GestureDetector(
                      onTap: onProfileTap,
                      behavior: HitTestBehavior.opaque,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isPro
                                    ? const [Color(0xffF59E0B), Color(0xffFFD700), Color(0xffD97706)]
                                    : const [Color(0xff11998E), Color(0xff38EF7D)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isPro ? const Color(0xffFFD700) : const Color(0xff11998E))
                                      .withValues(alpha: isPro ? 0.45 : 0.3),
                                  blurRadius: isPro ? 14 : 10,
                                  spreadRadius: isPro ? 2 : 1,
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
                          if (isPro)
                            Positioned(
                              top: -6,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: const Color(0xff0B1329),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xffFFD700),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xffFFD700).withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  "👑",
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            )
                          else
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
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
