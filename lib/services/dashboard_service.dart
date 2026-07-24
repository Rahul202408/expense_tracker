import '../models/transaction_model.dart';

class DashboardService {
  double totalIncome(List<TransactionModel> transactions) {
    return transactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double totalExpense(List<TransactionModel> transactions) {
    return transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double totalBalance(List<TransactionModel> transactions) {
    return totalIncome(transactions) - totalExpense(transactions);
  }
}
