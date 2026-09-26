import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current User ID
  String? get uid => _auth.currentUser?.uid ?? AuthService.cachedUid;

  /// Helper to resolve active authenticated user with graceful cold-boot wait
  Future<User?> _resolveActiveUser() async {
    User? user = _auth.currentUser;
    if (user != null) return user;
    try {
      user = await _auth.authStateChanges().firstWhere((u) => u != null).timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
    } catch (_) {}
    return user ?? _auth.currentUser;
  }

  /// Transactions Collection Reference for a specific authenticated user
  CollectionReference<Map<String, dynamic>> _getTransactionRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('transactions');
  }

  /// Add Transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    final user = await _resolveActiveUser();
    if (user == null) return;
    await _getTransactionRef(user.uid).add(transaction.toMap());
  }

  /// Get Transactions - Direct Firestore Stream
  /// Automatically resolves active Firebase user if token is initializing,
  /// preventing PERMISSION_DENIED on cold boot.
  Stream<List<TransactionModel>> getTransactions() async* {
    User? user = _auth.currentUser;
    user ??= await _resolveActiveUser();

    final activeUid = user?.uid ?? _auth.currentUser?.uid ?? AuthService.cachedUid;
    if (activeUid == null) {
      yield [];
      return;
    }

    yield* _firestore
        .collection('users')
        .doc(activeUid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Update Transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    final user = await _resolveActiveUser();
    if (user == null) return;
    await _getTransactionRef(user.uid).doc(transaction.id).update(transaction.toMap());
  }

  /// Delete Transaction
  Future<void> deleteTransaction(String id) async {
    final user = await _resolveActiveUser();
    if (user == null) return;
    await _getTransactionRef(user.uid).doc(id).delete();
  }
}
