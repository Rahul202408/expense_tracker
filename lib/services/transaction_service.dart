import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import '../models/transaction_model.dart';

class TransactionService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// In-memory cache of transactions to prevent flicker/reset between rebuilds
  static List<TransactionModel>? _cachedTransactions;
  static List<TransactionModel>? get cachedTransactions => _cachedTransactions;

  /// Current User ID
  String? get uid => _auth.currentUser?.uid ?? AuthService.cachedUid;

  /// Helper to resolve active authenticated user with graceful cold-boot wait and silent restore
  Future<User?> _resolveActiveUser() async {
    User? user = _auth.currentUser;
    if (user != null) return user;
    try {
      user = await _auth.authStateChanges().firstWhere((u) => u != null).timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
    } catch (_) {}
    if (user != null) return user;

    // Automatic silent Google re-authentication fallback
    try {
      user = await AuthService().trySilentGoogleSignIn();
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
    if (user == null) {
      throw Exception("User authentication required. Please log in.");
    }
    final activeUid = user.uid;
    
    final docRef = await _getTransactionRef(activeUid).add(transaction.toMap());

    // Optimistically update memory cache
    final newModel = TransactionModel(
      id: docRef.id,
      title: transaction.title,
      category: transaction.category,
      amount: transaction.amount,
      isExpense: transaction.isExpense,
      date: transaction.date,
    );
    if (_cachedTransactions != null) {
      _cachedTransactions = [newModel, ..._cachedTransactions!];
      _cachedTransactions!.sort((a, b) => b.date.compareTo(a.date));
    } else {
      _cachedTransactions = [newModel];
    }
  }

  /// One-time fetch from Firestore (useful for pull-to-refresh)
  Future<List<TransactionModel>> fetchTransactionsOnce() async {
    final user = await _resolveActiveUser();
    final activeUid = user?.uid ?? AuthService.cachedUid;
    if (activeUid == null) return _cachedTransactions ?? [];

    try {
      final snap = await _firestore
          .collection('users')
          .doc(activeUid)
          .collection('transactions')
          .get(const GetOptions(source: Source.serverAndCache));

      final list = snap.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      _cachedTransactions = list;
      return list;
    } catch (_) {
      return _cachedTransactions ?? [];
    }
  }

  /// Get Transactions - Resilient, Non-Terminating Realtime Stream
  /// 1. Emits cached memory transactions immediately if available (prevents zero-flash).
  /// 2. Listens to Firestore snapshots with double-fallback:
  ///    - First attempts orderBy('date', descending: true)
  ///    - If index is missing or field error occurs, falls back to un-ordered query and sorts in memory.
  /// 3. Listens to authStateChanges to seamlessly hook Firestore as soon as user token is ready.
  Stream<List<TransactionModel>> getTransactions() {
    late StreamController<List<TransactionModel>> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? authSub;
    Timer? initialFallbackTimer;
    bool hasEmittedFirstEvent = false;

    void startFirestoreListening(String userId, {bool useOrderBy = true}) {
      firestoreSub?.cancel();
      try {
        final query = useOrderBy
            ? _firestore
                .collection('users')
                .doc(userId)
                .collection('transactions')
                .orderBy('date', descending: true)
            : _firestore
                .collection('users')
                .doc(userId)
                .collection('transactions');

        firestoreSub = query.snapshots().listen(
          (snapshot) {
            hasEmittedFirstEvent = true;
            initialFallbackTimer?.cancel();

            final list = snapshot.docs
                .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
                .toList();

            // Always guarantee sorting in Dart memory
            list.sort((a, b) => b.date.compareTo(a.date));
            _cachedTransactions = list;

            if (!controller.isClosed) {
              controller.add(list);
            }
          },
          onError: (error) {
            debugPrint("Firestore getTransactions error (useOrderBy=$useOrderBy): $error");
            if (useOrderBy) {
              // Retry without orderBy in case composite index or type mismatch
              startFirestoreListening(userId, useOrderBy: false);
            } else {
              hasEmittedFirstEvent = true;
              initialFallbackTimer?.cancel();
              if (_cachedTransactions != null && !controller.isClosed) {
                controller.add(_cachedTransactions!);
              } else if (!controller.isClosed) {
                controller.add([]);
              }
            }
          },
        );
      } catch (e) {
        debugPrint("Firestore getTransactions exception: $e");
        if (useOrderBy) {
          startFirestoreListening(userId, useOrderBy: false);
        } else if (!controller.isClosed) {
          hasEmittedFirstEvent = true;
          initialFallbackTimer?.cancel();
          controller.add(_cachedTransactions ?? []);
        }
      }
    }

    void init() {
      // If we have cached transactions from earlier in this session, emit immediately
      if (_cachedTransactions != null && !controller.isClosed) {
        hasEmittedFirstEvent = true;
        controller.add(_cachedTransactions!);
      }

      final currentUser = _auth.currentUser;
      final cachedUid = AuthService.cachedUid;

      if (currentUser != null) {
        startFirestoreListening(currentUser.uid);
      } else if (cachedUid != null && cachedUid.isNotEmpty) {
        startFirestoreListening(cachedUid);
      }

      // Also listen to authStateChanges to seamlessly re-target if user session initializes
      authSub = _auth.authStateChanges().listen((user) {
        if (user != null) {
          startFirestoreListening(user.uid);
        }
      });

      // Failsafe timer: Guarantees that the stream NEVER hangs in infinite loading (max 3.5s)
      initialFallbackTimer = Timer(const Duration(milliseconds: 3500), () {
        if (!hasEmittedFirstEvent && !controller.isClosed) {
          hasEmittedFirstEvent = true;
          controller.add(_cachedTransactions ?? []);
        }
      });
    }

    controller = StreamController<List<TransactionModel>>.broadcast(
      onListen: init,
      onCancel: () {
        initialFallbackTimer?.cancel();
        firestoreSub?.cancel();
        authSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Clear in-memory transaction cache on logout or account deletion
  static void clearCache() {
    _cachedTransactions = null;
  }

  /// Update Transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    final user = await _resolveActiveUser();
    if (user == null) {
      throw Exception("User authentication required. Please log in.");
    }
    final activeUid = user.uid;
    await _getTransactionRef(activeUid).doc(transaction.id).update(transaction.toMap());

    if (_cachedTransactions != null) {
      final index = _cachedTransactions!.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _cachedTransactions![index] = transaction;
        _cachedTransactions!.sort((a, b) => b.date.compareTo(a.date));
      }
    }
  }

  /// Delete Transaction
  Future<void> deleteTransaction(String id) async {
    final user = await _resolveActiveUser();
    if (user == null) {
      throw Exception("User authentication required. Please log in.");
    }
    final activeUid = user.uid;
    await _getTransactionRef(activeUid).doc(id).delete();

    if (_cachedTransactions != null) {
      _cachedTransactions!.removeWhere((t) => t.id == id);
    }
  }
}
