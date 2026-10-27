import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'services/tts_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  NotificationService.initialize();
  NotificationService.rescheduleSaved();
  // Warm the Kokoro TTS asset cache in the background (first launch copies
  // ~155 MB of model files to app storage; later launches are a no-op
  // marker check). Synthesis itself stays lazy.
  unawaited(TtsService.warmAssets());
  runApp(const FidelisApp());
}