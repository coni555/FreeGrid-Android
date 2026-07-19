import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/app/theme/freegrid_theme.dart';

void main() {
  testWidgets('numberStyle always uses Geist tabular figures', (tester) async {
    late TextStyle style;
    await tester.pumpWidget(
      MaterialApp(
        theme: FreeGridTheme.light(),
        home: Builder(
          builder: (context) {
            style = context.numberStyle(
              24,
              color: context.fg.ink,
              weight: FontWeight.w300,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(style.fontFamily, 'Geist');
    expect(style.fontSize, 24);
    expect(style.fontWeight, FontWeight.w300);
    expect(style.fontFeatures?.single.feature, 'tnum');
  });
}
