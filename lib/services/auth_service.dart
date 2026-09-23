import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_analytics_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _prefIsLoggedIn = "is_user_logged_in";
  static const String _prefLastActiveTime = "last_active_time_ms";
  static const String _prefLastLoginTime = "last_login_time_ms";
  static const String _prefUserUid = "logged_user_uid";
  static const String _prefUserEmail = "logged_user_email";

  User? get currentUser => _auth.currentUser;

  /// Records a successful login or signup session in persistent local storage
  Future<void> recordUserLoginSession(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setBool(_prefIsLoggedIn, true);
      await prefs.setInt(_prefLastActiveTime, now);
      await prefs.setInt(_prefLastLoginTime, now);
      await prefs.setString(_prefUserUid, user.uid);
      if (user.email != null && user.email!.isNotEmpty) {
        await prefs.setString(_prefUserEmail, user.email!);
      }
      // Ensure onboarding is marked completed so returning users bypass it
      await prefs.setBool("onboarding", true);

      FirebaseAnalyticsService().setUserId(user.uid);
      FirebaseAnalyticsService().logLogin("email_or_google");
    } catch (_) {}
  }

  /// Updates the last active timestamp whenever user uses the app
  Future<void> updateLastActiveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefLastActiveTime, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Checks if the user's login session is valid:
  /// - User must be marked as logged in
  /// - If user has not used the app for >= 30 days (1 month), session expires
  /// - Otherwise, refreshes the active timestamp and returns true
  Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool(_prefIsLoggedIn) ?? false;
      if (!isLoggedIn) return false;

      final int? lastActiveMs = prefs.getInt(_prefLastActiveTime);
      if (lastActiveMs == null) {
        await updateLastActiveTime();
        return true;
      }

      final lastActiveDate = DateTime.fromMillisecondsSinceEpoch(lastActiveMs);
      final daysSinceLastActive = DateTime.now().difference(lastActiveDate).inDays;

      // Inactivity threshold: 30 days (1 month)
      if (daysSinceLastActive >= 30) {
        // Session expired due to 1 month inactivity
        await logout();
        return false;
      }

      // App used within 30 days: keep session alive & refresh active time
      await updateLastActiveTime();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid).get();
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

        await _firestore.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "fullName": fullName,
          "phone": phone,
          "email": email,
          "country": country,
          "countryCode": countryCode,
          "currencySymbol": currencySymbol,
          "currencyCode": currencyCode,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
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

      await _firestore.collection("users").doc(user.uid).update({
        "fullName": fullName,
        "phone": phone,
      });
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
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
        final doc = await _firestore.collection("users").doc(user.uid).get();

        if (!doc.exists) {
          await _firestore.collection("users").doc(user.uid).set({
            "uid": user.uid,
            "fullName": user.displayName ?? "",
            "phone": user.phoneNumber ?? "",
            "email": user.email ?? "",
            "photoUrl": user.photoURL ?? "",
            "country": "India",
            "countryCode": "IN",
            "currencySymbol": "₹",
            "currencyCode": "INR",
            "createdAt": FieldValue.serverTimestamp(),
          });
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
    } catch (_) {}
  }
}