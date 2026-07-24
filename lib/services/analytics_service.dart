import '../models/transaction_model.dart';

class AnalyticsService {
  Map<String, double> categoryTotals(List<TransactionModel> transactions) {
    final Map<String, double> data = {};

    for (final transaction in transactions) {
      if (!transaction.isExpense) continue;

      data.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    return data;
  }
}
