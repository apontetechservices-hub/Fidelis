import 'package:flutter/material.dart';
import '../features/rosary/rosary_screen.dart';
import '../features/readings/readings_screen.dart';
import '../features/prayers/prayers_screen.dart';
import '../features/saints/saints_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stations/stations_screen.dart';
import '../home_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String rosary = '/rosary';
  static const String readings = '/readings';
  static const String prayers = '/prayers';
  static const String saints = '/saints';
  static const String settings = '/settings';
  static const String stations = '/stations';

  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const HomeScreen(),
    rosary: (context) => const RosaryScreen(),
    readings: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is DateTime) {
        return ReadingsScreen(initialDate: args);
      }
      return const ReadingsScreen();
    },
    prayers: (context) => const PrayersScreen(),
    saints: (context) => const SaintsScreen(),
    settings: (context) => const SettingsScreen(),
    stations: (context) => const StationsScreen(),
  };
}