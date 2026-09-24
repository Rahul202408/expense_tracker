import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current User ID
  String? get uid => _auth.currentUser?.uid;

  /// Transactions Collection Reference
  CollectionReference<Map<String, dynamic>>? get _transactionRef {
    final currentUid = uid;
    if (currentUid == null) return null;
    return _firestore.collection('users').doc(currentUid).collection('transactions');
  }

  /// Add Transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    final ref = _transactionRef;
    if (ref == null) return;
    await ref.add(transaction.toMap());
  }

  /// Get Transactions - Direct Firestore Stream
  /// Firestore SDK natively caches queries on-device and delivers the initial
  /// snapshot instantly to every StreamBuilder.
  Stream<List<TransactionModel>> getTransactions() {
    final ref = _transactionRef;
    if (ref == null) return const Stream.empty();

    return ref
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
    final ref = _transactionRef;
    if (ref == null) return;
    await ref.doc(transaction.id).update(transaction.toMap());
  }

  /// Delete Transaction
  Future<void> deleteTransaction(String id) async {
    final ref = _transactionRef;
    if (ref == null) return;
    await ref.doc(id).delete();
  }
}
