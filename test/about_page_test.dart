import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/app/theme/freegrid_theme.dart';
import 'package:freegrid/features/dashboard/widgets/about_page.dart';

void main() {
  testWidgets('about page loads the real version slot and privacy promises', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(AboutPage(loadVersion: () async => '1.2.3 (45)')),
    );
    await tester.pumpAndSettle();

    expect(find.text('FreeGrid'), findsOneWidget);
    expect(find.text('1.2.3 (45)'), findsOneWidget);
    expect(find.text('本机存储'), findsOneWidget);
    expect(find.text('离线可用'), findsOneWidget);
    expect(find.text('无需账号'), findsOneWidget);
    expect(find.text('数据只留在你的设备上'), findsOneWidget);
    expect(find.bySemanticsLabel('版本，1.2.3 (45)'), findsOneWidget);
    final privacySemantics = tester
        .getSemantics(find.bySemanticsLabel('隐私政策，在浏览器中打开'))
        .getSemanticsData();
    expect(privacySemantics.flagsCollection.isButton, isTrue);
    expect(privacySemantics.hasAction(SemanticsAction.tap), isTrue);
    expect(find.text('ICP 备案号'), findsNothing);
    expect(find.text('评价与反馈'), findsNothing);
  });

  testWidgets('privacy row opens the exact public policy URL', (tester) async {
    Uri? opened;
    await tester.pumpWidget(
      _app(
        AboutPage(
          loadVersion: () async => '1.0.0 (1)',
          openExternalUrl: (url) async {
            opened = url;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AboutPage.privacyRowKey));
    await tester.pump();
    expect(opened, AboutPage.privacyUrl);
  });
}

Widget _app(Widget child) {
  return MaterialApp(theme: FreeGridTheme.light(), home: child);
}
