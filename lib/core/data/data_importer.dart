import 'dart:convert';

import '../domain/expense_category.dart';
import '../domain/models.dart';
import 'backup_codec.dart';

enum AssetsImportStrategy { replace, addToCash, skipAssets }

class CategoryMapEntry {
  const CategoryMapEntry({
    required this.raw,
    required this.count,
    required this.total,
    required this.canonical,
    required this.needsReview,
  });

  final String raw;
  final int count;
  final double total;
  final String canonical;
  final bool needsReview;
}

class ImportPreview {
  const ImportPreview({
    required this.sourceData,
    required this.expensesNew,
    required this.expensesSkipped,
    required this.incomesNew,
    required this.incomesSkipped,
    required this.passiveSourcesNew,
    required this.passiveSourcesSkipped,
    required this.hasAssets,
    required this.jsonAssetsTotal,
    required this.jsonLockedAssets,
    required this.jsonCash,
    required this.jsonAssetsUpdatedAt,
    required this.jsonFirstRecordDate,
    required this.currentCash,
    required this.currentLockedAssets,
    required this.categoryEntries,
  });

  final BackupData sourceData;
  final List<Expense> expensesNew;
  final int expensesSkipped;
  final List<Income> incomesNew;
  final int incomesSkipped;
  final List<PassiveSource> passiveSourcesNew;
  final int passiveSourcesSkipped;
  final bool hasAssets;
  final double jsonAssetsTotal;
  final double? jsonLockedAssets;
  final double? jsonCash;
  final DateTime? jsonAssetsUpdatedAt;
  final DateTime? jsonFirstRecordDate;
  final double currentCash;
  final double currentLockedAssets;
  final List<CategoryMapEntry> categoryEntries;

  int get totalAdded =>
      expensesNew.length + incomesNew.length + passiveSourcesNew.length;

  int get totalSkipped =>
      expensesSkipped + incomesSkipped + passiveSourcesSkipped;
}

class ImportResult {
  const ImportResult({
    required this.data,
    required this.expensesAdded,
    required this.incomesAdded,
    required this.passiveSourcesAdded,
    required this.duplicatesSkipped,
  });

  final BackupData data;
  final int expensesAdded;
  final int incomesAdded;
  final int passiveSourcesAdded;
  final int duplicatesSkipped;

  int get totalAdded => expensesAdded + incomesAdded + passiveSourcesAdded;
}

class DataImporter {
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static ImportPreview previewJsonBytes({
    required List<int> bytes,
    required BackupData current,
  }) {
    return previewJson(source: utf8.decode(bytes), current: current);
  }

