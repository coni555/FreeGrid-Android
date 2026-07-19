import 'dart:convert';
import 'dart:typed_data';

import 'backup_codec.dart';

enum DataExportFormat { csv, json }

/// FreeGrid 的离线导出层。
///
/// 只负责生成与 iOS 同口径的文件内容，不依赖 Flutter 或平台分享 API，便于
/// 单元测试和后续导入 round-trip 验证。
class DataIO {
  const DataIO._();

  static const csvMimeType = 'text/csv';
  static const jsonMimeType = 'application/json';

  static Uint8List exportJson(BackupData data) {
    return Uint8List.fromList(utf8.encode(BackupCodec.encodeString(data)));
  }

  static Uint8List exportCsv(BackupData data) {
    final rows = <_CsvRow>[
      for (final expense in data.expenses)
        _CsvRow(
          date: expense.date,
          kind: '支出',
          label: expense.category,
          amount: expense.amount,
          note: expense.note,
        ),
      for (final income in data.incomes)
        _CsvRow(
          date: income.date,
          kind: '收入',
          label: income.source,
          amount: income.amount,
          note: income.note,
        ),
    ]..sort((a, b) => a.date.compareTo(b.date));

    final output = StringBuffer('\uFEFF日期,类型,类别/来源,金额,备注\n');
    for (final row in rows) {
      output
        ..write(_formatDay(row.date))
        ..write(',')
        ..write(row.kind)
        ..write(',')
        ..write(_escapeCsv(row.label))
        ..write(',')
        ..write(_formatAmount(row.amount))
        ..write(',')
        ..write(_escapeCsv(row.note))
        ..write('\n');
    }
    return Uint8List.fromList(utf8.encode(output.toString()));
  }

  static String fileName(DataExportFormat format, {DateTime? now}) {
    final day = _formatCompactDay(now ?? DateTime.now());
    return switch (format) {
      DataExportFormat.csv => 'FreeGrid-记账-$day.csv',
      DataExportFormat.json => 'FreeGrid-备份-$day.json',
    };
  }

  static String mimeType(DataExportFormat format) => switch (format) {
    DataExportFormat.csv => csvMimeType,
    DataExportFormat.json => jsonMimeType,
  };

  static String _escapeCsv(String value) {
    if (!value.contains(',') &&
        !value.contains('"') &&
        !value.contains('\n') &&
        !value.contains('\r')) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }

  static String _formatAmount(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static String _formatDay(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _formatCompactDay(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }
}

class _CsvRow {
  const _CsvRow({
    required this.date,
    required this.kind,
    required this.label,
    required this.amount,
    required this.note,
  });

  final DateTime date;
  final String kind;
  final String label;
  final double amount;
  final String note;
}
