import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidelis/features/bible/bible_chapter_screen.dart';
import 'package:fidelis/features/rosary/rosary_prayer_screen.dart';
import 'package:fidelis/features/rosary/rosary_audio_files.dart';
import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/billing_service.dart';
import 'package:fidelis/services/bible_service.dart';

import 'audio_controller_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Each test must load the manifest in its own FakeAsync zone: futures
    // completed in a previous test's zone never resume when awaited here.
    RosaryAudioFiles.resetForTest();
  });

  /// Loads the rosary manifest through real async (outside the test's
  /// FakeAsync zone). A load started inside the zone stalls: its completion
  /// microtask lands on the zone's own queue, which pump-driven bodies never
  /// drain; a real-zone future resumed via runAsync does.
  Future<void> warmRosaryManifest(WidgetTester tester) async {
    await tester.runAsync(() => RosaryAudioFiles.ensureLoaded());
  }

  tearDown(() async {
    await AudioController.instance.stop();
    AudioController.instance.engineForTest = const TtsAudioEngine();
    BillingService.premium.value = false;
  });

  group('BibleChapterScreen audio controls', () {
    /// Loads the Bible assets through real async (outside the test's
    /// FakeAsync zone) so the screen's initState load finds warm caches —
    /// the multi-MB chapter asset never completes inside pump-driven frames.
    Future<void> warmBibleCache(WidgetTester tester) async {
      await tester.runAsync(() async {
        await BibleService.books();
        const book = BibleBook(
          key: 'Genesis',
          name: 'Genesis',
          testament: 'OT',
          order: 1,
          chapters: 50,
        );
        await BibleService.chapter(book, 1);
      });
    }

    testWidgets('has a centered play/pause toggle and no speaker button',
        (tester) async {
      BillingService.premium.value = true;
      await warmBibleCache(tester);
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

      // The old AppBar speaker control is gone.
      expect(find.byIcon(Icons.volume_up), findsNothing);
      expect(find.byIcon(Icons.volume_off), findsNothing);
      // Exactly one centered play toggle.
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('tapping play starts audio through the controller; tapping '
        'again pauses', (tester) async {
      BillingService.premium.value = true;
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

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // The chapter text went to the engine as TTS chunks.
      expect(engine.log.any((e) => e.startsWith('speak:')), isTrue);
      expect(AudioController.instance.isPlayingFor('bible'), isTrue);
      // Icon flipped to pause while playing.
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      await tester.pump();
      expect(engine.log, contains('pause'));
      expect(AudioController.instance.state, AudioState.paused);
      // Paused shows the play icon again.
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  });

  group('RosaryPrayerScreen audio controls', () {
    testWidgets('has a centered play/pause toggle and no speaker button',
        (tester) async {
      await warmRosaryManifest(tester);
      await tester.pumpWidget(const MaterialApp(
        home: RosaryPrayerScreen(mysteryType: 'joyful'),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.volume_up), findsNothing);
      expect(find.byIcon(Icons.volume_off), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('tapping play starts the step audio; tapping again pauses',
        (tester) async {
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

      // The step played through the controller (pre-rendered asset or
      // runtime TTS text — either way exactly one stream).
      expect(
        engine.log.any((e) => e.startsWith('asset:') || e.startsWith('speak:')),
        isTrue,
      );
      expect(AudioController.instance.isPlayingFor('rosary'), isTrue);
      expect(find.byIcon(Icons.pause), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      await tester.pump();
      expect(engine.log, contains('pause'));
      expect(AudioController.instance.state, AudioState.paused);
    });

    testWidgets('Next while playing auto-continues with the new step',
        (tester) async {
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
      expect(AudioController.instance.isPlayingFor('rosary'), isTrue);
      final playsBefore = engine.log.length;

      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Audio carried over without pressing play again.
      expect(AudioController.instance.isPlayingFor('rosary'), isTrue);
      expect(engine.log.length, greaterThan(playsBefore));
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('Next while never started does not autoplay', (tester) async {
      await warmRosaryManifest(tester);
      final engine = FakeAudioEngine();
      AudioController.instance.engineForTest = engine;
      await tester.pumpWidget(const MaterialApp(
        home: RosaryPrayerScreen(mysteryType: 'joyful'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump();

      expect(engine.log, isEmpty);
      expect(AudioController.instance.state, AudioState.stopped);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  });
}