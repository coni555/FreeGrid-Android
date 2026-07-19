import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/features/dashboard/dashboard_shell.dart';

void main() {
  test('dashboard body stops above the floating navigation hit area', () {
    expect(DashboardShell.extendsBehindNavigation, isFalse);
  });
}
