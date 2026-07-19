import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/app/theme/freegrid_theme.dart';
import 'package:freegrid/core/data/backup_codec.dart';
import 'package:freegrid/core/data/data_importer.dart';
import 'package:freegrid/core/domain/models.dart';
import 'package:freegrid/features/dashboard/widgets/import_review_sheet.dart';

void main() {
  ImportPreview preview() => DataImporter.previewJson(
    current: BackupData(assets: const UserAssets(lockedAssets: 300, cash: 200)),
    source: '''
    {
      "schema_version": 1,
      "assets": {"total": 1000, "locked_assets": 700, "cash": 300},
      "expenses": [
        {"amount": 90, "category": "shopping", "date": "2026-01-01"},
        {"amount": 30, "category": "food", "date": "2026-01-02"}
      ],
      "incomes": [
        {"amount": 500, "source": "稿费", "date": "2026-01-03"}
      ]
    }
    ''',
  );

  Widget app(ImportPreview value) => MaterialApp(
    theme: FreeGridTheme.light(),
    home: Scaffold(body: ImportReviewSheet(preview: value)),
  );

  testWidgets('shows summary, category review and safe default strategy', (
    tester,
  ) async {
    await tester.pumpWidget(app(preview()));

    expect(find.text('新增支出'), findsOneWidget);
    expect(find.text('2 笔'), findsOneWidget);
    expect(find.text('shopping'), findsOneWidget);
    expect(find.text('food'), findsOneWidget);
    expect(find.text('1 个待确认'), findsOneWidget);

    final skip = find.byKey(
      ImportReviewSheet.strategyKey(AssetsImportStrategy.skipAssets),
    );
    await tester.scrollUntilVisible(skip, 260);
    expect(
      find.descendant(
        of: skip,
        matching: find.byIcon(Icons.radio_button_checked_rounded),
      ),
      findsOneWidget,
    );
  });

  testWidgets('returns edited category map and chosen assets strategy', (
    tester,
  ) async {
    ImportReviewDecision? decision;
    await tester.pumpWidget(
      MaterialApp(
        theme: FreeGridTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  decision = await Navigator.of(context).push(
                    MaterialPageRoute<ImportReviewDecision>(
                      builder: (_) => ImportReviewSheet(preview: preview()),
                    ),
                  );
                },
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(ImportReviewSheet.categoryKey('food')),
    );
    await tester.tap(find.byKey(ImportReviewSheet.categoryKey('food')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('晚餐').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(ImportReviewSheet.strategyKey(AssetsImportStrategy.replace)),
    );
    await tester.tap(
      find.byKey(ImportReviewSheet.strategyKey(AssetsImportStrategy.replace)),
    );
    await tester.tap(find.byKey(ImportReviewSheet.confirmKey));
    await tester.pumpAndSettle();

    expect(decision?.strategy, AssetsImportStrategy.replace);
    expect(decision?.categoryMap['food'], '晚餐');
    expect(decision?.categoryMap['shopping'], '购物');
  });

  testWidgets('labels an assets-only commit by the selected operation', (
    tester,
  ) async {
    final first = preview();
    final noNewRecords = DataImporter.previewJson(
      current: first.sourceData,
      source: BackupCodec.encodeString(first.sourceData),
    );
    await tester.pumpWidget(app(noNewRecords));

    final replace = find.byKey(
      ImportReviewSheet.strategyKey(AssetsImportStrategy.replace),
    );
    await tester.scrollUntilVisible(replace, 260);
    tester.widget<InkWell>(replace).onTap!();
    await tester.pump();

    expect(find.text('确认替换净值'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(ImportReviewSheet.confirmKey),
    );
    expect(button.onPressed, isNotNull);
  });
}
