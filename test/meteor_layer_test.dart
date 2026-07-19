import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/app/theme/freegrid_theme.dart';
import 'package:freegrid/features/dashboard/widgets/meteor_layer.dart';

void main() {
  Widget surface({required ThemeData theme, bool enabled = true}) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: MeteorCardSurface(
          enabled: enabled,
          padding: const EdgeInsets.all(20),
          child: const SizedBox(width: 300, height: 200),
        ),
      ),
    );
  }

  testWidgets('light surface does not mount the meteor animation', (
    tester,
  ) async {
    await tester.pumpWidget(surface(theme: FreeGridTheme.light()));

    expect(find.byType(MeteorLayer), findsNothing);
    expect(find.byKey(MeteorLayer.paintKey), findsNothing);
  });

  testWidgets('dark active surface mounts one four-meteor painter', (
    tester,
  ) async {
    await tester.pumpWidget(surface(theme: FreeGridTheme.dark()));

    expect(MeteorLayer.meteorCount, 4);
    expect(find.byType(MeteorLayer), findsOneWidget);
    expect(find.byKey(MeteorLayer.paintKey), findsOneWidget);
  });

  testWidgets('inactive dark surface removes the meteor controller', (
    tester,
  ) async {
    await tester.pumpWidget(
      surface(theme: FreeGridTheme.dark(), enabled: false),
    );

    expect(find.byType(MeteorLayer), findsNothing);
  });
}
