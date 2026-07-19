import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/freegrid_theme.dart';
import '../../../core/domain/freedom_math.dart';

/// 把 Freedom Days 映射为固定颗粒、随宽度自动换行的生命网格。
///
/// 最后一格是 FreeGrid 的视觉记忆点：以 2 秒余弦曲线呼吸，并使用两层
/// glow。动画控制器只存在于这一格，不会让其余最多 364 格逐帧重建。
class LifeGrid extends StatelessWidget {
  const LifeGrid({
    required this.unit,
    required this.count,
    required this.assetCells,
    super.key,
  });

  static const currentCellKey = ValueKey('life-grid-current');

  final GridUnit unit;
  final int count;
  final int assetCells;

  @override
  Widget build(BuildContext context) {
    final cellSize = unit.cellSize;
    final spacing = unit.spacing;

    return Semantics(
      label: '自由网格，共 $count ${unit.label}',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = math.max(
              1,
              constraints.maxWidth ~/ (cellSize + spacing),
            );
            final visibleColumns = math.min(columns, count);
            final gridWidth =
                visibleColumns * cellSize + (visibleColumns - 1) * spacing;

            return Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: gridWidth,
                child: Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (var index = 0; index < count; index += 1)
                      _GridCell(
                        key: ValueKey('life-grid-cell-$index'),
                        size: cellSize,
                        radius: cellSize * 0.11,
                        color: index < assetCells
                            ? context.fg.incomeGold
                            : context.fg.assetBlue,
                        isCurrent: index == count - 1,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.size,
    required this.radius,
    required this.color,
    required this.isCurrent,
    super.key,
  });

  final double size;
  final double radius;
  final Color color;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    if (isCurrent) {
      return _BreathingGridCell(size: size, baseColor: color);
    }

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _BreathingGridCell extends StatefulWidget {
  const _BreathingGridCell({required this.size, required this.baseColor});

  final double size;
  final Color baseColor;

  @override
  State<_BreathingGridCell> createState() => _BreathingGridCellState();
}

class _BreathingGridCellState extends State<_BreathingGridCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isAsset = widget.baseColor == context.fg.incomeGold;
    final currentColor = dark
        ? (isAsset ? const Color(0xFFFFEBA6) : const Color(0xFFD4EBFF))
        : (isAsset ? const Color(0xFFB89433) : const Color(0xFF3380C7));
    final innerGlowColor = dark
        ? Colors.white
        : (isAsset ? const Color(0xFF8C7326) : const Color(0xFF26598C));
    final peakScale = dark ? 1.6 : 1.35;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final phase = _controller.value * 2 * math.pi;
          final breath = 0.5 - 0.5 * math.cos(phase);
          final scale = 1.1 + (peakScale - 1.1) * breath;
          final innerOpacity = dark ? 0.5 + 0.3 * breath : 0.25 + 0.15 * breath;
          final outerOpacity = dark ? 0.4 + 0.1 * breath : 0.30 + 0.10 * breath;

          return Transform.scale(
            key: LifeGrid.currentCellKey,
            scale: scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(widget.size * 0.17),
                boxShadow: [
                  BoxShadow(
                    color: innerGlowColor.withValues(alpha: innerOpacity),
                    blurRadius: 4 + 3 * breath,
                  ),
                  BoxShadow(
                    color: widget.baseColor.withValues(alpha: outerOpacity),
                    blurRadius: 9 + 6 * breath,
                  ),
                ],
              ),
              child: SizedBox.square(dimension: widget.size),
            ),
          );
        },
      ),
    );
  }
}

extension on GridUnit {
  double get cellSize => switch (this) {
    GridUnit.day => 9,
    GridUnit.month => 12,
    GridUnit.year => 16,
  };

  double get spacing => switch (this) {
    GridUnit.day => 2.5,
    GridUnit.month => 3,
    GridUnit.year => 3.5,
  };
}
