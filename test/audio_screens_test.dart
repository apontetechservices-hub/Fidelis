import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidelis/features/bible/bible_chapter_screen.dart';
import 'package:fidelis/features/rosary/rosary_prayer_screen.dart';
import 'package:fidelis/features/rosary/rosary_audio_files.dart';
import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/billing_service.dart';
import 'package:fidelis/services/bible_service.dart';
import 'package:fidelis/config/theme.dart';

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

  tearDown(() async {
    await AudioController.instance.stop();
    AudioController.instance.engineForTest = const TtsAudioEngine();
    BillingService.premium.value = false;
  });

  group('BibleChapterScreen audio controls', () {
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

  /// Counts TextSpan descendants whose background paint matches the
  /// recited-word tint (accent at 0.35 alpha) — the word-level highlight.
  /// Accepts either accent (the Bible follows the theme brightness; the
  /// rosary always uses gold). Components compare with a tolerance: Paint
  /// round-trips colors through float32 storage, so exact Color equality
  /// fails (alpha 0.35 comes back as 0.3500000238418579).
  int countWordTintSpans(WidgetTester tester) {
    final accents = [
      FidelisTheme.gold,
      FidelisTheme.deepRed,
    ];
    bool isTint(Color? bg) =>
        bg != null &&
        (bg.a - 0.35).abs() < 0.01 &&
        accents.any((accent) =>
            (bg.r - accent.r).abs() < 0.01 &&
            (bg.g - accent.g).abs() < 0.01 &&
            (bg.b - accent.b).abs() < 0.01);
    var count = 0;
    void walkRoot(TextSpan root) {
      void walk(TextSpan s) {
        if (isTint(s.style?.background?.color)) count++;
        for (final c in s.children ?? const <InlineSpan>[]) {
          if (c is TextSpan) walk(c);
        }
      }

      walk(root);
    }

    final richTexts = tester.widgetList<Widget>(find.byType(RichText));
    for (final w in richTexts) {
      final root = (w as RichText).text;
      if (root is TextSpan) walkRoot(root);
    }
    // SelectableText.rich renders via EditableText (no RichText widget in
    // the tree) — inspect its stored span directly.
    final selectableTexts = tester.widgetList<Widget>(find.byType(SelectableText));
    for (final w in selectableTexts) {
      final span = (w as SelectableText).textSpan;
      if (span != null) walkRoot(span);
    }
    return count;
  }

  group('Bible highlight sync (defect: highlight never reached the UI)', () {
    testWidgets('the recited verse highlights and the word advances within '
        'it while the voice plays', (tester) async {
      BillingService.premium.value = true;
      await warmBibleCache(tester);
      // Kokoro-like engine: one sentence (chars 0..12 of the chunk text)
      // with a 10s duration; the live position sits mid-sentence.
      final engine = TimingFakeEngine(
        sentenceTimings: [(0, 12, const Duration(seconds: 10))],
        position: const Duration(seconds: 5),
        duration: const Duration(seconds: 10),
      );
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

      expect(countWordTintSpans(tester), 0,
          reason: 'no highlight before playback');

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.pump();
      // One word-tick (200ms) after the sentence timing arrived.
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      // The verse-level highlight reached the UI: the first verse's text is
      // styled with the accent color.
      expect(AudioController.instance.listenable.value.sentenceIndex, 0);
      // The word-level highlight reached the UI: a recited-word tint span
      // exists inside the verse text.
      expect(countWordTintSpans(tester), greaterThan(0),
          reason: 'word-level highlight must be visible while the voice '
              'advances through the verse');

      await AudioController.instance.stop();
      await tester.pump();
      // Cleared when audio stops.
      expect(countWordTintSpans(tester), 0);
    });
  });

  group('Rosary highlight sync (defect: line highlight never reached the '
      'UI)', () {
    testWidgets('the recited line highlights and the word advances within '
        'it while the step audio plays', (tester) async {
      await warmRosaryManifest(tester);
      // Pre-rendered-file-like engine: a 12s asset with a live position.
      final engine = TimingFakeEngine(
        sentenceTimings: [],
        position: const Duration(seconds: 6),
        duration: const Duration(seconds: 12),
      );
      AudioController.instance.engineForTest = engine;
      await tester.pumpWidget(const MaterialApp(
        home: RosaryPrayerScreen(mysteryType: 'joyful'),
      ));
      await tester.pumpAndSettle();

      expect(countWordTintSpans(tester), 0,
          reason: 'no highlight before playback');

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      // The line-level highlight reached the UI: the prayer text is now
      // rendered with a recited-word tint span (the word being recited).
      expect(countWordTintSpans(tester), greaterThan(0),
          reason: 'line/word-level highlight must be visible while the '
              'voice advances through the prayer');

      await AudioController.instance.stop();
      await tester.pump();
      expect(countWordTintSpans(tester), 0);
    });
  });
}