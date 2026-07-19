import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/core/data/backup_codec.dart';
import 'package:freegrid/core/domain/models.dart';
import 'package:freegrid/features/dashboard/first_record_date_resolver.dart';

void main() {
  group('first record date parity', () {
    test('declared iOS baseline wins over an earlier imported transaction', () {
      final data = BackupData(
        firstRecordDate: DateTime(2024, 9, 8),
        incomes: [Income(amount: 1, source: '工资', date: DateTime(2024, 9, 1))],
      );

      expect(
        resolveFirstRecordDate(data, DateTime(2026, 7, 14)),
        DateTime(2024, 9, 8),
      );
    });

    test('legacy data without a baseline infers the earliest transaction', () {
      final data = BackupData(
        expenses: [
          Expense(amount: 1, category: '其他', date: DateTime(2024, 9, 8)),
        ],
        incomes: [Income(amount: 1, source: '工资', date: DateTime(2024, 9, 1))],
      );

      expect(
        resolveFirstRecordDate(data, DateTime(2026, 7, 14)),
        DateTime(2024, 9, 1),
      );
    });

    test('a new backdated entry moves the declared baseline earlier', () {
      final data = BackupData(firstRecordDate: DateTime(2024, 9, 8));

      expect(
        resolveFirstRecordDateForMutation(data, DateTime(2024, 9, 1, 20)),
        DateTime(2024, 9, 1),
      );
      expect(
        resolveFirstRecordDateForMutation(data, DateTime(2026, 7, 14)),
        DateTime(2024, 9, 8),
      );
    });
  });
}
