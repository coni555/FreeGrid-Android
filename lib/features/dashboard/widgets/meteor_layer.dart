import 'package:flutter/material.dart';

import '../../../app/theme/freegrid_theme.dart';

/// iOS Dashboard Hero 的暗色流星背景。
///
/// 四颗流星共用一个 14 分钟循环的 controller（5/6/7/8 秒周期的最小公倍
/// 数），CustomPainter 直接监听 controller，动画过程中不会重建 Hero 内容。
class MeteorLayer extends StatefulWidget {
  const MeteorLayer({super.key});

  static const paintKey = ValueKey('meteor-layer-paint');
  static const meteorCount = 4;

  @override
  State<MeteorLayer> createState() => _MeteorLayerState();
}

class _MeteorLayerState extends State<MeteorLayer>
    with SingleTickerProviderStateMixin {
  static const _timelineSeconds = 840.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 840),
  );
  var _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 0;
      return;
    }

    if (!_seeded) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _controller.value = (now % 840000) / 840000;
      _seeded = true;
    }
    if (!_controller.isAnimating) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        key: MeteorLayer.paintKey,
        painter: _MeteorPainter(
          timeline: _controller,
          timelineSeconds: _timelineSeconds,
        ),
        isComplex: true,
        willChange: true,
        size: Size.infinite,
      ),
    );
  }
}

/// 保持原 Hero 卡片的圆角、描边和 padding，并仅在暗色且启用时插入流星。
class MeteorCardSurface extends StatelessWidget {
  const MeteorCardSurface({
    required this.enabled,
    required this.padding,
    required this.child,
    super.key,
  });

  final bool enabled;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final showMeteor =
        enabled && Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: context.fg.paper)),
            if (showMeteor)
              const Positioned.fill(
                child: IgnorePointer(
                  child: ExcludeSemantics(child: MeteorLayer()),
                ),
              ),
            Padding(padding: padding, child: child),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: context.fg.hairline, width: 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeteorPainter extends CustomPainter {
  _MeteorPainter({required this.timeline, required this.timelineSeconds})
    : super(repaint: timeline);

  final Animation<double> timeline;
  final double timelineSeconds;

  static const _meteors = [
    _MeteorParam(width: 90, topRatio: 0.10, delay: 1.0, duration: 6.0),
    _MeteorParam(width: 60, topRatio: 0.30, delay: 3.5, duration: 8.0),
    _MeteorParam(width: 110, topRatio: 0.20, delay: 6.0, duration: 5.0),
    _MeteorParam(width: 45, topRatio: 0.40, delay: 0.5, duration: 7.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final time = timeline.value * timelineSeconds;
    for (final meteor in _meteors) {
      final phase = ((time - meteor.delay) % meteor.duration) / meteor.duration;
      final opacity = switch (phase) {
        < 0.03 => 0.9 * phase / 0.03,
        < 0.25 => 0.9 * (1 - (phase - 0.03) / 0.22),
        _ => 0.0,
      };
      if (opacity <= 0) continue;

      final startX = -meteor.width;
      final endX = size.width + 50;
      final x = startX + (endX - startX) * phase;
      final y = meteor.topRatio * size.height + 30 * phase;
      final bounds = Rect.fromLTWH(x, y, meteor.width, 1);
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFB8D8FF).withValues(alpha: 0.8 * opacity),
            const Color(0xFF9CC3FF).withValues(alpha: 0.3 * opacity),
            Colors.transparent,
          ],
        ).createShader(bounds);
      canvas.drawRect(bounds, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeteorPainter oldDelegate) {
    return oldDelegate.timeline != timeline ||
        oldDelegate.timelineSeconds != timelineSeconds;
  }
}

class _MeteorParam {
  const _MeteorParam({
    required this.width,
    required this.topRatio,
    required this.delay,
    required this.duration,
  });

  final double width;
  final double topRatio;
  final double delay;
  final double duration;
}
