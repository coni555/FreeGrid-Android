import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/freegrid_theme.dart';

/// Dashboard 品牌栏：保留 Android 触控热区，只降低可见控件的重量。
class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    required this.isDarkMode,
    required this.heroVertical,
    required this.onToggleTheme,
    required this.onToggleHero,
    super.key,
  });

  static const themeMarkKey = ValueKey('dashboard-theme-mark');
  static const layoutIconKey = ValueKey('dashboard-layout-icon');

  final bool isDarkMode;
  final bool heroVertical;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleHero;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TopBarAction(
          tooltip: isDarkMode ? '切换浅色模式' : '切换深色模式',
          onPressed: () {
            HapticFeedback.selectionClick();
            onToggleTheme();
          },
          child: SizedBox.square(
            key: themeMarkKey,
            dimension: 22,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.fg.ink, width: 1),
              ),
              child: Center(
                child: isDarkMode
                    ? Icon(
                        Icons.dark_mode_rounded,
                        color: context.fg.sky,
                        size: 10,
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.fg.sky,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox.square(dimension: 9),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FreeGrid',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: context.fg.ink,
                  fontWeight: FontWeight.w500,
                  fontSize: 27,
                  letterSpacing: 0,
                  height: 1.04,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '通往财富自由之路',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.fg.inkFaint,
                  letterSpacing: 0,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        _TopBarAction(
          tooltip: heroVertical ? '切换左右布局' : '切换居中布局',
          onPressed: () {
            HapticFeedback.selectionClick();
            onToggleHero();
          },
          child: Icon(
            key: layoutIconKey,
            heroVertical
                ? Icons.view_agenda_outlined
                : Icons.view_week_outlined,
            color: context.fg.skyDeep,
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _TopBarAction extends StatelessWidget {
  const _TopBarAction({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: context.fg.skyDeep,
        overlayColor: context.fg.skyDeep.withValues(alpha: 0.08),
        shape: const CircleBorder(),
      ),
      icon: child,
    );
  }
}
