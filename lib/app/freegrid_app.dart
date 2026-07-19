import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/dashboard/dashboard_shell.dart';
import 'theme/freegrid_theme.dart';

class FreeGridApp extends StatefulWidget {
  const FreeGridApp({super.key});

  @override
  State<FreeGridApp> createState() => _FreeGridAppState();
}

class _FreeGridAppState extends State<FreeGridApp> {
  static const _themeKey = 'freegrid.appearance.dark';

  final _preferences = SharedPreferencesAsync();
  var _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final dark = await _preferences.getBool(_themeKey) ?? false;
    if (!mounted) return;
    setState(() => _themeMode = dark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _setDarkMode(bool dark) async {
    setState(() => _themeMode = dark ? ThemeMode.dark : ThemeMode.light);
    await _preferences.setBool(_themeKey, dark);
  }

  @override
  Widget build(BuildContext context) {
    final dark = _themeMode == ThemeMode.dark;
    return MaterialApp(
      title: 'FreeGrid',
      debugShowCheckedModeBanner: false,
      theme: FreeGridTheme.light(),
      darkTheme: FreeGridTheme.dark(),
      themeMode: _themeMode,
      themeAnimationDuration: const Duration(milliseconds: 280),
      themeAnimationCurve: Curves.easeInOutCubic,
      home: DashboardShell(isDarkMode: dark, onDarkModeChanged: _setDarkMode),
    );
  }
}
