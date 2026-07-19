import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/freegrid_theme.dart';
import '../../../core/data/data_importer.dart';
import '../../../core/domain/expense_category.dart';

class ImportReviewDecision {
  const ImportReviewDecision({
    required this.strategy,
    required this.categoryMap,
  });

  final AssetsImportStrategy strategy;
  final Map<String, String> categoryMap;
}

class ImportReviewSheet extends StatefulWidget {
  const ImportReviewSheet({required this.preview, super.key});

  static const confirmKey = ValueKey('confirm-import');
  static const closeKey = ValueKey('close-import-review');

  static ValueKey<String> categoryKey(String raw) =>
      ValueKey('import-category-$raw');

  static ValueKey<String> strategyKey(AssetsImportStrategy strategy) =>
      ValueKey('import-strategy-${strategy.name}');

  final ImportPreview preview;

  @override
  State<ImportReviewSheet> createState() => _ImportReviewSheetState();
}

class _ImportReviewSheetState extends State<ImportReviewSheet> {
  late final Map<String, String> _categoryMap;
  var _strategy = AssetsImportStrategy.skipAssets;

  @override
  void initState() {
    super.initState();
    _categoryMap = {
      for (final entry in widget.preview.categoryEntries)
        entry.raw: entry.canonical,
    };
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    final canCommit =
        preview.totalAdded > 0 ||
        (preview.hasAssets && _strategy != AssetsImportStrategy.skipAssets);
    final reviewCount = preview.categoryEntries
        .where((entry) => entry.needsReview)
        .length;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.92,
      child: Material(
        color: context.fg.paper,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.fg.hairline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: context.fg.skyFaint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fact_check_outlined,
                        color: context.fg.skyDeep,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '导入预览',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: context.fg.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            '确认后才会写入本机',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: context.fg.inkFaint),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: ImportReviewSheet.closeKey,
                      tooltip: '取消导入',
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: context.fg.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: context.fg.hairlineSoft),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  children: [
                    _ReviewCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _ReviewKicker('IMPORT SUMMARY · 导入摘要'),
                          const SizedBox(height: 14),
                          _SummaryRow(
                            label: '新增支出',
                            value: '${preview.expensesNew.length} 笔',
                          ),
                          _SummaryRow(
                            label: '新增收入',
                            value: '${preview.incomesNew.length} 笔',
                          ),
                          _SummaryRow(
                            label: '新增被动源',
                            value: '${preview.passiveSourcesNew.length} 个',
                          ),
                          if (preview.totalSkipped > 0) ...[
                            Divider(height: 20, color: context.fg.hairlineSoft),
                            _SummaryRow(
                              label: '跳过重复',
                              value: '${preview.totalSkipped} 项',
                              valueColor: context.fg.inkFaint,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (preview.categoryEntries.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _ReviewCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: _ReviewKicker('CATEGORY MAP · 分类对齐'),
                                ),
                                if (reviewCount > 0)
                                  Text(
                                    '$reviewCount 个待确认',
                                    style: TextStyle(
                                      color: context.fg.flame,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '外来分类不会直接写进账本。橙点表示无法自动判断，请在导入前确认。',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: context.fg.inkFaint,
                                    height: 1.4,
                                  ),
                            ),
                            for (final entry in preview.categoryEntries) ...[
                              Divider(
                                height: 24,
                                color: context.fg.hairlineSoft,
                              ),
                              _CategoryMapRow(
                                entry: entry,
                                selected: _categoryMap[entry.raw]!,
                                onChanged: (value) {
                                  HapticFeedback.selectionClick();
                                  setState(
                                    () => _categoryMap[entry.raw] = value,
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _ReviewCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _ReviewKicker('ASSETS · 资产处理'),
                          const SizedBox(height: 7),
                          Text(
                            preview.hasAssets
                                ? '默认不动当前资产。只有你明确选择时，备份里的净值才会参与合并。'
                                : '这个文件没有资产数据，只会导入交易与被动收入。',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: context.fg.inkFaint,
                                  height: 1.4,
                                ),
                          ),
                          const SizedBox(height: 6),
                          _StrategyOption(
                            strategy: AssetsImportStrategy.skipAssets,
                            selected: _strategy,
                            title: '只导入交易',
                            description: '保留现有资产与现金桶',
                            enabled: true,
                            onSelected: _selectStrategy,
                          ),
                          Divider(height: 1, color: context.fg.hairlineSoft),
                          _StrategyOption(
                            strategy: AssetsImportStrategy.replace,
                            selected: _strategy,
                            title: '替换净值',
                            description: _replaceDescription(preview),
                            enabled: preview.hasAssets,
                            onSelected: _selectStrategy,
                          ),
                          Divider(height: 1, color: context.fg.hairlineSoft),
                          _StrategyOption(
                            strategy: AssetsImportStrategy.addToCash,
                            selected: _strategy,
                            title: '加到现金',
                            description:
                                '现金 ¥${_money(preview.currentCash)} → '
                                '¥${_money(preview.currentCash + preview.jsonAssetsTotal)}',
                            enabled: preview.hasAssets,
                            onSelected: _selectStrategy,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: BoxDecoration(
                  color: context.fg.mist,
                  border: Border(top: BorderSide(color: context.fg.hairline)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    key: ImportReviewSheet.confirmKey,
                    onPressed: canCommit
                        ? () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(
                              context,
                              ImportReviewDecision(
                                strategy: _strategy,
                                categoryMap: Map.unmodifiable(_categoryMap),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.download_done_rounded, size: 19),
                    label: Text(_confirmLabel(preview)),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.fg.skyDeep,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      disabledBackgroundColor: context.fg.mist2,
                      disabledForegroundColor: context.fg.inkGhost,
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectStrategy(AssetsImportStrategy strategy) {
    HapticFeedback.selectionClick();
    setState(() => _strategy = strategy);
  }

  String _confirmLabel(ImportPreview preview) {
    if (preview.totalAdded > 0) return '确认导入 ${preview.totalAdded} 项';
    return switch (_strategy) {
      AssetsImportStrategy.replace => '确认替换净值',
      AssetsImportStrategy.addToCash => '确认加到现金',
      AssetsImportStrategy.skipAssets => '没有可导入的新记录',
    };
  }

  String _replaceDescription(ImportPreview preview) {
    final locked = preview.jsonLockedAssets;
    final cash = preview.jsonCash;
    if (locked != null && cash != null) {
      return '资产 ¥${_money(locked)} · 现金 ¥${_money(cash)}';
    }
    return '旧版单桶：资产清零 · 现金 ¥${_money(preview.jsonAssetsTotal)}';
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.fg.mist,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.fg.hairline),
      ),
      child: child,
    );
  }
}

class _ReviewKicker extends StatelessWidget {
  const _ReviewKicker(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: context.fg.inkFaint,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.2,
        height: 1.2,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: context.fg.inkMuted)),
          const Spacer(),
          Text(
            value,
            style: context.numberStyle(
              14,
              color: valueColor ?? context.fg.ink,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryMapRow extends StatelessWidget {
  const _CategoryMapRow({
    required this.entry,
    required this.selected,
    required this.onChanged,
  });

  final CategoryMapEntry entry;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (entry.needsReview) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: context.fg.flame,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                    child: Text(
                      entry.raw.isEmpty ? '（空分类）' : entry.raw,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.fg.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${entry.count} 笔 · ¥${_money(entry.total)}',
                style: context.numberStyle(
                  12,
                  color: context.fg.inkFaint,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_rounded, color: context.fg.inkGhost, size: 15),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          key: ImportReviewSheet.categoryKey(entry.raw),
          initialValue: selected,
          tooltip: '选择 ${entry.raw} 的标准分类',
          onSelected: onChanged,
          itemBuilder: (context) => [
            for (final category in ExpenseCategory.canonical)
              PopupMenuItem(value: category, child: Text(category)),
          ],
          child: Container(
            constraints: const BoxConstraints(minWidth: 86),
            padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
            decoration: BoxDecoration(
              color: context.fg.skyFaint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.fg.skyDeep.withValues(alpha: 0.52),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selected,
                  style: TextStyle(
                    color: context.fg.skyDeep,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: context.fg.skyDeep,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StrategyOption extends StatelessWidget {
  const _StrategyOption({
    required this.strategy,
    required this.selected,
    required this.title,
    required this.description,
    required this.enabled,
    required this.onSelected,
  });

  final AssetsImportStrategy strategy;
  final AssetsImportStrategy selected;
  final String title;
  final String description;
  final bool enabled;
  final ValueChanged<AssetsImportStrategy> onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = strategy == selected;
    final titleColor = enabled ? context.fg.ink : context.fg.inkGhost;
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: enabled,
      child: InkWell(
        key: ImportReviewSheet.strategyKey(strategy),
        onTap: enabled ? () => onSelected(strategy) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected
                    ? context.fg.skyDeep
                    : enabled
                    ? context.fg.inkGhost
                    : context.fg.hairline,
                size: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        color: enabled
                            ? context.fg.inkFaint
                            : context.fg.inkGhost,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _money(double value) {
  final decimals = value == value.roundToDouble() ? 0 : 2;
  return value
      .toStringAsFixed(decimals)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
}
