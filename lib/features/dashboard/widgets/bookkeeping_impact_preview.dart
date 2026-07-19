import 'package:flutter/material.dart';

import '../../../app/theme/freegrid_theme.dart';
import '../../../core/domain/freedom_math.dart';

@immutable
class BookkeepingImpact {
  const BookkeepingImpact._({
    required this.isExpense,
    required this.amount,
    required this.currentNetWorth,
    required this.nextNetWorth,
    required this.currentDailyBurn,
    required this.nextDailyBurn,
    required this.currentFreedomDays,
    required this.nextFreedomDays,
  });

  factory BookkeepingImpact.calculate({
    required bool isExpense,
    required double amount,
    required double netWorth,
    required double dailyBurn,
    required double dailyPassive,
    required int trackDays,
  }) {
    final nextNetWorth = netWorth + (isExpense ? -amount : amount);
    final nextDailyBurn = isExpense && trackDays > 0
        ? FreedomMath.dailyBurn(
            totalExpenses: dailyBurn * trackDays + amount,
            trackDays: trackDays,
          )
        : dailyBurn;

    return BookkeepingImpact._(
      isExpense: isExpense,
      amount: amount,
      currentNetWorth: netWorth,
      nextNetWorth: nextNetWorth,
      currentDailyBurn: dailyBurn,
      nextDailyBurn: nextDailyBurn,
      currentFreedomDays: FreedomMath.freedomDays(
        netWorth: netWorth,
        dailyBurn: dailyBurn,
        dailyPassive: dailyPassive,
      ),
      nextFreedomDays: FreedomMath.freedomDays(
        netWorth: nextNetWorth,
        dailyBurn: nextDailyBurn,
        dailyPassive: dailyPassive,
      ),
    );
  }

  final bool isExpense;
  final double amount;
  final double currentNetWorth;
  final double nextNetWorth;
  final double currentDailyBurn;
  final double nextDailyBurn;
  final double currentFreedomDays;
  final double nextFreedomDays;

  double get dailyBurnDelta => nextDailyBurn - currentDailyBurn;

  double? get freedomDeltaDays {
    if (!currentFreedomDays.isFinite || !nextFreedomDays.isFinite) return null;
    return nextFreedomDays - currentFreedomDays;
  }
}

class BookkeepingImpactPreview extends StatelessWidget {
  const BookkeepingImpactPreview({required this.impact, super.key});

  static const cardKey = ValueKey('bookkeeping-impact-preview');
  static const netWorthRowKey = ValueKey('impact-net-worth');
  static const dailyBurnRowKey = ValueKey('impact-daily-burn');
  static const freedomDaysRowKey = ValueKey('impact-freedom-days');

  final BookkeepingImpact impact;

  @override
  Widget build(BuildContext context) {
    final accent = impact.isExpense ? context.fg.flame : context.fg.skyDeep;

    return Container(
      key: cardKey,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: context.fg.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.fg.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            impact.isExpense
                ? 'DAVIS TRIPLE KILL · 戴维斯三杀预览'
                : 'FREEDOM GAIN · 自由增长预览',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.fg.inkFaint,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          _ImpactLine(
            key: netWorthRowKey,
            label: impact.isExpense ? 'KILL 1 · 净值' : 'GAIN 1 · 净值',
            before: _formatYuan(impact.currentNetWorth),
            after: _formatYuan(impact.nextNetWorth),
            delta:
                '${impact.isExpense ? '−' : '+'}${_formatYuan(impact.amount)}',
            accent: accent,
          ),
          if (impact.isExpense) ...[
            const SizedBox(height: 13),
            _ImpactLine(
              key: dailyBurnRowKey,
              label: 'KILL 2 · 日均',
              before: _formatYuan(
                impact.currentDailyBurn,
                minimumFractionDigits: 1,
                maximumFractionDigits: 1,
              ),
              after: _formatYuan(
                impact.nextDailyBurn,
                minimumFractionDigits: 2,
                maximumFractionDigits: 2,
              ),
              delta:
                  '+${_formatYuan(impact.dailyBurnDelta, minimumFractionDigits: 2, maximumFractionDigits: 2)}',
              accent: accent,
            ),
          ],
          const SizedBox(height: 13),
          _ImpactLine(
            key: freedomDaysRowKey,
            label: impact.isExpense ? 'KILL 3 · 自由天数' : 'GAIN 2 · 自由天数',
            before: FreedomMath.freedomDaysDisplay(impact.currentFreedomDays),
            after: FreedomMath.freedomDaysDisplay(impact.nextFreedomDays),
            delta: _freedomDeltaLabel(impact),
            accent: accent,
          ),
          const SizedBox(height: 13),
          Divider(height: 1, color: context.fg.hairlineSoft),
          const SizedBox(height: 10),
          Text(
            impact.isExpense
                ? '这笔消费对自由天数的传导效应。还没保存，只是看看。'
                : '这笔收入对自由天数的回血效应。还没保存，只是看看。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.fg.inkFaint,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class BookkeepingImpactSection extends StatelessWidget {
  const BookkeepingImpactSection({
    required this.amount,
    required this.isExpense,
    required this.netWorth,
    required this.dailyBurn,
    required this.dailyPassive,
    required this.trackDays,
    super.key,
  });

  static const sectionKey = ValueKey('bookkeeping-impact-section');

  final double? amount;
  final bool isExpense;
  final double netWorth;
  final double dailyBurn;
  final double dailyPassive;
  final int trackDays;

  @override
  Widget build(BuildContext context) {
    final value = amount;
    if (value == null || value <= 0) return const SizedBox.shrink();

    return Padding(
      key: sectionKey,
      padding: const EdgeInsets.only(top: 18),
      child: BookkeepingImpactPreview(
        impact: BookkeepingImpact.calculate(
          isExpense: isExpense,
          amount: value,
          netWorth: netWorth,
          dailyBurn: dailyBurn,
          dailyPassive: dailyPassive,
          trackDays: trackDays,
        ),
      ),
    );
  }
}

class _ImpactLine extends StatelessWidget {
  const _ImpactLine({
    required this.label,
    required this.before,
    required this.after,
    required this.delta,
    required this.accent,
    super.key,
  });

  final String label;
  final String before;
  final String after;
  final String delta;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.fg.inkFaint,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.15,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$before  →  $after',
                  maxLines: 1,
                  style: context.numberStyle(
                    17,
                    color: context.fg.ink,
                    weight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              delta,
              style: context.numberStyle(
                14,
                color: accent,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _freedomDeltaLabel(BookkeepingImpact impact) {
  final delta = impact.freedomDeltaDays;
  if (delta == null) return '—';
  if (impact.isExpense) return '−${(-delta).round()} 天';
  return '+${delta.round()} 天';
}

String _formatYuan(
  double value, {
  int minimumFractionDigits = 0,
  int maximumFractionDigits = 2,
}) {
  var source = value.toStringAsFixed(maximumFractionDigits);
  while (source.contains('.') &&
      source.endsWith('0') &&
      source.length - source.indexOf('.') - 1 > minimumFractionDigits) {
    source = source.substring(0, source.length - 1);
  }
  if (source.endsWith('.')) source = source.substring(0, source.length - 1);

  final parts = source.split('.');
  final integer = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final fraction = parts.length == 2 ? '.${parts.last}' : '';
  return '¥$integer$fraction';
}
