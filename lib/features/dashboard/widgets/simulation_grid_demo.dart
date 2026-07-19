import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/freegrid_theme.dart';
import '../../../core/domain/freedom_math.dart';

@immutable
class SimulationGridSnapshot {
  const SimulationGridSnapshot({
    required this.unit,
    required this.count,
    required this.assetCells,
  });

  factory SimulationGridSnapshot.fromFreedomDays({
    required GridUnit unit,
    required double freedomDays,
    required double lockedAssets,
    required double netWorth,
  }) {
    final rawCount = freedomDays.isFinite
        ? switch (unit) {
            GridUnit.day => freedomDays,
            GridUnit.month => freedomDays / 30.44,
            GridUnit.year => freedomDays / 365.25,
          }
        : unit.maxCells.toDouble();
    final count = rawCount.floor().clamp(0, unit.maxCells);
    final assetCells = netWorth > 0 && count > 0
        ? (count * math.max(0, lockedAssets) / netWorth).round().clamp(0, count)
        : 0;
    return SimulationGridSnapshot(
      unit: unit,
      count: count,
      assetCells: assetCells,
    );
  }

  final GridUnit unit;
  final int count;
  final int assetCells;
}

@immutable
class SimulationGridTiming {
  const SimulationGridTiming({
    required this.spanSeconds,
    required this.cellDurationSeconds,
  });

  factory SimulationGridTiming.resolve({
    required int delta,
    required bool ignite,
  }) {
    if (ignite) {
      return SimulationGridTiming(
        spanSeconds: math.min(3, math.max(0.5, 0.18 * delta)),
        cellDurationSeconds: 0.72,
      );
    }
    return SimulationGridTiming(
      spanSeconds: math.min(1.6, math.max(0.25, 0.10 * delta)),
      cellDurationSeconds: 0.55,
    );
  }

  final double spanSeconds;
  final double cellDurationSeconds;

  double get totalSeconds => spanSeconds + cellDurationSeconds;
}

@immutable
class SimulationCellVisual {
  const SimulationCellVisual({
    required this.opacity,
    required this.scale,
    required this.glow,
  });

  final double opacity;
  final double scale;
  final double glow;
}

SimulationCellVisual resolveSimulationCellVisual({
  required int index,
  required int oldCount,
  required int newCount,
  required double elapsedSeconds,
}) {
  final stableCount = math.min(oldCount, newCount);
  if (index < stableCount) {
    return const SimulationCellVisual(opacity: 1, scale: 1, glow: 0);
  }

  final ignite = newCount > oldCount;
  final delta = (newCount - oldCount).abs();
  if (delta == 0) {
    return const SimulationCellVisual(opacity: 1, scale: 1, glow: 0);
  }
  final timing = SimulationGridTiming.resolve(delta: delta, ignite: ignite);
  final cascadeIndex = ignite ? index - oldCount : oldCount - 1 - index;
  final start = delta <= 1
      ? 0.0
      : cascadeIndex / (delta - 1) * timing.spanSeconds;
  final local = ((elapsedSeconds - start) / timing.cellDurationSeconds).clamp(
    0.0,
    1.0,
  );

  if (ignite) {
    final envelope = _envelope(local, attack: 0.12, release: 1.4);
    return SimulationCellVisual(
      opacity: 0.14 + 0.86 * _easeOut(math.min(1, local / 0.30)),
      scale: 1 + 0.20 * envelope,
      glow: envelope * 0.9,
    );
  }

  final envelope = _envelope(local, attack: 0.16, release: 1.4);
  return SimulationCellVisual(
    opacity: 1 - 0.86 * _easeOut(math.min(1, local / 0.55)),
    scale: 1 + 0.12 * envelope,
    glow: envelope * 0.8,
  );
}

class SimulationGridDemo extends StatefulWidget {
  const SimulationGridDemo({
    required this.before,
    required this.after,
    required this.isExpense,
    super.key,
  });

  static const paintKey = ValueKey('simulation-grid-paint');
  static const playKey = ValueKey('simulation-grid-play');
  static const reducedMotionKey = ValueKey('simulation-grid-reduced-motion');

