import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';
import 'backup_codec.dart';

class LocalFreeGridStore {
  LocalFreeGridStore({SharedPreferencesAsync? preferences, this.seedNow})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _backupKey = 'freegrid.local.backup.v1';

  final SharedPreferencesAsync _preferences;
  final DateTime? seedNow;

  Future<BackupData> load() async {
    final source = await _preferences.getString(_backupKey);
    if (source == null || source.isEmpty) {
      return seedData(now: seedNow ?? DateTime.now());
    }

    try {
      return BackupCodec.decodeString(source);
    } on FormatException {
      return seedData(now: seedNow ?? DateTime.now());
    }
  }

  Future<void> save(BackupData data) {
    return _preferences.setString(_backupKey, BackupCodec.encodeString(data));
  }

  static BackupData seedData({required DateTime now}) {
    final firstRecordDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 634));
    final createdAt = firstRecordDate.toUtc();

    return BackupData(
      schemaVersion: 1,
      assets: UserAssets(
        total: 6630.9,
        lockedAssets: 3992.8,
        cash: 2638.1,
        updatedAt: now,
        firstRecordDate: firstRecordDate,
      ),
      expenses: [
        Expense(
          id: _id('seed-expense', createdAt),
          amount: 71.3 * 635,
          category: '历史消费',
          note: '初始化日均消费基线',
          date: firstRecordDate,
          createdAt: createdAt,
        ),
      ],
      incomes: const [],
      passiveSources: const [],
      firstRecordDate: firstRecordDate,
    );
  }

  static String nextId(String prefix, DateTime now) {
    return _id(prefix, now.toUtc());
  }

  static String _id(String prefix, DateTime value) {
    return '$prefix-${value.microsecondsSinceEpoch}';
  }
}
