import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/core/data/backup_codec.dart';
import 'package:freegrid/core/domain/models.dart';

void main() {
  group('BackupCodec', () {
    test('decodes iOS schema v1 snake_case backup', () {
      final backup = BackupCodec.decodeString('''
      {
        "schema_version": 1,
        "assets": {
          "total": 500,
          "locked_assets": 300,
          "cash": 200,
          "updated_at": "2026-05-25T08:55:55.159Z"
        },
        "expenses": [
          {
            "id": "a",
            "amount": 25.5,
            "category": "午餐",
            "date": "2026-01-15",
            "note": "ok",
            "created_at": "2026-01-15T10:00:00Z"
          }
        ],
        "incomes": [
          {
            "id": "b",
            "amount": 1600,
            "source": "工资",
            "date": "2026-01-15",
            "is_passive": false
          }
        ],
        "passive_sources": [
          {"name": "股息", "monthly_amount": 300}
        ],
        "first_record_date": "2026-01-01"
      }
      ''');

      expect(backup.schemaVersion, 1);
      expect(backup.assets?.lockedAssets, 300);
      expect(backup.assets?.cash, 200);
      expect(backup.expenses.single.category, '午餐');
      expect(backup.incomes.single.source, '工资');
      expect(backup.passiveSources.single.monthlyAmount, 300);
      expect(backup.firstRecordDate, DateTime(2026, 1, 1));
    });

    test('legacy assets without dual buckets fall back to cash bucket', () {
      final backup = BackupCodec.decodeString('''
      {"assets": {"total": 500}}
      ''');

      expect(backup.assets?.lockedAssets, 0);
      expect(backup.assets?.cash, 500);
    });

    test('encodes backup with stable schema and dual buckets', () {
      final json = BackupCodec.encodeString(
        BackupData(
          assets: const UserAssets(lockedAssets: 300, cash: 200),
          expenses: [
            Expense(
              id: 'expense-id',
              amount: 25.5,
              category: '午餐',
              date: DateTime(2026, 1, 15),
            ),
          ],
          passiveSources: const [PassiveSource(name: '股息', monthlyAmount: 300)],
          firstRecordDate: DateTime(2026, 1, 1),
        ),
      );
      final map = jsonDecode(json) as Map<String, Object?>;
      final assets = map['assets'] as Map<String, Object?>;

      expect(map['schema_version'], 1);
      expect(assets['total'], 500);
      expect(assets['locked_assets'], 300);
      expect(assets['cash'], 200);
      expect(map['first_record_date'], '2026-01-01');
    });
  });
}