  final SimulationGridSnapshot before;
  final SimulationGridSnapshot after;
  final bool isExpense;

  @override
  State<SimulationGridDemo> createState() => _SimulationGridDemoState();
}

enum _DemoPhase { idle, playing, done }

class _SimulationGridDemoState extends State<SimulationGridDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _phase = _DemoPhase.idle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _phase = _DemoPhase.done);
        }
      });
  }

  int get _delta => (widget.after.count - widget.before.count).abs();
  bool get _ignite => widget.after.count > widget.before.count;

  @override
  void didUpdateWidget(covariant SimulationGridDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.before.count != widget.before.count ||
        oldWidget.before.assetCells != widget.before.assetCells ||
        oldWidget.after.count != widget.after.count ||
        oldWidget.after.assetCells != widget.after.assetCells ||
        oldWidget.isExpense != widget.isExpense) {
      _controller.reset();
      _phase = _DemoPhase.idle;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _play() {
    if (_phase == _DemoPhase.playing || _delta == 0) return;
    HapticFeedback.selectionClick();
    final timing = SimulationGridTiming.resolve(delta: _delta, ignite: _ignite);
    _controller.duration = Duration(
      milliseconds: (timing.totalSeconds * 1000).round(),
    );
    setState(() => _phase = _DemoPhase.playing);
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final accent = widget.isExpense ? context.fg.flame : context.fg.skyDeep;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.fg.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.fg.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'GRID PREVIEW · 格子推演',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.fg.inkFaint,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.before.count} → ${widget.after.count} ${widget.before.unit.label}',
                style: context.numberStyle(
                  12,
                  color: context.fg.inkFaint,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_delta == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                widget.isExpense
                    ? '不足一格——还在当日预算内，这笔不削自由。'
                    : '不足一格——这笔还不够点亮一格自由。',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: context.fg.inkMuted),
              ),
            )
          else if (reduceMotion)
            _ReducedMotionComparison(
              key: SimulationGridDemo.reducedMotionKey,
              before: widget.before,
              after: widget.after,
              accent: accent,
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final height = SimulationGridPainter.gridHeight(
                  width: constraints.maxWidth,
                  unit: widget.before.unit,
                  count: math.max(widget.before.count, widget.after.count),
                );
                return RepaintBoundary(
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: height,
                    child: CustomPaint(
                      key: SimulationGridDemo.paintKey,
                      painter: SimulationGridPainter(
                        progress: _controller,
                        before: widget.before,
                        after: widget.after,
                        assetColor: context.fg.incomeGold,
                        cashColor: context.fg.assetBlue,
                        extinguishGlowColor: context.fg.flame,
                      ),
                      isComplex: true,
                      willChange: _phase == _DemoPhase.playing,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                Icon(
                  widget.isExpense
                      ? Icons.local_fire_department_outlined
                      : Icons.auto_awesome_rounded,
                  size: 14,
                  color: accent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.isExpense
                        ? '熄灭 $_delta 格 · 每格 1 ${widget.before.unit.label}自由'
                        : '点亮 $_delta 格 · 每格 1 ${widget.before.unit.label}自由',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: context.fg.inkFaint),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: SimulationGridDemo.playKey,
                onPressed: _phase == _DemoPhase.playing ? null : _play,
                icon: Icon(
                  _phase == _DemoPhase.done
                      ? Icons.replay_rounded
                      : Icons.play_arrow_rounded,
                  size: 18,
                ),
                label: Text(switch (_phase) {
                  _DemoPhase.idle =>
                    widget.isExpense ? '演示这笔熄灭哪几格' : '演示这笔点亮哪几格',
                  _DemoPhase.playing => '推演中…',
                  _DemoPhase.done => '重播',
                }),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  disabledForegroundColor: context.fg.inkGhost,
                  side: BorderSide(
                    color: _phase == _DemoPhase.playing
                        ? context.fg.hairline
                        : accent,
                  ),
                  minimumSize: const Size.fromHeight(46),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SimulationGridPainter extends CustomPainter {
  SimulationGridPainter({
    required this.progress,
    required this.before,
    required this.after,
    required this.assetColor,
    required this.cashColor,
    required this.extinguishGlowColor,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final SimulationGridSnapshot before;
  final SimulationGridSnapshot after;
  final Color assetColor;
  final Color cashColor;
  final Color extinguishGlowColor;

  static double gridHeight({
    required double width,
    required GridUnit unit,
    required int count,
  }) {
    if (count <= 0) return 0;
    final cell = unit.cellSize;
    final spacing = unit.spacing;
    final columns = math.max(1, ((width + spacing) / (cell + spacing)).floor());
    final rows = (count / columns).ceil();
    return rows * cell + math.max(0, rows - 1) * spacing;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final total = math.max(before.count, after.count);
    if (total == 0) return;
    final delta = (after.count - before.count).abs();
    final ignite = after.count > before.count;
    final timing = SimulationGridTiming.resolve(delta: delta, ignite: ignite);
    final elapsed = progress.value * timing.totalSeconds;
    final cell = before.unit.cellSize;
    final spacing = before.unit.spacing;
    final columns = math.max(
      1,
      ((size.width + spacing) / (cell + spacing)).floor(),
    );

    for (var index = 0; index < total; index += 1) {
      final visual = resolveSimulationCellVisual(
        index: index,
        oldCount: before.count,
        newCount: after.count,
        elapsedSeconds: elapsed,
      );
      final assetBoundary = index < math.min(before.count, after.count)
          ? after.assetCells
          : ignite
          ? after.assetCells
          : before.assetCells;
      final base = index < assetBoundary ? assetColor : cashColor;
      final row = index ~/ columns;
      final column = index % columns;
      final center = Offset(
        column * (cell + spacing) + cell / 2,
        row * (cell + spacing) + cell / 2,
      );
      final dimension = cell * visual.scale;
      final rect = Rect.fromCenter(
        center: center,
        width: dimension,
        height: dimension,
      );
      final radius = Radius.circular(cell * 0.13);

      if (visual.glow > 0.01) {
        final glowColor = ignite ? base : extinguishGlowColor;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius),
          Paint()
            ..color = glowColor.withValues(alpha: visual.glow * 0.7)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              cell * 0.65 * visual.glow,
            ),
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()..color = base.withValues(alpha: visual.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SimulationGridPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.before != before ||
        oldDelegate.after != after ||
        oldDelegate.assetColor != assetColor ||
        oldDelegate.cashColor != cashColor ||
        oldDelegate.extinguishGlowColor != extinguishGlowColor;
  }
}

class _ReducedMotionComparison extends StatelessWidget {
  const _ReducedMotionComparison({
    required this.before,
    required this.after,
    required this.accent,
    super.key,
  });

  final SimulationGridSnapshot before;
  final SimulationGridSnapshot after;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _StaticMiniGrid(snapshot: before, opacity: 0.42)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.arrow_forward_rounded, color: accent, size: 18),
        ),
        Expanded(child: _StaticMiniGrid(snapshot: after, opacity: 1)),
      ],
    );
  }
}

class _StaticMiniGrid extends StatelessWidget {
  const _StaticMiniGrid({required this.snapshot, required this.opacity});

  final SimulationGridSnapshot snapshot;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    const maxCells = 60;
    final visible = math.min(maxCells, snapshot.count);
    final assetRatio = snapshot.count == 0
        ? 0.0
        : snapshot.assetCells / snapshot.count;
    final visibleAssets = (visible * assetRatio).round();
    return Opacity(
      opacity: opacity,
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        children: [
          for (var index = 0; index < visible; index += 1)
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: index < visibleAssets
                    ? context.fg.incomeGold
                    : context.fg.assetBlue,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
        ],
      ),
    );
  }
}

double _easeOut(double value) {
  final clamped = value.clamp(0.0, 1.0);
  return 1 - math.pow(1 - clamped, 4).toDouble();
}

double _envelope(
  double value, {
  required double attack,
  required double release,
}) {
  if (value >= 1) return 0;
  if (value < attack) return _easeOut(value / attack);
  return math.pow(1 - (value - attack) / (1 - attack), release).toDouble();
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
