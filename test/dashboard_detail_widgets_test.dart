import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/app/theme/freegrid_theme.dart';
import 'package:freegrid/features/dashboard/widgets/dashboard_sparkline.dart';
import 'package:freegrid/features/dashboard/widgets/dashboard_top_bar.dart';

void main() {
  testWidgets('top bar keeps compact visuals with full Android tap targets', (
    tester,
  ) async {
    var themeTaps = 0;
    var layoutTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: FreeGridTheme.light(),
        home: Scaffold(
          body: DashboardTopBar(
            isDarkMode: false,
            heroVertical: false,
            onToggleTheme: () => themeTaps += 1,
            onToggleHero: () => layoutTaps += 1,
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(DashboardTopBar.themeMarkKey)),
      const Size.square(22),
    );
    final layoutIcon = tester.widget<Icon>(
      find.byKey(DashboardTopBar.layoutIconKey),
    );
    expect(layoutIcon.size, 18);

    final buttons = tester.widgetList<IconButton>(find.byType(IconButton));
    expect(buttons, hasLength(2));
    for (final button in buttons) {
      expect(button.constraints?.minWidth, 48);
      expect(button.constraints?.minHeight, 48);
    }

    await tester.tap(find.byTooltip('切换深色模式'));
    await tester.tap(find.byTooltip('切换居中布局'));
    expect(themeTaps, 1);
    expect(layoutTaps, 1);
  });

  testWidgets('sparkline uses theme skyDeep and iOS stroke geometry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FreeGridTheme.dark(),
        home: const SizedBox(
          width: 300,
          height: 36,
          child: DashboardSparkline(values: [80, 84, 93]),
        ),
      ),
    );

    final paint = tester.widget<CustomPaint>(
      find.byKey(DashboardSparkline.paintKey),
    );
    final painter = paint.painter! as DashboardSparklinePainter;
    expect(painter.color, FreeGridColors.dark.skyDeep);
    expect(DashboardSparklinePainter.strokeWidth, 1.2);
    expect(DashboardSparklinePainter.endDotDiameter, 5);
  });
}
