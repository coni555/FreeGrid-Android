import 'package:flutter/material.dart';

@immutable
class FreeGridColors extends ThemeExtension<FreeGridColors> {
  const FreeGridColors({
    required this.paper,
    required this.mist,
    required this.mist2,
    required this.nav,
    required this.navSelected,
    required this.hairline,
    required this.hairlineSoft,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.inkGhost,
    required this.sky,
    required this.skyDeep,
    required this.skySoft,
    required this.skyFaint,
    required this.assetBlue,
    required this.incomeGold,
    required this.flame,
    required this.mossGreen,
  });

  static const light = FreeGridColors(
    paper: Color(0xFFF2F3F5),
    mist: Color(0xFFFEFFFF),
    mist2: Color(0xFFEEEEF1),
    nav: Color(0xF7FEFFFF),
    navSelected: Color(0xFFE8F2FA),
    hairline: Color(0xFFDEDEE1),
    hairlineSoft: Color(0xFFEBEBED),
    ink: Color(0xFF252428),
    inkMuted: Color(0xFF66656B),
    inkFaint: Color(0xFF949398),
    inkGhost: Color(0xFFBDBCC1),
    sky: Color(0xFF73B8EB),
    skyDeep: Color(0xFF4785C7),
    skySoft: Color(0xFFC7E0F5),
    skyFaint: Color(0xFFEDF5FC),
    assetBlue: Color(0xFF73B8EB),
    incomeGold: Color(0xFFE6A638),
    flame: Color(0xFFD16652),
    mossGreen: Color(0xFF5C9E6B),
  );

  static const dark = FreeGridColors(
    paper: Color(0xFF0A0B13),
    mist: Color(0xFF141621),
    mist2: Color(0xFF1C1F2D),
    nav: Color(0xF21C1F2B),
    navSelected: Color(0xFF111521),
    hairline: Color(0xFF373947),
    hairlineSoft: Color(0xFF272A37),
    ink: Color(0xFFF0F1F5),
    inkMuted: Color(0xFFA8ADBA),
    inkFaint: Color(0xFF7B8190),
    inkGhost: Color(0xFF505563),
    sky: Color(0xFF85C7F7),
    skyDeep: Color(0xFFA6D9FF),
    skySoft: Color(0xFF47668C),
    skyFaint: Color(0xFF1E2D41),
    assetBlue: Color(0xFF85C7F7),
    incomeGold: Color(0xFFEBCB73),
    flame: Color(0xFFF08C73),
    mossGreen: Color(0xFF8BD29E),
  );

  final Color paper;
  final Color mist;
  final Color mist2;
  final Color nav;
  final Color navSelected;
  final Color hairline;
  final Color hairlineSoft;
  final Color ink;
  final Color inkMuted;
  final Color inkFaint;
  final Color inkGhost;
  final Color sky;
  final Color skyDeep;
  final Color skySoft;
  final Color skyFaint;
  final Color assetBlue;
  final Color incomeGold;
  final Color flame;
  final Color mossGreen;

  @override
  FreeGridColors copyWith() => this;

  @override
  FreeGridColors lerp(covariant FreeGridColors? other, double t) {
    if (other == null) return this;
    return FreeGridColors(
      paper: Color.lerp(paper, other.paper, t)!,
      mist: Color.lerp(mist, other.mist, t)!,
      mist2: Color.lerp(mist2, other.mist2, t)!,
      nav: Color.lerp(nav, other.nav, t)!,
      navSelected: Color.lerp(navSelected, other.navSelected, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      hairlineSoft: Color.lerp(hairlineSoft, other.hairlineSoft, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      inkGhost: Color.lerp(inkGhost, other.inkGhost, t)!,
      sky: Color.lerp(sky, other.sky, t)!,
      skyDeep: Color.lerp(skyDeep, other.skyDeep, t)!,
      skySoft: Color.lerp(skySoft, other.skySoft, t)!,
      skyFaint: Color.lerp(skyFaint, other.skyFaint, t)!,
      assetBlue: Color.lerp(assetBlue, other.assetBlue, t)!,
      incomeGold: Color.lerp(incomeGold, other.incomeGold, t)!,
      flame: Color.lerp(flame, other.flame, t)!,
      mossGreen: Color.lerp(mossGreen, other.mossGreen, t)!,
    );
  }
}

extension FreeGridThemeContext on BuildContext {
  FreeGridColors get fg =>
      Theme.of(this).extension<FreeGridColors>() ?? FreeGridColors.light;

  /// FreeGrid 的数字字体层。中文正文继续走系统字体，所有关键数字通过这里
  /// 统一使用 Geist 与 tabular figures，避免各页面回退成不同的 Roboto。
  TextStyle numberStyle(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w300,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      color: color,
      fontFamily: 'Geist',
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

class FreeGridTheme {
  static ThemeData light() =>
      _base(brightness: Brightness.light, colors: FreeGridColors.light);

  static ThemeData dark() =>
      _base(brightness: Brightness.dark, colors: FreeGridColors.dark);

  static ThemeData _base({
    required Brightness brightness,
    required FreeGridColors colors,
  }) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.sky,
      onPrimary: dark ? const Color(0xFF07131D) : const Color(0xFF07131D),
      secondary: colors.incomeGold,
      onSecondary: dark ? const Color(0xFF241803) : const Color(0xFF201503),
      error: colors.flame,
      onError: dark ? const Color(0xFF250906) : Colors.white,
      surface: colors.mist,
      onSurface: colors.ink,
      onSurfaceVariant: colors.inkMuted,
      outline: colors.hairline,
      outlineVariant: colors.hairlineSoft,
    );

    final body = TextTheme(
      displayLarge: TextStyle(
        fontSize: 58,
        fontWeight: FontWeight.w200,
        letterSpacing: -1.6,
        color: colors.ink,
      ),
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.8,
        color: colors.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 29,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
        color: colors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
        color: colors.ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: colors.ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.35, color: colors.inkMuted),
      bodySmall: TextStyle(fontSize: 12, height: 1.3, color: colors.inkFaint),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: colors.ink,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.paper,
      extensions: [colors],
      textTheme: body,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.paper,
        foregroundColor: colors.ink,
        titleTextStyle: body.titleLarge,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: colors.hairlineSoft, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.mist,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.mist,
        modalBackgroundColor: colors.mist,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: colors.inkGhost),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.skyDeep, width: 1.2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.mist,
        contentTextStyle: TextStyle(color: colors.ink),
        actionTextColor: colors.skyDeep,
        elevation: 0,
        shape: StadiumBorder(side: BorderSide(color: colors.hairline)),
      ),
    );
  }
}
