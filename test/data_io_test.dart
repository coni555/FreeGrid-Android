import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/core/data/backup_codec.dart';
import 'package:freegrid/core/data/data_io.dart';
import 'package:freegrid/core/domain/models.dart';

void main() {
  group('DataIO', () {
    final data = BackupData(
      schemaVersion: 1,
      assets: const UserAssets(lockedAssets: 300, cash: 200),
      expenses: [
        Expense(
          id: 'expense-1',
          amount: 12,
          category: '午餐,工作餐',
          note: '他说"很好"\n第二行',
          date: DateTime(2026, 7, 2),
        ),
      ],
      incomes: [
        Income(
          id: 'income-1',
          amount: 1600.5,
          source: '工资',
          date: DateTime(2026, 7, 1),
        ),
      ],
      firstRecordDate: DateTime(2026, 7, 1),
    );

    test(
      'CSV matches iOS header, BOM, sorting, escaping and amount format',
      () {
        final bytes = DataIO.exportCsv(data);

        expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
        final csv = utf8.decode(bytes);
        // Dart 的 UTF-8 decoder 会消费 BOM；BOM 已在上面的原始字节断言验证。
        expect(csv, startsWith('日期,类型,类别/来源,金额,备注\n'));
        expect(csv, contains('2026-07-01,收入,工资,1600.5,\n'));
        expect(csv, contains('2026-07-02,支出,"午餐,工作餐",12,"他说""很好""\n第二行"\n'));
      },
    );

    test('JSON export round-trips through BackupCodec without data loss', () {
      final exported = utf8.decode(DataIO.exportJson(data));
      final decoded = BackupCodec.decodeString(exported);

      expect(decoded.schemaVersion, 1);
      expect(decoded.assets?.lockedAssets, 300);
      expect(decoded.assets?.cash, 200);
      expect(decoded.expenses.single.id, 'expense-1');
      expect(decoded.expenses.single.note, '他说"很好"\n第二行');
      expect(decoded.incomes.single.id, 'income-1');
      expect(decoded.firstRecordDate, DateTime(2026, 7, 1));
    });

    test('uses stable iOS-compatible names and mime types', () {
      final now = DateTime(2026, 7, 14);
      expect(
        DataIO.fileName(DataExportFormat.csv, now: now),
        'FreeGrid-记账-20260714.csv',
      );
      expect(
        DataIO.fileName(DataExportFormat.json, now: now),
        'FreeGrid-备份-20260714.json',
      );
      expect(DataIO.mimeType(DataExportFormat.csv), 'text/csv');
      expect(DataIO.mimeType(DataExportFormat.json), 'application/json');
    });
  });
}
