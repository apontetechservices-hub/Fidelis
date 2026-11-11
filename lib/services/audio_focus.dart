import 'dart:async';

import 'package:audio_session/audio_session.dart';

import 'audio_controller.dart';

/// Audio focus + unplug reactions: when another app takes focus (music, a
/// call, an alarm) or the headphones are unplugged, Fidelis pauses — and
/// STAYS paused after the interruption ends (no auto-resume; the user
/// resumes manually). The interruption-begin → pause wiring is the app's
/// (just_audio's own handler is disabled — its default auto-RESUMES after
/// an interruption, which the app must not do); the interruption-end →
/// nothing.
///
/// The routing is injectable so the mechanics are testable: production
/// passes audio_session's streams (see main.dart); tests pass fakes and
/// assert the pause-on-loss + stay-paused behavior directly.

/// Wires [interruptions] (begin events pause) and [becomingNoisy] (an
/// unplug pauses) to [controller]. Every reaction is logged through
/// [onEvent] (the diagnostics path — the device shows that the event
/// arrived and the pause executed, so a field report can distinguish "the
/// event never arrived" from "the pause failed"). Returns the
/// subscriptions (main.dart keeps them alive for the process lifetime;
/// tests cancel them).
List<StreamSubscription<dynamic>> wireAudioFocus({
  required Stream<AudioInterruptionEvent> interruptions,
  required Stream<void> becomingNoisy,
  required AudioController controller,
  void Function(String line)? onEvent,
}) {
  final subs = <StreamSubscription<dynamic>>[];
  subs.add(interruptions.listen((event) {
    if (!event.begin) return; // the interruption end: nothing (stay paused)
    onEvent?.call('focus loss (${event.type.name}) → paused (stays paused)');
    unawaited(controller.pause());
  }));
  subs.add(becomingNoisy.listen((_) {
    onEvent?.call('headphones unplugged → paused (stays paused)');
    unawaited(controller.pause());
  }));
  return subs;
}

/// Production wiring: configures the speech session (spoken-audio
/// attributes — the system asks us to pause rather than duck) and wires
/// the focus reactions. The listeners register BEFORE the configuration —
/// a configure failure must not take the focus reactions down with it
/// (the round-3 hardening: the old inline wiring's single try/catch
/// swallowed everything silently). Best-effort: never blocks startup; a
/// failure is recorded through [onEvent] instead of dying silently (the
/// diagnostics path shows WHY focus handling is off).
Future<void> configureAudioFocus({
  required AudioController controller,
  void Function(String line)? onEvent,
}) async {
  try {
    final session = await AudioSession.instance;
    wireAudioFocus(
      interruptions: session.interruptionEventStream,
      becomingNoisy: session.becomingNoisyEventStream,
      controller: controller,
      onEvent: onEvent,
    );
    await session.configure(AudioSessionConfiguration.speech());
  } catch (e) {
    onEvent?.call('audio focus wiring failed: $e');
  }
}
