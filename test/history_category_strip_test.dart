import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/app/theme/freegrid_theme.dart';
import 'package:freegrid/features/dashboard/widgets/history_category_strip.dart';

void main() {
  testWidgets('expense category strip does not overflow on Pixel 7', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: FreeGridTheme.light(),
        home: Scaffold(
          body: HistoryCategoryStrip(
            categories: const [
              HistoryCategoryItem(name: '购物', total: 16586),
              HistoryCategoryItem(name: '成长投资', total: 12345),
              HistoryCategoryItem(name: '午餐', total: 8632),
              HistoryCategoryItem(name: '晚餐', total: 7954),
            ],
            selectedCategory: null,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('购物'), findsOneWidget);
    expect(
      tester.getSize(find.byType(HistoryCategoryStrip)),
      const Size(1080 / 2.625, HistoryCategoryStrip.height),
    );
    expect(tester.takeException(), isNull);
  });
}
