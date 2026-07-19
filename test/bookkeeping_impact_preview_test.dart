import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/app/theme/freegrid_theme.dart';
import 'package:freegrid/core/domain/freedom_math.dart';
import 'package:freegrid/features/dashboard/widgets/bookkeeping_impact_preview.dart';

void main() {
  test('expense impact matches the shared FreedomMath calculation', () {
    final impact = BookkeepingImpact.calculate(
      isExpense: true,
      amount: 100,
      netWorth: 6631,
      dailyBurn: 71.3,
      dailyPassive: 0,
      trackDays: 635,
    );

    expect(impact.nextNetWorth, 6531);
    expect(impact.nextDailyBurn, closeTo(71.3 + 100 / 635, 0.000001));
    expect(
      impact.nextFreedomDays,
      FreedomMath.freedomDays(netWorth: 6531, dailyBurn: impact.nextDailyBurn),
    );
    expect(impact.freedomDeltaDays, isNegative);
  });

  test('income changes net worth but keeps the daily burn unchanged', () {
    final impact = BookkeepingImpact.calculate(
      isExpense: false,
      amount: 100,
      netWorth: 6631,
      dailyBurn: 71.3,
      dailyPassive: 10,
      trackDays: 635,
    );

    expect(impact.nextNetWorth, 6731);
    expect(impact.nextDailyBurn, 71.3);
    expect(
      impact.nextFreedomDays,
      FreedomMath.freedomDays(
        netWorth: 6731,
        dailyBurn: 71.3,
        dailyPassive: 10,
      ),
    );
    expect(impact.freedomDeltaDays, isPositive);
  });

  testWidgets('expense renders all three KILL rows and exact money precision', (
    tester,
  ) async {
    final impact = BookkeepingImpact.calculate(
      isExpense: true,
      amount: 100,
      netWorth: 6631,
      dailyBurn: 71.3,
      dailyPassive: 0,
      trackDays: 635,
    );

    await tester.pumpWidget(_app(BookkeepingImpactPreview(impact: impact)));

    expect(find.text('DAVIS TRIPLE KILL · 戴维斯三杀预览'), findsOneWidget);
    expect(find.text('KILL 1 · 净值'), findsOneWidget);
    expect(find.text('KILL 2 · 日均'), findsOneWidget);
    expect(find.text('KILL 3 · 自由天数'), findsOneWidget);
    expect(find.text('¥6,631  →  ¥6,531'), findsOneWidget);
    expect(find.text('¥71.3  →  ¥71.46'), findsOneWidget);
    expect(find.text('−¥100'), findsOneWidget);
  });

  testWidgets('income renders two GAIN rows without the daily-burn row', (
    tester,
  ) async {
    final impact = BookkeepingImpact.calculate(
      isExpense: false,
      amount: 100,
      netWorth: 6631,
      dailyBurn: 71.3,
      dailyPassive: 0,
      trackDays: 635,
    );

    await tester.pumpWidget(_app(BookkeepingImpactPreview(impact: impact)));

    expect(find.text('FREEDOM GAIN · 自由增长预览'), findsOneWidget);
    expect(find.text('GAIN 1 · 净值'), findsOneWidget);
    expect(find.text('GAIN 2 · 自由天数'), findsOneWidget);
    expect(find.text('KILL 2 · 日均'), findsNothing);
    expect(find.text('+¥100'), findsOneWidget);
  });

  testWidgets('section stays absent until amount is valid', (tester) async {
    Widget section(double? amount) => BookkeepingImpactSection(
      amount: amount,
      isExpense: true,
      netWorth: 6631,
      dailyBurn: 71.3,
      dailyPassive: 0,
      trackDays: 635,
    );

    await tester.pumpWidget(_app(section(null)));
    expect(find.byKey(BookkeepingImpactSection.sectionKey), findsNothing);
    expect(find.byKey(BookkeepingImpactPreview.cardKey), findsNothing);

    await tester.pumpWidget(_app(section(100)));
    expect(find.byKey(BookkeepingImpactSection.sectionKey), findsOneWidget);
    expect(find.byKey(BookkeepingImpactPreview.cardKey), findsOneWidget);
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: FreeGridTheme.light(),
    home: Scaffold(
      body: Center(child: SizedBox(width: 390, child: child)),
    ),
  );
}
