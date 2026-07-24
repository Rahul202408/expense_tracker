import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current User
  User? get currentUser => _auth.currentUser;

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  // ----------------------------
  // SIGN UP
  // ----------------------------
  Future<String?> signUp({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;

      if (user != null) {
        await _firestore.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "fullName": fullName,
          "phone": phone,
          "email": email,
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
    final uid = _auth.currentUser!.uid;

    await _firestore.collection("users").doc(uid).update({
      "fullName": fullName,
      "phone": phone,
    });
  }

  // ----------------------------
  // LOGIN
  // ----------------------------
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ----------------------------
  // RESET PASSWORD
  // ----------------------------
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

  // ----------------------------
  // GOOGLE SIGN IN
  // ----------------------------
  Future<String?> googleSignIn() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

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

  // ----------------------------
  // LOGOUT
  // ----------------------------
  Future<void> logout() async {
    await _auth.signOut();
  }
}
