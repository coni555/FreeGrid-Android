import 'package:flutter_test/flutter_test.dart';
import 'package:freegrid/features/dashboard/widgets/freedom_hero_presentation.dart';

void main() {
  group('FreedomHeroPresentation', () {
    test('does not claim freedom before there is spending data', () {
      final state = FreedomHeroPresentation.resolve(
        dailyBurn: 0,
        freedomDays: double.infinity,
      );

      expect(state.display, '—');
      expect(state.kicker, 'FREEDOM DAYS');
      expect(state.hasBurnData, isFalse);
      expect(state.isCovered, isFalse);
    });

    test('keeps genuine passive coverage as freedom', () {
      final state = FreedomHeroPresentation.resolve(
        dailyBurn: 50,
        freedomDays: double.infinity,
      );

      expect(state.display, '∞');
      expect(state.kicker, 'FREEDOM');
      expect(state.hasBurnData, isTrue);
      expect(state.isCovered, isTrue);
    });

    test('keeps finite freedom unit and number presentation', () {
      final state = FreedomHeroPresentation.resolve(
        dailyBurn: 50,
        freedomDays: 93,
      );

      expect(state.display, '93');
      expect(state.kicker, 'FREEDOM DAYS');
      expect(state.isCovered, isFalse);
    });
  });
}
