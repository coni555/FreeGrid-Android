import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/app/theme/freegrid_theme.dart';
import 'package:freegrid/features/dashboard/widgets/data_management_card.dart';

void main() {
  Widget app({
    Future<void> Function()? onImport,
    Future<void> Function()? onCsv,
    Future<void> Function()? onJson,
    Future<void> Function()? onClear,
  }) {
    return MaterialApp(
      theme: FreeGridTheme.light(),
      home: Scaffold(
        body: DataManagementCard(
          onImportJson: onImport ?? () async {},
          onExportCsv: onCsv ?? () async {},
          onExportJson: onJson ?? () async {},
          onClearData: onClear ?? () async {},
        ),
      ),
    );
  }

  testWidgets('import action opens its own flow', (tester) async {
    var imports = 0;
    await tester.pumpWidget(app(onImport: () async => imports += 1));

    await tester.tap(find.byKey(DataManagementCard.importJsonKey));
    expect(imports, 1);
  });

  testWidgets('export buttons call their own actions', (tester) async {
    var csv = 0;
    var json = 0;
    await tester.pumpWidget(
      app(onCsv: () async => csv += 1, onJson: () async => json += 1),
    );

    await tester.tap(find.byKey(DataManagementCard.exportCsvKey));
    await tester.tap(find.byKey(DataManagementCard.exportJsonKey));
    expect(csv, 1);
    expect(json, 1);
  });

  testWidgets('clear requires destructive confirmation', (tester) async {
    var clears = 0;
    await tester.pumpWidget(app(onClear: () async => clears += 1));

    await tester.tap(find.byKey(DataManagementCard.clearDataKey));
    await tester.pumpAndSettle();
    expect(find.text('清空所有数据？'), findsOneWidget);
    expect(clears, 0);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(clears, 0);

    await tester.tap(find.byKey(DataManagementCard.clearDataKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认清空'));
    await tester.pumpAndSettle();
    expect(clears, 1);
    expect(find.text('已清空所有数据'), findsOneWidget);
  });
}
