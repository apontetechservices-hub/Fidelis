import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidelis/config/app_strings.dart';
import 'package:fidelis/features/bible/bible_chapter_screen.dart';
import 'package:fidelis/features/rosary/rosary_prayer_screen.dart';
import 'package:fidelis/features/rosary/rosary_audio_files.dart';
import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/billing_service.dart';
import 'package:fidelis/services/bible_service.dart';
import 'package:fidelis/services/kokoro_engine.dart';

import 'audio_controller_test.dart';

/// NEXT ADVANCES IN BOTH ENGINE STATES (round 5, defect 1d): in the broken
/// fallback state the owner saw 'pressing Next STOPPED playback and Play
/// RESTARTED at the same place instead of advancing'. The root hole: the
/// screens' listening decisions read only the screen-local flag, which a
/// notification-side resume (or any playback start that did not pass
/// through the screen's own play button) leaves stale-false while the
/// stream is audibly playing — the old silent-navigation branch then
/// STOPPED the playing audio on Next. The fix reads the LIVE playback
/// state: playing always advances with audio; the paused semantics are
/// unchanged (the governing rule).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BillingService.premium.value = true;
    SharedPreferences.setMockInitialValues({});
    // The screens' render-ahead walks must abort cleanly in the widget
    // tests: the scripted override short-circuits synthesis without the
    // native engine or any platform channel (an unmocked path_provider
    // call would hang the walk's render forever in the fake-async zone
    // and leak the live-render demand the walk yields on).
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async =>
        null;
  });

  tearDown(() async {
    await AudioController.instance.stop();
    AudioController.instance.engineForTest = const TtsAudioEngine();
    KokoroEngine.resetForTest();
  });

  /// Loads the rosary manifest through real async (outside the test's
  /// FakeAsync zone) so the screen's initState finds warm caches.
  Future<void> warmRosaryManifest(WidgetTester tester) async {
    await tester.runAsync(() => RosaryAudioFiles.ensureLoaded());
  }

  /// Loads the Bible assets through real async so the screen's initState
  /// load finds warm caches. BOTH chapters the test navigates between —
  /// the multi-MB chapter asset never completes inside pump-driven frames.
  Future<void> warmBibleCache(WidgetTester tester, [String lang = 'en']) async {
    await tester.runAsync(() async {
      await AppStrings.setLanguage(lang);
      await BibleService.books();
      const book = BibleBook(
        key: 'Genesis',
        name: 'Genesis',
        testament: 'OT',
        order: 1,
        chapters: 50,
      );
      await BibleService.chapter(book, 1);
      await BibleService.chapter(book, 2);
    });
  }

  testWidgets('rosary Next while PLAYING with a stale-false listening '
      'flag (a notification-side resume) advances WITH audio', (tester) async {
    await warmRosaryManifest(tester);
    final engine = FakeAudioEngine();
    AudioController.instance.engineForTest = engine;
    await tester.pumpWidget(const MaterialApp(
      home: RosaryPrayerScreen(mysteryType: 'joyful'),
    ));
    await tester.pumpAndSettle();

    // Play via the screen (the flag ON), pause via the screen (the flag
    // OFF — the governing rule), then resume via the CONTROLLER — the
    // notification's play path, which never touches the screen's flag.
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(AudioController.instance.isPlayingFor('rosary'), isTrue);
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
    await tester.pump();
    expect(AudioController.instance.state, AudioState.paused);
    await AudioController.instance.resume();
    await tester.pump();
    await tester.pump();
    expect(AudioController.instance.isPlayingFor('rosary'), isTrue,
        reason: 'the notification-side resume is audibly playing');

    // NEXT: the playing stream must advance WITH audio — the stale flag
    // must not route the press into the silent-navigation stop.
    final speaksBefore =
        engine.log.where((e) => e.startsWith('speak:')).length;
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(
        AudioController.instance.state,
        AudioState.playing,
        reason: 'Next while playing must advance with audio in BOTH engine '
            'states — the old behavior stopped the stream here');
    expect(
        engine.log.where((e) => e.startsWith('speak:')).length,
        greaterThan(speaksBefore),
        reason: "the new step's audio started (the advance is audible, "
            'not a stop-and-restart of the same place)');

    // Cancel the word timer inside the body (the pending-timer invariant
    // checks before tearDown runs).
    await AudioController.instance.stop();
    await tester.pump();
  });

  testWidgets('rosary Next while PAUSED (an explicit in-app pause) stays '
      'silent navigation — the governing rule unchanged', (tester) async {
    await warmRosaryManifest(tester);
    final engine = FakeAudioEngine();
    AudioController.instance.engineForTest = engine;
    await tester.pumpWidget(const MaterialApp(
      home: RosaryPrayerScreen(mysteryType: 'joyful'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
    await tester.pump();
    expect(AudioController.instance.state, AudioState.paused);

    final speaksBefore =
        engine.log.where((e) => e.startsWith('speak:')).length;
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(AudioController.instance.state, AudioState.stopped,
        reason: 'Next after an explicit pause navigates silently (the '
            'abandoned step\'s paused stream is stale — stopped)');
    expect(engine.log.where((e) => e.startsWith('speak:')).length,
        speaksBefore,
        reason: 'no audio started (the user paused — navigation is silent)');

    // Cancel the word timer inside the body (the pending-timer invariant
    // checks before tearDown runs).
    await AudioController.instance.stop();
    await tester.pump();
  });

  testWidgets('bible chapter Next while PLAYING with a stale-false '
      'listening flag auto-continues into the new chapter', (tester) async {
    await warmBibleCache(tester);
    final engine = FakeAudioEngine();
    AudioController.instance.engineForTest = engine;
    const book = BibleBook(
      key: 'Genesis',
      name: 'Genesis',
      testament: 'OT',
      order: 1,
      chapters: 50,
    );
    await tester.pumpWidget(const MaterialApp(
      home: BibleChapterScreen(book: book, chapter: 1),
    ));
    await tester.pumpAndSettle();

    // Play via the screen, pause via the screen, resume via the
    // CONTROLLER (the notification's play path — the flag stays false).
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(AudioController.instance.isPlayingFor('bible'), isTrue);
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
    await tester.pump();
    expect(AudioController.instance.state, AudioState.paused);
    await AudioController.instance.resume();
    await tester.pump();
    await tester.pump();
    expect(AudioController.instance.isPlayingFor('bible'), isTrue);

    // The chapter Next: the new chapter must AUTO-CONTINUE (the stale
    // flag must not open it silently — the old behavior stopped the
    // playback with the old screen).
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    await tester.pump();
    expect(find.text('Genesis 2'), findsOneWidget);
    expect(
        AudioController.instance.state,
        AudioState.playing,
        reason: 'the chapter Next while playing must auto-continue with '
            'audio in BOTH engine states');

    // Cancel the word timer inside the body (the pending-timer invariant
    // checks before tearDown runs).
    await AudioController.instance.stop();
    await tester.pump();
  });
}
