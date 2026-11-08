import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'config/app_strings.dart';
import 'services/audio_controller.dart';
import 'services/audio_service_handler.dart';
import 'services/bible_address_migration.dart';
import 'services/notification_service.dart';
import 'services/tts_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // The media notification + lock-screen player for background audio: the
  // handler mirrors the AudioController's state into the media session and
  // routes the notification's play/pause/stop back through it, so the
  // in-app controls and the player always agree. The notification exists
  // only while audio is playing or paused (a backgrounded playback that
  // ends naturally parks it paused); no audio, no player. Must run before
  // runApp and before any audio starts.
  await AudioService.init(
    builder: () => FidelisAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.studiofideli.fidelis.audio',
      androidNotificationChannelName: 'Fidelis audio',
      androidNotificationChannelDescription: 'Prayer audio playback',
      // Pausing leaves the foreground so the notification stays swipeable
      // (resumable or dismissable); playing re-enters the foreground.
      androidStopForegroundOnPause: true,
      // The notification's accent: the app's liturgical gold — the player
      // reads as part of Fidelis.
      notificationColor: Color(0xFFC5A55A),
    ),
  );
  _wireAudioFocus();
  // The app language must be known before the Bible address migration: the
  // stored last-reading position is language-agnostic, and Spanish-saved
  // positions are already in the standard numbering (see
  // BibleAddressMigration). Loading here also gives the first build the
  // saved locale without waiting for the app state's own load.
  await AppStrings.load();
  // Bible address migration (v1.4.77): the English text was rebuilt to the
  // standard Douay-Rheims chapter divisions, so the stored last-reading
  // position from the old English numbering must remap to keep pointing at
  // the same verse text. One-time, flag-guarded; runs before runApp so no
  // Bible screen can read an unmigrated position.
  await BibleAddressMigration.apply();
  NotificationService.initialize();
  NotificationService.rescheduleSaved();
  // Warm the Kokoro TTS asset cache in the background (first launch copies
  // ~155 MB of model files to app storage; later launches are a no-op
  // marker check). Synthesis itself stays lazy.
  unawaited(TtsService.warmAssets());
  runApp(const FidelisApp());
}

/// Audio focus + unplug reactions: when another app takes focus (music, a
/// call, an alarm) or the headphones are unplugged, Fidelis pauses — and
/// STAYS paused after the interruption ends (no auto-resume; the user
/// resumes manually). Spoken-audio attributes: the system asks us to pause
/// rather than duck. Best-effort: never blocks startup.
Future<void> _wireAudioFocus() async {
  try {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());
    session.interruptionEventStream
        .where((event) => event.begin)
        .listen((_) => unawaited(AudioController.instance.pause()));
    session.becomingNoisyEventStream
        .listen((_) => unawaited(AudioController.instance.pause()));
  } catch (_) {}
}
