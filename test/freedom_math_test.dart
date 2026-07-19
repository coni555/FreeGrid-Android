import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/core/domain/freedom_math.dart';
import 'package:freegrid/core/domain/models.dart';

void main() {
  group('FreedomMath', () {
    test('trackDays includes both first day and today', () {
      expect(
        FreedomMath.trackDays(
          firstRecordDate: DateTime(2026, 1, 1, 20),
          now: DateTime(2026, 1, 1, 8),
        ),
        1,
      );
      expect(
        FreedomMath.trackDays(
          firstRecordDate: DateTime(2026, 1, 1, 20),
          now: DateTime(2026, 1, 2, 8),
        ),
        2,
      );
    });

    test('freedom day display floors day values instead of rounding', () {
      expect(FreedomMath.freedomDaysDisplay(77.9), '77');
      expect(FreedomMath.freedomDaysDisplay(365), '11');
    });

    test('passive income coverage turns freedom days into infinity', () {
      final days = FreedomMath.freedomDays(
        netWorth: 5600,
        dailyBurn: 30,
        dailyPassive: 30,
      );

      expect(days.isInfinite, isTrue);
      expect(FreedomMath.freedomDaysDisplay(days), '∞');
    });

    test('grid state uses the same floor boundary as hero number', () {
      final state = FreedomMath.gridState(
        lockedAssets: 3300,
        cash: 2300,
        dailyBurn: 71.8,
      );

      expect(state.unit, GridUnit.day);
      expect(state.count, 77);
      expect(state.blueCells + state.yellowCells, 77);
    });

    test('history assigns same-day income to the same natural day', () {
      final history = FreedomMath.freedomDaysHistory(
        expenses: [
          Expense(amount: 300, category: '午餐', date: DateTime(2026, 1, 1, 12)),
        ],
        incomes: [
          Income(amount: 1600, source: '工资', date: DateTime(2026, 1, 15, 18)),
        ],
        currentNetWorth: 5600,
        firstRecordDate: DateTime(2026, 1, 1, 22),
        now: DateTime(2026, 1, 15, 9),
        weeks: 2,
      );

      expect(history, isNotEmpty);
      expect(history.last.date, DateTime(2026, 1, 15));
      expect(history.last.freedomDays, closeTo(280, 0.001));
    });
  });
}
