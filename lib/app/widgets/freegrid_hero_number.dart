import 'package:flutter/material.dart';

import '../theme/freegrid_theme.dart';

/// Dashboard Hero 专用数字。
///
/// iOS 以 SF Pro Rounded UltraLight 显示自由天数；其设计注释说明原始视觉
/// 目标是 Geist 100。Android 端直接随包内置 Geist Thin，避免 Roboto 的
/// 字形差异，也不再用手工 Canvas 模拟字体轮廓。
class FreeGridHeroNumber extends StatelessWidget {
  const FreeGridHeroNumber({
    required this.value,
    required this.color,
    required this.height,
    super.key,
  });

  final String value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.visible,
      textAlign: TextAlign.center,
      style: context.numberStyle(
        height,
        color: color,
        weight: FontWeight.w100,
        height: 1,
        letterSpacing: -height * 0.04,
      ),
    );
  }
}
