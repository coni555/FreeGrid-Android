import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/app/theme/freegrid_theme.dart';
import 'package:freegrid/core/domain/freedom_math.dart';
import 'package:freegrid/features/dashboard/widgets/simulation_grid_demo.dart';

void main() {
  test('timing keeps expense crisp and income deliberately slower', () {
    final expense = SimulationGridTiming.resolve(delta: 30, ignite: false);
    final income = SimulationGridTiming.resolve(delta: 30, ignite: true);

    expect(expense.cellDurationSeconds, 0.55);
    expect(expense.spanSeconds, 1.6);
    expect(expense.totalSeconds, closeTo(2.15, 0.000001));
    expect(income.cellDurationSeconds, 0.72);
    expect(income.spanSeconds, 3);
    expect(income.totalSeconds, closeTo(3.72, 0.000001));
  });

  test('expense extinguishes from the final cell backwards', () {
    final finalCell = resolveSimulationCellVisual(
      index: 9,
      oldCount: 10,
      newCount: 7,
      elapsedSeconds: 0.3,
    );
    final firstTransitionCell = resolveSimulationCellVisual(
      index: 7,
      oldCount: 10,
      newCount: 7,
      elapsedSeconds: 0.3,
    );

    expect(finalCell.opacity, lessThan(firstTransitionCell.opacity));
    expect(finalCell.glow, greaterThanOrEqualTo(0));
  });

  test('income ignites the first new cell before the later cells', () {
    final firstNew = resolveSimulationCellVisual(
      index: 7,
      oldCount: 7,
      newCount: 10,
      elapsedSeconds: 0.3,
    );
    final finalNew = resolveSimulationCellVisual(
      index: 9,
      oldCount: 7,
      newCount: 10,
      elapsedSeconds: 0.3,
    );

    expect(firstNew.opacity, greaterThan(finalNew.opacity));
    expect(firstNew.scale, greaterThanOrEqualTo(1));
  });

  test('snapshot locks the current unit across threshold changes', () {
    final snapshot = SimulationGridSnapshot.fromFreedomDays(
      unit: GridUnit.day,
      freedomDays: 400,
      lockedAssets: 250,
      netWorth: 500,
    );

    expect(snapshot.unit, GridUnit.day);
    expect(snapshot.count, GridUnit.day.maxCells);
    expect(snapshot.assetCells, 183);
  });

  testWidgets('normal mode mounts one painter and replays to done', (
    tester,
  ) async {
    await tester.pumpWidget(_app(reduceMotion: false));

    expect(find.byKey(SimulationGridDemo.paintKey), findsOneWidget);
    expect(find.byKey(SimulationGridDemo.reducedMotionKey), findsNothing);
    expect(find.text('演示这笔熄灭哪几格'), findsOneWidget);

    await tester.tap(find.byKey(SimulationGridDemo.playKey));
    await tester.pump();
    expect(find.text('推演中…'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('重播'), findsOneWidget);
  });

  testWidgets('reduce motion falls back to static before-after grids', (
    tester,
  ) async {
    await tester.pumpWidget(_app(reduceMotion: true));

    expect(find.byKey(SimulationGridDemo.paintKey), findsNothing);
    expect(find.byKey(SimulationGridDemo.reducedMotionKey), findsOneWidget);
    expect(find.byKey(SimulationGridDemo.playKey), findsNothing);
  });
}

Widget _app({required bool reduceMotion}) {
  return MaterialApp(
    theme: FreeGridTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390,
            child: SimulationGridDemo(
              before: const SimulationGridSnapshot(
                unit: GridUnit.day,
                count: 10,
                assetCells: 6,
              ),
              after: const SimulationGridSnapshot(
                unit: GridUnit.day,
                count: 7,
                assetCells: 5,
              ),
              isExpense: true,
            ),
          ),
        ),
      ),
    ),
  );
}
