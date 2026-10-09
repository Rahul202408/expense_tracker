import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_analytics_service.dart';
import 'in_app_purchase_service.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static const String _prefIsLoggedIn = "is_user_logged_in";
  static const String _prefLastActiveTime = "last_active_time_ms";
  static const String _prefLastLoginTime = "last_login_time_ms";
  static const String _prefUserUid = "logged_user_uid";
  static const String _prefUserEmail = "logged_user_email";
  static const String _prefUserName = "logged_user_name";
  static const String _prefUserPhotoUrl = "logged_user_photo_url";

  /// Synchronous memory cache of the active session UID, Email, Name & Photo for immediate startup access
  static String? cachedUid;
  static String? cachedEmail;
  static String? cachedName;
  static String? cachedPhotoUrl;

  User? get currentUser => _auth.currentUser;

  /// Loads cached session from SharedPreferences on app launch
  static Future<void> initCachedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool(_prefIsLoggedIn) ?? false;
      if (isLoggedIn) {
        cachedUid = prefs.getString(_prefUserUid);
        cachedEmail = prefs.getString(_prefUserEmail);
        cachedName = prefs.getString(_prefUserName);
        cachedPhotoUrl = prefs.getString(_prefUserPhotoUrl);
      }
    } catch (_) {}
  }

  /// Records a successful login or signup session in persistent local storage
  Future<void> recordUserLoginSession(User user, {String? fullName}) async {
    try {
      cachedUid = user.uid;
      cachedEmail = user.email;

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setBool(_prefIsLoggedIn, true);
      await prefs.setInt(_prefLastActiveTime, now);
      await prefs.setInt(_prefLastLoginTime, now);
      await prefs.setString(_prefUserUid, user.uid);
      if (user.email != null && user.email!.isNotEmpty) {
        await prefs.setString(_prefUserEmail, user.email!);
      }

      // Resolve best available name
      String? resolvedName = fullName;
      if (resolvedName == null || resolvedName.trim().isEmpty) {
        if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
          resolvedName = user.displayName!.trim();
        }
      }
      if (resolvedName == null || resolvedName.trim().isEmpty) {
        resolvedName = prefs.getString(_prefUserName);
      }
      if (resolvedName == null || resolvedName.trim().isEmpty) {
        if (user.email != null && user.email!.isNotEmpty) {
          resolvedName = user.email!.split('@')[0];
        }
      }

      if (resolvedName != null && resolvedName.trim().isNotEmpty) {
        cachedName = resolvedName.trim();
        await prefs.setString(_prefUserName, cachedName!);
      }

      // Resolve best available photo URL
      final photo = user.photoURL ?? prefs.getString(_prefUserPhotoUrl);
      if (photo != null && photo.trim().isNotEmpty) {
        cachedPhotoUrl = photo.trim();
        await prefs.setString(_prefUserPhotoUrl, cachedPhotoUrl!);
      }

      // Ensure onboarding is marked completed so returning users bypass it
      await prefs.setBool("onboarding", true);

      FirebaseAnalyticsService().setUserId(user.uid);
      FirebaseAnalyticsService().logLogin("email_or_google");

      // Auto-heal and sync Firestore user profile in background
      _autoHealUserProfile(user, cachedName);
    } catch (_) {}
  }

  /// Auto-heals and synchronizes user profile data between Firebase Auth and Firestore
  Future<void> _autoHealUserProfile(User user, String? name) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      final currentFullName = data?['fullName']?.toString().trim();
      final currentEmail = data?['email']?.toString().trim();

      final Map<String, dynamic> updates = {};

      final healName = (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : ((user.displayName != null && user.displayName!.trim().isNotEmpty)
              ? user.displayName!.trim()
              : (user.email != null ? user.email!.split('@')[0] : ''));

      if ((currentFullName == null || currentFullName.isEmpty) && healName.isNotEmpty) {
        updates['fullName'] = healName;
        updates['displayName'] = healName;
      }

      if ((currentEmail == null || currentEmail.isEmpty) && user.email != null && user.email!.isNotEmpty) {
        updates['email'] = user.email!;
      }

      if (user.photoURL != null &&
          user.photoURL!.isNotEmpty &&
          (data?['photoUrl'] == null || data?['photoUrl'].toString().isEmpty == true)) {
        updates['photoUrl'] = user.photoURL!;
      }

      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(user.uid).set(updates, SetOptions(merge: true));
      }

      // If FirebaseAuth user profile is missing displayName, populate it
      if ((user.displayName == null || user.displayName!.trim().isEmpty) && healName.isNotEmpty) {
        try {
          await user.updateDisplayName(healName);
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Updates the last active timestamp whenever user uses the app
  Future<void> updateLastActiveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefLastActiveTime, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Attempts to silently re-authenticate a previously connected Google account
  /// and restores the active FirebaseAuth user session.
  Future<User?> trySilentGoogleSignIn() async {
    try {
      if (_auth.currentUser != null) {
        return _auth.currentUser;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            '567397044370-v3lldaotf0uuu3h5p3tbr0p4ul2o2ot7.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final restoredUser = userCredential.user;

      if (restoredUser != null) {
        final resolvedName = restoredUser.displayName ?? googleUser.displayName ?? "";
        await recordUserLoginSession(restoredUser, fullName: resolvedName);
        return restoredUser;
      }
    } catch (_) {}
    return null;
  }

  /// Checks if the user has an active, valid authentication session.
  /// Strictly requires a verified FirebaseAuth user. Never permits unauthenticated "ghost logins".
  Future<bool> isSessionValid() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await recordUserLoginSession(user);
        await updateLastActiveTime();
        return true;
      }

      // Wait briefly on authStateChanges for cold-boot token hydration
      try {
        user = await _auth.authStateChanges().firstWhere((u) => u != null).timeout(
          const Duration(milliseconds: 2000),
          onTimeout: () => null,
        );
      } catch (_) {}

      if (user != null) {
        await recordUserLoginSession(user);
        await updateLastActiveTime();
        return true;
      }

      // Attempt silent Google sign-in restoration
      user = await trySilentGoogleSignIn();
      if (user != null) {
        await updateLastActiveTime();
        return true;
      }

      // If Firebase Auth has NO authenticated user, clear stale local session flags
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefIsLoggedIn, false);
      return false;
    } catch (_) {
      return _auth.currentUser != null;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserData() async {
    User? user = _auth.currentUser;
    if (user == null) {
      try {
        user = await _auth.authStateChanges().firstWhere((u) => u != null).timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
      } catch (_) {}
    }
    if (user == null) {
      try {
        user = await trySilentGoogleSignIn();
      } catch (_) {}
    }
    final uid = user?.uid ?? _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).get();
  }

  Future<String?> signUp({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    String country = "India",
    String countryCode = "IN",
    String currencySymbol = "₹",
    String currencyCode = "INR",
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;

      if (user != null) {
        try {
          await user.updateDisplayName(fullName);
        } catch (_) {}

        // 1. Immediately record user login session locally
        await recordUserLoginSession(user, fullName: fullName);

        // 2. Persist profile to Firestore safely
        try {
          await _firestore.collection("users").doc(user.uid).set({
            "uid": user.uid,
            "fullName": fullName,
            "displayName": fullName,
            "phone": phone,
            "email": email,
            "country": country,
            "countryCode": countryCode,
            "currencySymbol": currencySymbol,
            "currencyCode": currencyCode,
            "isPro": false,
            "createdAt": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));
        } catch (e) {
          debugPrint("Non-blocking Firestore signup profile sync: $e");
        }
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseAuthError(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.updateDisplayName(fullName);
      } catch (_) {}

      await _firestore.collection("users").doc(user.uid).set({
        "fullName": fullName,
        "displayName": fullName,
        "phone": phone,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      cachedName = fullName;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefUserName, fullName);
      } catch (_) {}
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Fetch saved user data from Firestore to retrieve saved name
        try {
          final doc = await _firestore.collection("users").doc(credential.user!.uid).get();
          final savedName = doc.data()?['fullName']?.toString() ??
              doc.data()?['displayName']?.toString() ??
              doc.data()?['name']?.toString();

          if (savedName != null && savedName.trim().isNotEmpty) {
            try {
              await credential.user!.updateDisplayName(savedName.trim());
            } catch (_) {}
          }
          await recordUserLoginSession(credential.user!, fullName: savedName);
        } catch (_) {
          await recordUserLoginSession(credential.user!);
        }
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseAuthError(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseAuthError(e);
    } catch (e) {
      return e.toString();
    }
  }

  /// Maps cryptic FirebaseAuthException error codes to clean, actionable messages
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "No account found with this email. Please check your email or sign up.";
      case 'wrong-password':
      case 'invalid-credential':
        return "Invalid email or password credential. Please check and try again.";
      case 'email-already-in-use':
        return "This email address is already registered. Please sign in instead.";
      case 'weak-password':
        return "Password is too weak. Please use at least 6 characters.";
      case 'invalid-email':
        return "The email address is improperly formatted.";
      case 'network-request-failed':
        return "Network connection error. Please verify your internet connection.";
      case 'too-many-requests':
        return "Too many attempts. Access temporarily locked. Please try again later.";
      case 'user-disabled':
        return "This user account has been disabled. Please contact support.";
      default:
        return e.message ?? "An authentication error occurred. Please try again.";
    }
  }

  Future<String?> googleSignIn() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            '567397044370-v3lldaotf0uuu3h5p3tbr0p4ul2o2ot7.apps.googleusercontent.com',
      );

      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return "Google Sign-In Cancelled";
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      User? user = userCredential.user;

      if (user != null) {
        final resolvedName = user.displayName ?? googleUser.displayName ?? "";

        // 1. Immediately record login session in local storage
        await recordUserLoginSession(user, fullName: resolvedName);

        // 2. Merge user details into Firestore safely in background
        try {
          await _firestore.collection("users").doc(user.uid).set({
            "uid": user.uid,
            "fullName": resolvedName,
            "displayName": resolvedName,
            "phone": user.phoneNumber ?? "",
            "email": user.email ?? googleUser.email,
            "photoUrl": user.photoURL ?? googleUser.photoUrl ?? "",
            "country": "India",
            "countryCode": "IN",
            "currencySymbol": "₹",
            "currencyCode": "INR",
            "updatedAt": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));
        } catch (e) {
          debugPrint("Non-blocking Firestore user profile sync: $e");
        }
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    cachedUid = null;
    cachedEmail = null;
    cachedName = null;
    cachedPhotoUrl = null;

    try {
      await _auth.signOut();
    } catch (_) {}

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefIsLoggedIn, false);
      await prefs.remove(_prefLastActiveTime);
      await prefs.remove(_prefLastLoginTime);
      await prefs.remove(_prefUserUid);
      await prefs.remove(_prefUserEmail);
      await prefs.remove(_prefUserName);
      await prefs.remove(_prefUserPhotoUrl);
      await prefs.remove("is_pro_user");
      await prefs.remove("pro_plan_id");
      await prefs.remove("pro_purchase_date");
    } catch (_) {}

    try {
      await InAppPurchaseService().clearProStatusLocally();
    } catch (_) {}
  }
}