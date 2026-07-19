import 'dart:math' as math;

import 'models.dart';

enum FreedomUnit { day, month, year }

enum GridUnit { day, month, year }

extension GridUnitInfo on GridUnit {
  int get maxCells {
    return switch (this) {
      GridUnit.day => 365,
      GridUnit.month => 120,
      GridUnit.year => 99,
    };
  }

  String get label {
    return switch (this) {
      GridUnit.day => '天',
      GridUnit.month => '月',
      GridUnit.year => '年',
    };
  }
}

class GridState {
  const GridState({
    required this.unit,
    required this.count,
    required this.blueCells,
    required this.yellowCells,
    required this.isOverflow,
  });

  final GridUnit unit;
  final int count;
  final int blueCells;
  final int yellowCells;
  final bool isOverflow;
}

class HistoryPoint {
  const HistoryPoint({required this.date, required this.freedomDays});

  final DateTime date;
  final double freedomDays;
}

class DeltaSummary {
  const DeltaSummary({
    required this.start,
    required this.end,
    required this.delta,
  });

  final int start;
  final int end;
  final int delta;
}

class FreedomMath {
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static int daysBetween(DateTime from, DateTime to) {
    final start = startOfDay(from);
    final end = startOfDay(to);
    return end.difference(start).inDays;
  }

  static int trackDays({required DateTime? firstRecordDate, DateTime? now}) {
    if (firstRecordDate == null) return 1;
    final days = daysBetween(firstRecordDate, now ?? DateTime.now());
    return math.max(1, days + 1);
  }

  static double dailyBurn({
    required double totalExpenses,
    required int trackDays,
  }) {
    if (trackDays <= 0) return 0;
    return totalExpenses / trackDays;
  }

  static double dailyPassive(List<PassiveSource> sources) {
    return sources.fold(0, (sum, source) => sum + source.monthlyAmount / 30);
  }

  static double passiveRatio({
    required double dailyPassive,
    required double dailyBurn,
  }) {
    if (dailyBurn <= 0) return 0;
    return dailyPassive / dailyBurn;
  }

  static double freedomDays({
    required double netWorth,
    required double dailyBurn,
    double dailyPassive = 0,
  }) {
    final netBurn = math.max(0, dailyBurn - dailyPassive).toDouble();
    if (netBurn <= 0) return double.infinity;
    return math.max(0, netWorth) / netBurn;
  }

  static String freedomDaysDisplay(double value) {
    if (value.isInfinite || value.isNaN) return '∞';
    if (value < 365) return value.toInt().toString();
    if (value < 3650) return (value / 30.44).toInt().toString();
    return (value / 365.25).toStringAsFixed(1);
  }

  static FreedomUnit freedomDaysUnit(double value) {
    if (value.isInfinite || value.isNaN) return FreedomUnit.day;
    if (value < 365) return FreedomUnit.day;
    if (value < 3650) return FreedomUnit.month;
    return FreedomUnit.year;
  }

  static String freedomDaysFormatted(double value, FreedomUnit unit) {
    if (value.isInfinite || value.isNaN) return '∞';
    return switch (unit) {
      FreedomUnit.day => value.toStringAsFixed(0),
      FreedomUnit.month => (value / 30.44).toStringAsFixed(0),
      FreedomUnit.year => (value / 365.25).toStringAsFixed(1),
    };
  }

  static String freedomUnitLabel(FreedomUnit unit) {
    return switch (unit) {
      FreedomUnit.day => '天',
      FreedomUnit.month => '月',
      FreedomUnit.year => '年',
    };
  }

