import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/utils/security_validator.dart';

void main() {
  group('TransactionModel Tests', () {
    test('TransactionModel toMap and fromMap serialization', () {
      final date = DateTime(2026, 1, 15, 10, 30);
      final model = TransactionModel(
        id: 'test_id_123',
        title: 'Coffee',
        category: 'Food',
        amount: 150.0,
        isExpense: true,
        date: date,
      );

      final map = model.toMap();
      expect(map['title'], 'Coffee');
      expect(map['category'], 'Food');
      expect(map['amount'], 150.0);
      expect(map['isExpense'], true);

      final reconstructed = TransactionModel.fromMap(map, 'test_id_123');
      expect(reconstructed.id, 'test_id_123');
      expect(reconstructed.title, 'Coffee');
      expect(reconstructed.category, 'Food');
      expect(reconstructed.amount, 150.0);
      expect(reconstructed.isExpense, true);
      expect(reconstructed.date.millisecondsSinceEpoch, date.millisecondsSinceEpoch);
    });
  });

  group('SecurityValidator Tests', () {
    test('sanitize strips harmful HTML tags', () {
      expect(SecurityValidator.sanitize('  Normal Text  '), 'Normal Text');
      expect(SecurityValidator.sanitize('<script>alert("xss")</script>'), 'alert("xss")');
    });

    test('validateEmail checks email format (null on valid, string on error)', () {
      expect(SecurityValidator.validateEmail('test@example.com'), isNull);
      expect(SecurityValidator.validateEmail('invalid-email'), isNotNull);
    });

    test('validatePhone checks valid Indian phone numbers', () {
      expect(SecurityValidator.validatePhone('9876543210'), isNotNull); // Sequential descending rejected
      expect(SecurityValidator.validatePhone('9825134769'), isNull); // Valid random mobile number
      expect(SecurityValidator.validatePhone('123'), isNotNull); // Too short
    });
  });
}
