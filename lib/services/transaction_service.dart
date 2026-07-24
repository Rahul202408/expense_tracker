import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current User ID
  String get uid => _auth.currentUser!.uid;

  /// Transactions Collection Reference
  CollectionReference<Map<String, dynamic>> get _transactionRef {
    return _firestore.collection('users').doc(uid).collection('transactions');
  }

  /// Add Transaction
  // Future<void> addTransaction(TransactionModel transaction) async {
  //   await _transactionRef.add(transaction.toMap());
  // }
  Future<void> addTransaction(TransactionModel transaction) async {
    print("UID: $uid");
    print("PATH: users/$uid/transactions");

    await _transactionRef.add(transaction.toMap());

    print("Transaction Added Successfully");
  }

  /// Get Transactions
  Stream<List<TransactionModel>> getTransactions() {
    return _transactionRef
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
    await _transactionRef.doc(transaction.id).update(transaction.toMap());
  }

  /// Delete Transaction
  Future<void> deleteTransaction(String id) async {
    await _transactionRef.doc(id).delete();
  }
}
