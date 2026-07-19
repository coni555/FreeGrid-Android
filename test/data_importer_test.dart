import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/core/data/backup_codec.dart';
import 'package:freegrid/core/data/data_importer.dart';
import 'package:freegrid/core/domain/models.dart';

void main() {
  const expenseUuid = '2F4A22D0-7E26-4B74-A0A6-5C1E24D8D8C1';
  const incomeUuid = '94C824B0-D893-4521-8D4E-F9E756DE4372';

  group('DataImporter preview', () {
    test('decodes selected file bytes explicitly as UTF-8', () {
      final preview = DataImporter.previewJsonBytes(
        current: const BackupData(),
        bytes: utf8.encode('''
        {
          "expenses": [{
            "amount": 10513,
            "category": "数码",
            "date": "2026-01-01"
          }]
        }
        '''),
      );

      expect(preview.expensesNew.single.category, '数码');
      expect(preview.categoryEntries.single.raw, '数码');
      expect(preview.categoryEntries.single.canonical, '购物');
    });

    test('uses valid UUIDs for exact expense and income deduplication', () {
      final current = BackupData(
        expenses: [
          Expense(
            id: expenseUuid.toLowerCase(),
            amount: 1,
            category: '早餐',
            date: DateTime(2026, 1, 1),
          ),
        ],
        incomes: [
          Income(
            id: incomeUuid.toLowerCase(),
            amount: 1,
            source: '旧来源',
            date: DateTime(2026, 1, 1),
          ),
        ],
      );

      final preview = DataImporter.previewJson(
        current: current,
        source:
            '''
        {
          "expenses": [{
            "id": "$expenseUuid",
            "amount": 999,
            "category": "购物",
            "date": "2026-06-01"
          }],
          "incomes": [{
            "id": "$incomeUuid",
            "amount": 999,
            "source": "新来源",
            "date": "2026-06-01"
          }]
        }
        ''',
      );

      expect(preview.expensesNew, isEmpty);
      expect(preview.incomesNew, isEmpty);
      expect(preview.expensesSkipped, 1);
      expect(preview.incomesSkipped, 1);
    });

    test('falls back to natural-day content fingerprints without UUIDs', () {
      final current = BackupData(
        expenses: [
          Expense(
            amount: 25.5,
            category: '午餐',
            note: '面馆',
            date: DateTime(2026, 1, 15, 23, 40),
          ),
        ],
        incomes: [
          Income(
            amount: 1600,
            source: '稿费',
            note: '一月',
            date: DateTime(2026, 1, 15, 8),
          ),
        ],
      );

      final preview = DataImporter.previewJson(
        current: current,
        source: '''
        {
          "expenses": [{
            "amount": 25.5,
            "category": "午餐",
            "date": "2026-01-15",
            "note": "面馆"
          }],
          "incomes": [{
            "amount": 1600,
            "source": "稿费",
            "date": "2026-01-15",
            "note": "一月"
          }]
        }
        ''',
      );

      expect(preview.totalAdded, 0);
      expect(preview.totalSkipped, 2);
    });

    test('keeps identical rows inside one backup as separate transactions', () {
      final preview = DataImporter.previewJson(
        current: const BackupData(),
        source: '''
        {
          "expenses": [
            {"amount": 8, "category": "晚餐", "date": "2026-01-15"},
            {"amount": 8, "category": "晚餐", "date": "2026-01-15"}
          ]
        }
        ''',
      );

      expect(preview.expensesNew, hasLength(2));
      expect(preview.expensesSkipped, 0);
    });

    test('aggregates non-canonical categories by total descending', () {
      final preview = DataImporter.previewJson(
        current: const BackupData(),
        source: '''
        {
          "expenses": [
            {"amount": 30, "category": "food", "date": "2026-01-01"},
            {"amount": 20, "category": "food", "date": "2026-01-02"},
            {"amount": 90, "category": "shopping", "date": "2026-01-03"},
            {"amount": 10, "category": "早餐", "date": "2026-01-04"}
          ]
        }
        ''',
      );

      expect(preview.categoryEntries.map((item) => item.raw), [
        'shopping',
        'food',
      ]);
      expect(preview.categoryEntries.first.total, 90);
      expect(preview.categoryEntries.first.canonical, '购物');
      expect(preview.categoryEntries.first.needsReview, isFalse);
      expect(preview.categoryEntries.last.count, 2);
      expect(preview.categoryEntries.last.needsReview, isTrue);
    });
  });

  group('DataImporter commit', () {
    final current = BackupData(
      schemaVersion: 1,
      assets: UserAssets(
        lockedAssets: 300,
        cash: 200,
        updatedAt: DateTime.utc(2026, 1, 10),
        firstRecordDate: DateTime(2026, 1, 1),
      ),
      firstRecordDate: DateTime(2026, 1, 1),
    );
    const dualBucketSource = '''
    {
      "schema_version": 1,
      "assets": {
        "total": 1000,
        "locked_assets": 700,
        "cash": 300,
        "updated_at": "2025-12-31T10:00:00Z"
      },
      "first_record_date": "2025-12-01"
    }
    ''';

    test('replace restores schema v1 dual buckets and imported baseline', () {
      final preview = DataImporter.previewJson(
        source: dualBucketSource,
        current: current,
      );
      final result = DataImporter.commitImport(
        preview: preview,
        current: current,
        strategy: AssetsImportStrategy.replace,
        now: DateTime.utc(2026, 2, 1),
      );

      expect(result.data.assets?.lockedAssets, 700);
      expect(result.data.assets?.cash, 300);
      expect(result.data.assets?.updatedAt, DateTime.utc(2025, 12, 31, 10));
      expect(result.data.firstRecordDate, DateTime(2025, 12, 1));
    });

    test('addToCash keeps locked assets and adds imported total to cash', () {
      final preview = DataImporter.previewJson(
        source: dualBucketSource,
        current: current,
      );
      final now = DateTime.utc(2026, 2, 1);
      final result = DataImporter.commitImport(
        preview: preview,
        current: current,
        strategy: AssetsImportStrategy.addToCash,
        now: now,
      );

      expect(result.data.assets?.lockedAssets, 300);
      expect(result.data.assets?.cash, 1200);
      expect(result.data.assets?.updatedAt, now);
      expect(result.data.firstRecordDate, DateTime(2025, 12, 1));
    });

    test('skipAssets leaves both buckets and updatedAt unchanged', () {
      final preview = DataImporter.previewJson(
        source: dualBucketSource,
        current: current,
      );
      final result = DataImporter.commitImport(
        preview: preview,
        current: current,
        strategy: AssetsImportStrategy.skipAssets,
        now: DateTime.utc(2026, 2, 1),
      );

      expect(result.data.assets?.lockedAssets, 300);
      expect(result.data.assets?.cash, 200);
      expect(result.data.assets?.updatedAt, DateTime.utc(2026, 1, 10));
      expect(result.data.firstRecordDate, DateTime(2025, 12, 1));
    });

    test('merge strategies keep the earliest local transaction baseline', () {
      final local = BackupData(
        expenses: [
          Expense(amount: 10, category: '早餐', date: DateTime(2024, 3, 2, 18)),
        ],
      );
      final preview = DataImporter.previewJson(
        current: local,
        source: '''
        {
          "assets": {"total": 100},
          "first_record_date": "2025-01-01"
        }
        ''',
      );
      final result = DataImporter.commitImport(
        preview: preview,
        current: local,
        strategy: AssetsImportStrategy.skipAssets,
      );

      expect(result.data.firstRecordDate, DateTime(2024, 3, 2));
      expect(result.data.assets?.firstRecordDate, DateTime(2024, 3, 2));
    });

    test('legacy no-schema total replaces into cash-only bucket', () {
      final preview = DataImporter.previewJson(
        source: '{"assets":{"total":500}}',
        current: current,
      );
      final result = DataImporter.commitImport(
        preview: preview,
        current: current,
        strategy: AssetsImportStrategy.replace,
      );

      expect(preview.sourceData.schemaVersion, isNull);
      expect(preview.jsonLockedAssets, isNull);
      expect(preview.jsonCash, isNull);
      expect(result.data.assets?.lockedAssets, 0);
      expect(result.data.assets?.cash, 500);
    });

    test('normalizes category, preserves UUID and records original label', () {
      final preview = DataImporter.previewJson(
        current: const BackupData(),
        source:
            '''
        {
          "expenses": [{
            "id": "$expenseUuid",
            "amount": 88,
            "category": "food",
            "date": "2026-01-15",
            "note": "朋友聚餐",
            "created_at": "2026-01-15T10:00:00Z"
          }]
        }
        ''',
      );
      final result = DataImporter.commitImport(
        preview: preview,
        current: const BackupData(),
        strategy: AssetsImportStrategy.skipAssets,
        categoryMap: const {'food': '晚餐'},
      );
      final expense = result.data.expenses.single;

      expect(expense.id, expenseUuid);
      expect(expense.category, '晚餐');
      expect(expense.note, '朋友聚餐 · 原分类·food');
      expect(expense.createdAt, DateTime.utc(2026, 1, 15, 10));
      expect(result.expensesAdded, 1);
    });

    test('committed UUID import is idempotent on the next preview', () {
      final firstPreview = DataImporter.previewJson(
        current: const BackupData(),
        source:
            '''
        {"expenses":[{
          "id":"$expenseUuid",
          "amount":20,
          "category":"午餐",
          "date":"2026-01-15"
        }]}
        ''',
      );
      final committed = DataImporter.commitImport(
        preview: firstPreview,
        current: const BackupData(),
        strategy: AssetsImportStrategy.skipAssets,
      ).data;
      final secondPreview = DataImporter.previewJson(
        current: committed,
        source: BackupCodec.encodeString(firstPreview.sourceData),
      );

      expect(secondPreview.expensesNew, isEmpty);
      expect(secondPreview.expensesSkipped, 1);
    });

    test(
      'mapped legacy category remains idempotent through note provenance',
      () {
        const source = '''
      {"expenses":[{
        "amount":20,
        "category":"food",
        "date":"2026-01-15",
        "note":"聚餐"
      }]}
      ''';
        final firstPreview = DataImporter.previewJson(
          current: const BackupData(),
          source: source,
        );
        final committed = DataImporter.commitImport(
          preview: firstPreview,
          current: const BackupData(),
          strategy: AssetsImportStrategy.skipAssets,
          categoryMap: const {'food': '晚餐'},
        ).data;
        final secondPreview = DataImporter.previewJson(
          current: committed,
          source: source,
        );

        expect(committed.expenses.single.note, '聚餐 · 原分类·food');
        expect(secondPreview.expensesNew, isEmpty);
        expect(secondPreview.expensesSkipped, 1);
      },
    );
  });
}
