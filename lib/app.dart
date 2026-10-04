import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'config/app_strings.dart';
import 'config/routes.dart';
import 'splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FidelisApp extends StatefulWidget {
  const FidelisApp({super.key});

  @override
  State<FidelisApp> createState() => _FidelisAppState();

  /// Access the app state to toggle theme from anywhere
  static _FidelisAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_FidelisAppState>();
  }
}

class _FidelisAppState extends State<FidelisApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    AppStrings.localeNotifier.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSettings() async {
    await AppStrings.load();
    final prefs = await SharedPreferences.getInstance();
    final darkMode = prefs.getBool('dark_mode') ?? false;
    if (!mounted) return;
    setState(() {
      _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void setDarkMode(bool darkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', darkMode);
    setState(() {
      _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey('app-${AppStrings.locale}'),
      title: 'Fidelis',
      debugShowCheckedModeBanner: false,
      theme: FidelisTheme.lightTheme,
      darkTheme: FidelisTheme.darkTheme,
      themeMode: _themeMode,
      locale: Locale(AppStrings.locale),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        ...AppRoutes.routes,
      },
    );
  }
}