  static ImportPreview previewJson({
    required String source,
    required BackupData current,
  }) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('FreeGrid backup must be a JSON object.');
    }
    final raw = decoded.cast<String, Object?>();
    final imported = BackupCodec.decodeMap(raw);

    final existingExpenseIds = current.expenses
        .map((item) => _validUuid(item.id))
        .whereType<String>()
        .toSet();
    final existingExpenseKeys = current.expenses.expand(_expenseKeys).toSet();
    final expensesNew = <Expense>[];
    var expensesSkipped = 0;
    for (final expense in imported.expenses) {
      final uuid = _validUuid(expense.id);
      final duplicate = uuid != null
          ? existingExpenseIds.contains(uuid)
          : existingExpenseKeys.contains(_expenseKey(expense));
      if (duplicate) {
        expensesSkipped += 1;
      } else {
        expensesNew.add(expense);
      }
    }

    final existingIncomeIds = current.incomes
        .map((item) => _validUuid(item.id))
        .whereType<String>()
        .toSet();
    final existingIncomeKeys = current.incomes.map(_incomeKey).toSet();
    final incomesNew = <Income>[];
    var incomesSkipped = 0;
    for (final income in imported.incomes) {
      final uuid = _validUuid(income.id);
      final duplicate = uuid != null
          ? existingIncomeIds.contains(uuid)
          : existingIncomeKeys.contains(_incomeKey(income));
      if (duplicate) {
        incomesSkipped += 1;
      } else {
        incomesNew.add(income);
      }
    }

    final existingPassiveKeys = current.passiveSources.map(_passiveKey).toSet();
    final passiveSourcesNew = <PassiveSource>[];
    var passiveSourcesSkipped = 0;
    for (final source in imported.passiveSources) {
      final key = _passiveKey(source);
      if (existingPassiveKeys.contains(key)) {
        passiveSourcesSkipped += 1;
      } else {
        passiveSourcesNew.add(source);
      }
    }

    final categoryTotals = <String, ({int count, double total})>{};
    for (final expense in expensesNew) {
      final rawCategory = expense.category.trim();
      if (ExpenseCategory.canonical.contains(rawCategory)) continue;
      final previous = categoryTotals[rawCategory];
      categoryTotals[rawCategory] = (
        count: (previous?.count ?? 0) + 1,
        total: (previous?.total ?? 0) + expense.amount,
      );
    }
    final categoryEntries = categoryTotals.entries.map((entry) {
      final suggestion = ExpenseCategory.suggest(entry.key);
      return CategoryMapEntry(
        raw: entry.key,
        count: entry.value.count,
        total: entry.value.total,
        canonical: suggestion.canonical,
        needsReview: !suggestion.known,
      );
    }).toList()..sort((a, b) => b.total.compareTo(a.total));

    final assetsRaw = _map(raw['assets']);
    final importedAssets = imported.assets;
    final total = _double(assetsRaw?['total']) ?? importedAssets?.netWorth ?? 0;

    return ImportPreview(
      sourceData: imported,
      expensesNew: List.unmodifiable(expensesNew),
      expensesSkipped: expensesSkipped,
      incomesNew: List.unmodifiable(incomesNew),
      incomesSkipped: incomesSkipped,
      passiveSourcesNew: List.unmodifiable(passiveSourcesNew),
      passiveSourcesSkipped: passiveSourcesSkipped,
      hasAssets: assetsRaw != null,
      jsonAssetsTotal: total,
      jsonLockedAssets: _double(assetsRaw?['locked_assets']),
      jsonCash: _double(assetsRaw?['cash']),
      jsonAssetsUpdatedAt: importedAssets?.updatedAt,
      jsonFirstRecordDate: imported.firstRecordDate,
      currentCash: current.assets?.cash ?? 0,
      currentLockedAssets: current.assets?.lockedAssets ?? 0,
      categoryEntries: List.unmodifiable(categoryEntries),
    );
  }

  static ImportResult commitImport({
    required ImportPreview preview,
    required BackupData current,
    required AssetsImportStrategy strategy,
    Map<String, String> categoryMap = const {},
    DateTime? now,
  }) {
    final importedExpenses = preview.expensesNew.map((expense) {
      final rawCategory = expense.category.trim();
      final requested = categoryMap[rawCategory];
      final mappedCategory =
          requested != null && ExpenseCategory.canonical.contains(requested)
          ? requested
          : ExpenseCategory.suggest(rawCategory).canonical;
      final note = mappedCategory == rawCategory
          ? expense.note
          : expense.note.isEmpty
          ? '原分类·$rawCategory'
          : '${expense.note} · 原分类·$rawCategory';
      return Expense(
        id: expense.id,
        amount: expense.amount,
        category: mappedCategory,
        note: note,
        date: expense.date,
        createdAt: expense.createdAt,
      );
    }).toList();

    final currentFirstRecordDate = _currentFirstRecordDate(current);
    final mergedFirstRecordDate = _earlier(
      currentFirstRecordDate,
      preview.jsonFirstRecordDate,
    );
    final timestamp = now ?? DateTime.now();
    final currentAssets = current.assets ?? const UserAssets();

    final UserAssets nextAssets;
    final DateTime? nextFirstRecordDate;
    switch (strategy) {
      case AssetsImportStrategy.replace:
        final hasDualBuckets =
            preview.jsonLockedAssets != null && preview.jsonCash != null;
        final locked = hasDualBuckets ? preview.jsonLockedAssets! : 0.0;
        final cash = hasDualBuckets
            ? preview.jsonCash!
            : preview.jsonAssetsTotal;
        nextFirstRecordDate =
            preview.jsonFirstRecordDate ?? currentFirstRecordDate;
        nextAssets = UserAssets(
          total: locked + cash,
          lockedAssets: locked,
          cash: cash,
          updatedAt: preview.jsonAssetsUpdatedAt ?? timestamp,
          firstRecordDate: nextFirstRecordDate,
        );
      case AssetsImportStrategy.addToCash:
        nextFirstRecordDate = mergedFirstRecordDate;
        nextAssets = UserAssets(
          total:
              currentAssets.lockedAssets +
              currentAssets.cash +
              preview.jsonAssetsTotal,
          lockedAssets: currentAssets.lockedAssets,
          cash: currentAssets.cash + preview.jsonAssetsTotal,
          updatedAt: timestamp,
          firstRecordDate: nextFirstRecordDate,
        );
      case AssetsImportStrategy.skipAssets:
        nextFirstRecordDate = mergedFirstRecordDate;
        nextAssets = UserAssets(
          total: currentAssets.netWorth,
          lockedAssets: currentAssets.lockedAssets,
          cash: currentAssets.cash,
          updatedAt: currentAssets.updatedAt,
          firstRecordDate: nextFirstRecordDate,
        );
    }

    final next = BackupData(
      schemaVersion: current.schemaVersion ?? 1,
      assets: nextAssets,
      expenses: [...current.expenses, ...importedExpenses],
      incomes: [...current.incomes, ...preview.incomesNew],
      devices: current.devices,
      passiveSources: [...current.passiveSources, ...preview.passiveSourcesNew],
      firstRecordDate: nextFirstRecordDate,
    );

    return ImportResult(
      data: next,
      expensesAdded: importedExpenses.length,
      incomesAdded: preview.incomesNew.length,
      passiveSourcesAdded: preview.passiveSourcesNew.length,
      duplicatesSkipped: preview.totalSkipped,
    );
  }

  static String? _validUuid(String? value) {
    if (value == null || !_uuidPattern.hasMatch(value)) return null;
    return value.toLowerCase();
  }

  static Iterable<String> _expenseKeys(Expense expense) sync* {
    yield _expenseKey(expense);

    final original = _originalCategory(expense.note);
    if (original != null) {
      yield _expenseKeyParts(
        expense: expense,
        category: original.category,
        note: original.note,
      );
    }
  }

  static String _expenseKey(Expense expense) => _expenseKeyParts(
    expense: expense,
    category: expense.category,
    note: expense.note,
  );

  static String _expenseKeyParts({
    required Expense expense,
    required String category,
    required String note,
  }) => '${_day(expense.date)}|${expense.amount}|$category|$note';

  static ({String category, String note})? _originalCategory(String note) {
    const marker = '原分类·';
    final markerIndex = note.lastIndexOf(marker);
    if (markerIndex < 0) return null;

    final category = note.substring(markerIndex + marker.length);
    var originalNote = note.substring(0, markerIndex);
    if (originalNote.endsWith(' · ')) {
      originalNote = originalNote.substring(0, originalNote.length - 3);
    }
    return (category: category, note: originalNote);
  }

  static String _incomeKey(Income income) =>
      '${_day(income.date)}|${income.amount}|${income.source}|${income.note}';

  static String _passiveKey(PassiveSource source) =>
      '${source.name}|${source.monthlyAmount}';

  static String _day(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static DateTime? _earlier(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }

  static DateTime? _currentFirstRecordDate(BackupData data) {
    final dates = [
      data.firstRecordDate,
      data.assets?.firstRecordDate,
      ...data.expenses.map((expense) => expense.date),
      ...data.incomes.map((income) => income.date),
    ].whereType<DateTime>();
    DateTime? earliest;
    for (final value in dates) {
      final day = DateTime(value.year, value.month, value.day);
      earliest = _earlier(earliest, day);
    }
    return earliest;
  }

  static Map<String, Object?>? _map(Object? value) {
    if (value is Map) return value.cast<String, Object?>();
    return null;
  }

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
