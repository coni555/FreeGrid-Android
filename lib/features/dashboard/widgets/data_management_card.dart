import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/freegrid_theme.dart';

class DataManagementCard extends StatelessWidget {
  const DataManagementCard({
    required this.onImportJson,
    required this.onExportCsv,
    required this.onExportJson,
    required this.onClearData,
    super.key,
  });

  static const importJsonKey = ValueKey('import-json');
  static const exportCsvKey = ValueKey('export-csv');
  static const exportJsonKey = ValueKey('export-json');
  static const clearDataKey = ValueKey('clear-all-data');

  final Future<void> Function() onImportJson;
  final Future<void> Function() onExportCsv;
  final Future<void> Function() onExportJson;
  final Future<void> Function() onClearData;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.fg.mist,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.fg.hairline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'DATA',
                style: TextStyle(
                  color: context.fg.inkFaint,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.save_alt_rounded,
                color: context.fg.inkFaint,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ImportDataButton(onPressed: onImportJson),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CompactDataButton(
                  key: exportCsvKey,
                  icon: Icons.table_chart_outlined,
                  label: '导出 CSV',
                  onPressed: onExportCsv,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactDataButton(
                  key: exportJsonKey,
                  icon: Icons.data_object_rounded,
                  label: '导出 JSON',
                  onPressed: onExportJson,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '导入会先预览重复记录与资产变化；CSV 可用 Excel、Numbers 或腾讯文档打开。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.fg.inkFaint,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: context.fg.hairlineSoft),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              key: clearDataKey,
              onPressed: () => _confirmClear(context),
              icon: const Icon(Icons.delete_outline_rounded, size: 17),
              label: const Text('清空所有数据'),
              style: TextButton.styleFrom(
                foregroundColor: context.fg.flame,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    HapticFeedback.selectionClick();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空所有数据？'),
        content: const Text('资产、现金、收支记录和被动收入都会被永久删除，且无法撤销。建议先导出 JSON 备份。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: context.fg.flame),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    HapticFeedback.heavyImpact();
    await onClearData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          content: Text('已清空所有数据'),
        ),
      );
  }
}

class _ImportDataButton extends StatelessWidget {
  const _ImportDataButton({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.fg.skyFaint,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: DataManagementCard.importJsonKey,
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: context.fg.skyDeep.withValues(alpha: 0.48),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.file_open_outlined,
                color: context.fg.skyDeep,
                size: 18,
              ),
              const SizedBox(width: 9),
              Text(
                '导入 JSON 备份',
                style: TextStyle(
                  color: context.fg.skyDeep,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '先预览',
                style: TextStyle(color: context.fg.inkFaint, fontSize: 12),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                color: context.fg.inkFaint,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactDataButton extends StatelessWidget {
  const _CompactDataButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        icon: Icon(icon, size: 16),
        label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.fg.ink,
          side: BorderSide(
            color: context.fg.ink.withValues(alpha: 0.38),
            width: 1,
          ),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }
}
