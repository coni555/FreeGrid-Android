import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/app/theme/freegrid_theme.dart';
import 'package:freegrid/core/domain/freedom_math.dart';
import 'package:freegrid/features/dashboard/widgets/life_grid.dart';

void main() {
  testWidgets('day grid keeps 9dp cells and wraps with adaptive columns', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FreeGridTheme.light(),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              child: LifeGrid(unit: GridUnit.day, count: 9, assetCells: 4),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('life-grid-cell-0'))),
      const Size.square(9),
    );
    final firstTop = tester
        .getTopLeft(find.byKey(const ValueKey('life-grid-cell-0')))
        .dy;
    final nextRowTop = tester
        .getTopLeft(find.byKey(const ValueKey('life-grid-cell-8')))
        .dy;
    expect(nextRowTop - firstTop, 11.5);
  });

  testWidgets('month and year grids use the iOS parity cell sizes', (
    tester,
  ) async {
    Future<void> expectCellSize(GridUnit unit, double size) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FreeGridTheme.light(),
          home: Scaffold(body: LifeGrid(unit: unit, count: 2, assetCells: 1)),
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('life-grid-cell-0'))),
        Size.square(size),
      );
    }

    await expectCellSize(GridUnit.month, 12);
    await expectCellSize(GridUnit.year, 16);
  });

  testWidgets('current dark cell reaches the 1.6 breathing peak', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FreeGridTheme.dark(),
        home: const Scaffold(
          body: LifeGrid(unit: GridUnit.day, count: 1, assetCells: 0),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    final transform = tester.widget<Transform>(
      find.byKey(LifeGrid.currentCellKey),
    );
    expect(transform.transform.getMaxScaleOnAxis(), closeTo(1.6, 0.001));
  });
}
