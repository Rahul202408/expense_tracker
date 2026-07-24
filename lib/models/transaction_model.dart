import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final bool isExpense;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.isExpense,
    required this.date,
  });

  /// Firestore → Model
  factory TransactionModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return TransactionModel(
      id: documentId,
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      isExpense: map['isExpense'] ?? true,
      date: (map['date'] as Timestamp).toDate(),
    );
  }

  /// Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'isExpense': isExpense,
      'date': Timestamp.fromDate(date),
    };
  }
}
