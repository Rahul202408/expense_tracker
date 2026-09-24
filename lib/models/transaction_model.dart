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
    DateTime parsedDate;
    final rawDate = map['date'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    final rawAmount = map['amount'];
    double parsedAmount = 0.0;
    if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      parsedAmount = double.tryParse(rawAmount) ?? 0.0;
    }

    return TransactionModel(
      id: documentId,
      title: map['title']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Other',
      amount: parsedAmount,
      isExpense: map['isExpense'] is bool ? map['isExpense'] as bool : true,
      date: parsedDate,
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
