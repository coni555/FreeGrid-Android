import 'dart:convert';

import '../domain/models.dart';

class BackupData {
  const BackupData({
    this.schemaVersion,
    this.assets,
    this.expenses = const [],
    this.incomes = const [],
    this.devices = const [],
    this.passiveSources = const [],
    this.firstRecordDate,
  });

  final int? schemaVersion;
  final UserAssets? assets;
  final List<Expense> expenses;
  final List<Income> incomes;
  final List<Device> devices;
  final List<PassiveSource> passiveSources;
  final DateTime? firstRecordDate;
}

class BackupCodec {
  static BackupData decodeString(String source) {
    final raw = jsonDecode(source);
    if (raw is! Map<String, Object?>) {
      throw const FormatException('FreeGrid backup must be a JSON object.');
    }
    return decodeMap(raw);
  }

  static BackupData decodeMap(Map<String, Object?> json) {
    final assetsJson = _map(json['assets']);
    final firstRecordDate = _date(json['first_record_date']);

    return BackupData(
      schemaVersion: _int(json['schema_version']),
      assets: assetsJson == null
          ? null
          : UserAssets(
              total: _double(assetsJson['total']) ?? 0,
              lockedAssets: _double(assetsJson['locked_assets']) ?? 0,
              cash:
                  _double(assetsJson['cash']) ??
                  _double(assetsJson['total']) ??
                  0,
              updatedAt: _dateTime(assetsJson['updated_at']),
              firstRecordDate: firstRecordDate,
            ),
      expenses: _list(json['expenses']).map(_expense).toList(),
      incomes: _list(json['incomes']).map(_income).toList(),
      devices: _list(json['devices']).map(_device).toList(),
      passiveSources: _list(
        json['passive_sources'],
      ).map(_passiveSource).toList(),
      firstRecordDate: firstRecordDate,
    );
  }

  static String encodeString(BackupData data) {
    return const JsonEncoder.withIndent('  ').convert(encodeMap(data));
  }

  static Map<String, Object?> encodeMap(BackupData data) {
    return {
      'schema_version': data.schemaVersion ?? 1,
      if (data.assets != null) 'assets': _assetsJson(data.assets!),
      'expenses': data.expenses.map(_expenseJson).toList(),
      'incomes': data.incomes.map(_incomeJson).toList(),
      if (data.devices.isNotEmpty)
        'devices': data.devices.map(_deviceJson).toList(),
      'passive_sources': data.passiveSources.map(_passiveJson).toList(),
      if (data.firstRecordDate != null)
        'first_record_date': _formatDay(data.firstRecordDate!),
    };
  }

  static Expense _expense(Map<String, Object?> json) {
    return Expense(
      id: _string(json['id']),
      amount: _double(json['amount']) ?? 0,
      category: _string(json['category']) ?? '',
      note: _string(json['note']) ?? '',
      date: _date(json['date']) ?? DateTime.now(),
      createdAt: _dateTime(json['created_at']),
    );
  }

  static Income _income(Map<String, Object?> json) {
    return Income(
      id: _string(json['id']),
      amount: _double(json['amount']) ?? 0,
      source: _string(json['source']) ?? '',
      isPassive: _bool(json['is_passive']) ?? false,
      note: _string(json['note']) ?? '',
      date: _date(json['date']) ?? DateTime.now(),
      createdAt: _dateTime(json['created_at']),
    );
  }

  static Device _device(Map<String, Object?> json) {
    return Device(
      id: _string(json['id']),
      name: _string(json['name']) ?? '',
      category: _string(json['category']) ?? '数码',
      price: _double(json['price']) ?? 0,
      purchaseDate: _date(json['purchase_date']) ?? DateTime.now(),
      status: _string(json['status']) ?? 'active',
      soldPrice: _double(json['sold_price']),
      soldDate: _date(json['sold_date']),
      note: _string(json['note']) ?? '',
      createdAt: _dateTime(json['created_at']),
    );
  }

  static PassiveSource _passiveSource(Map<String, Object?> json) {
    return PassiveSource(
      id: _string(json['id']),
      name: _string(json['name']) ?? '',
      monthlyAmount: _double(json['monthly_amount']) ?? 0,
      createdAt: _dateTime(json['created_at']),
    );
  }

  static Map<String, Object?> _assetsJson(UserAssets assets) {
    return {
      'total': assets.netWorth,
      'locked_assets': assets.lockedAssets,
      'cash': assets.cash,
      if (assets.updatedAt != null)
        'updated_at': assets.updatedAt!.toUtc().toIso8601String(),
    };
  }

  static Map<String, Object?> _expenseJson(Expense expense) {
    return {
      if (expense.id != null) 'id': expense.id,
      'amount': expense.amount,
      'category': expense.category,
      'date': _formatDay(expense.date),
      if (expense.note.isNotEmpty) 'note': expense.note,
      if (expense.createdAt != null)
        'created_at': expense.createdAt!.toUtc().toIso8601String(),
    };
  }

  static Map<String, Object?> _incomeJson(Income income) {
    return {
      if (income.id != null) 'id': income.id,
      'amount': income.amount,
      'source': income.source,
      'date': _formatDay(income.date),
      if (income.note.isNotEmpty) 'note': income.note,
      'is_passive': income.isPassive,
      if (income.createdAt != null)
        'created_at': income.createdAt!.toUtc().toIso8601String(),
    };
  }

  static Map<String, Object?> _deviceJson(Device device) {
    return {
      if (device.id != null) 'id': device.id,
      'name': device.name,
      'category': device.category,
      'price': device.price,
      'purchase_date': _formatDay(device.purchaseDate),
      'status': device.status,
      if (device.soldPrice != null) 'sold_price': device.soldPrice,
      if (device.soldDate != null) 'sold_date': _formatDay(device.soldDate!),
      if (device.note.isNotEmpty) 'note': device.note,
      if (device.createdAt != null)
        'created_at': device.createdAt!.toUtc().toIso8601String(),
    };
  }

  static Map<String, Object?> _passiveJson(PassiveSource source) {
    return {
      if (source.id != null) 'id': source.id,
      'name': source.name,
      'monthly_amount': source.monthlyAmount,
      if (source.createdAt != null)
        'created_at': source.createdAt!.toUtc().toIso8601String(),
    };
  }

  static List<Map<String, Object?>> _list(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, Object?>())
        .toList();
  }

  static Map<String, Object?>? _map(Object? value) {
    if (value is Map) return value.cast<String, Object?>();
    return null;
  }

  static String? _string(Object? value) {
    return value is String ? value : null;
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool? _bool(Object? value) {
    if (value is bool) return value;
    if (value is String) {
      return switch (value.toLowerCase()) {
        'true' => true,
        'false' => false,
        _ => null,
      };
    }
    return null;
  }

  static DateTime? _date(Object? value) {
    final source = _string(value);
    if (source == null || source.isEmpty) return null;
    final parts = source.split('-');
    if (parts.length != 3) return DateTime.tryParse(source);
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  static DateTime? _dateTime(Object? value) {
    final source = _string(value);
    if (source == null || source.isEmpty) return null;
    return DateTime.tryParse(source);
  }

  static String _formatDay(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