  static GridState gridState({
    required double lockedAssets,
    required double cash,
    required double dailyBurn,
    double dailyPassive = 0,
  }) {
    if (dailyBurn <= 0) {
      return const GridState(
        unit: GridUnit.day,
        count: 0,
        blueCells: 0,
        yellowCells: 0,
        isOverflow: false,
      );
    }

    final netWorth = math.max(0, lockedAssets) + math.max(0, cash);
    final netBurn = math.max(0, dailyBurn - dailyPassive).toDouble();

    if (netBurn <= 0) {
      return const GridState(
        unit: GridUnit.year,
        count: 99,
        blueCells: 99,
        yellowCells: 0,
        isOverflow: true,
      );
    }

    final totalDays = netWorth / netBurn;
    if (!totalDays.isFinite) {
      return const GridState(
        unit: GridUnit.year,
        count: 99,
        blueCells: 99,
        yellowCells: 0,
        isOverflow: true,
      );
    }

    final (unit, count, isOverflow) = switch (totalDays) {
      < 365 => (GridUnit.day, totalDays.toInt(), false),
      < 3650 => (
        GridUnit.month,
        math.min((totalDays / 30.44).toInt(), GridUnit.month.maxCells),
        false,
      ),
      _ => (
        GridUnit.year,
        math.min((totalDays / 365.25).toInt(), GridUnit.year.maxCells),
        (totalDays / 365.25).toInt() > GridUnit.year.maxCells,
      ),
    };

    final blueCells = netWorth > 0
        ? (count * math.max(0, lockedAssets) / netWorth).round()
        : 0;
    final yellowCells = count - blueCells;

    return GridState(
      unit: unit,
      count: count,
      blueCells: blueCells,
      yellowCells: yellowCells,
      isOverflow: isOverflow,
    );
  }

  static List<HistoryPoint> freedomDaysHistory({
    required List<Expense> expenses,
    required List<Income> incomes,
    required double currentNetWorth,
    required DateTime? firstRecordDate,
    double dailyPassive = 0,
    int weeks = 12,
    DateTime? now,
  }) {
    if (firstRecordDate == null) return const [];

    final today = startOfDay(now ?? DateTime.now());
    final trackedDays = daysBetween(firstRecordDate, today);
    if (trackedDays < 14) return const [];

    final availableWeeks = math.min(weeks, trackedDays ~/ 7);
    final snapshots = <HistoryPoint>[];

    for (var i = availableWeeks; i >= 0; i -= 1) {
      final weekEnd = today.subtract(Duration(days: 7 * i));
      if (weekEnd.isBefore(startOfDay(firstRecordDate))) continue;

      final trackDaysI = math.max(1, daysBetween(firstRecordDate, weekEnd) + 1);

      bool onOrBefore(DateTime date) {
        return !startOfDay(date).isAfter(weekEnd);
      }

      bool after(DateTime date) {
        return startOfDay(date).isAfter(weekEnd);
      }

      final expUntil = expenses
          .where((expense) => onOrBefore(expense.date))
          .fold(0.0, (sum, expense) => sum + expense.amount);
      final dailyBurnI = expUntil / trackDaysI;

      final expAfter = expenses
          .where((expense) => after(expense.date))
          .fold(0.0, (sum, expense) => sum + expense.amount);
      final incAfter = incomes
          .where((income) => after(income.date))
          .fold(0.0, (sum, income) => sum + income.amount);
      final netWorthI = currentNetWorth + expAfter - incAfter;

      final netBurnI = math.max(0, dailyBurnI - dailyPassive).toDouble();
      final daysI = netBurnI > 0
          ? math.max(0, netWorthI) / netBurnI
          : dailyBurnI > 0
          ? 1825.0
          : 0.0;

      snapshots.add(HistoryPoint(date: weekEnd, freedomDays: daysI));
    }

    return snapshots;
  }

  static DeltaSummary? deltaSummary(List<HistoryPoint> history) {
    if (history.length < 2) return null;
    final start = history.first.freedomDays.toInt();
    final end = history.last.freedomDays.toInt();
    return DeltaSummary(start: start, end: end, delta: end - start);
  }

  static DateTime? depleteDate({required double freedomDays, DateTime? now}) {
    if (freedomDays.isInfinite || freedomDays <= 0 || freedomDays >= 1825 * 5) {
      return null;
    }
    return (now ?? DateTime.now()).add(Duration(days: freedomDays.round()));
  }
}
