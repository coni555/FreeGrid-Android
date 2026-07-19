import 'package:flutter/material.dart';

import '../../../app/theme/freegrid_theme.dart';

class HistoryCategoryItem {
  const HistoryCategoryItem({required this.name, required this.total});

  final String name;
  final double total;
}

class HistoryCategoryStrip extends StatelessWidget {
  const HistoryCategoryStrip({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
    super.key,
  });

  static const height = 72.0;

  final List<HistoryCategoryItem> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<double>(0, (sum, item) => sum + item.total);
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
        children: [
          _CategoryChip(
            label: '全部',
            amount: total,
            selected: selectedCategory == null,
            onTap: () => onSelected(null),
          ),
          for (final item in categories)
            _CategoryChip(
              label: item.name,
              amount: item.total,
              selected: selectedCategory == item.name,
              onTap: () =>
                  onSelected(selectedCategory == item.name ? null : item.name),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final double amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? context.fg.skyFaint : context.fg.mist,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? context.fg.skyDeep : context.fg.hairlineSoft,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? context.fg.skyDeep : context.fg.inkMuted,
                  fontSize: 11,
                ),
              ),
              Text(
                '¥${_formatMoney(amount)}',
                style: context.numberStyle(
                  14,
                  color: context.fg.ink,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatMoney(double value) {
  return value
      .toStringAsFixed(value.abs() >= 1000 ? 0 : 1)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
}
