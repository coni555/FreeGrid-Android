import '../../../core/domain/freedom_math.dart';

/// 把核心数学结果翻译成 Hero 展示状态。
///
/// `dailyBurn == 0` 时核心层按数学定义返回无穷，但产品层不能把“尚无消费
/// 样本”误写成“已经财富自由”，因此在这里明确区分两种状态。
class FreedomHeroPresentation {
  const FreedomHeroPresentation({
    required this.display,
    required this.kicker,
    required this.hasBurnData,
    required this.isCovered,
  });

  factory FreedomHeroPresentation.resolve({
    required double dailyBurn,
    required double freedomDays,
  }) {
    final hasBurnData = dailyBurn > 0;
    final isCovered = hasBurnData && freedomDays.isInfinite;
    if (!hasBurnData) {
      return const FreedomHeroPresentation(
        display: '—',
        kicker: 'FREEDOM DAYS',
        hasBurnData: false,
        isCovered: false,
      );
    }
    if (isCovered) {
      return const FreedomHeroPresentation(
        display: '∞',
        kicker: 'FREEDOM',
        hasBurnData: true,
        isCovered: true,
      );
    }

    final unit = FreedomMath.freedomDaysUnit(freedomDays);
    return FreedomHeroPresentation(
      display: FreedomMath.freedomDaysDisplay(freedomDays),
      kicker: switch (unit) {
        FreedomUnit.day => 'FREEDOM DAYS',
        FreedomUnit.month => 'FREEDOM MONTHS',
        FreedomUnit.year => 'FREEDOM YEARS',
      },
      hasBurnData: true,
      isCovered: false,
    );
  }

  final String display;
  final String kicker;
  final bool hasBurnData;
  final bool isCovered;
}
