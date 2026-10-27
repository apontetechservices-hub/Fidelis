import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidelis/features/bible/bible_chapter_screen.dart';
import 'package:fidelis/features/rosary/rosary_controller.dart';
import 'package:fidelis/features/rosary/rosary_prayer_screen.dart';
import 'package:fidelis/features/rosary/rosary_audio_files.dart';
import 'package:fidelis/features/rosary/rosary_prayers.dart';
import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/billing_service.dart';
import 'package:fidelis/services/bible_service.dart';
import 'package:fidelis/services/tts_service.dart';
import 'package:fidelis/config/app_strings.dart';
import 'package:fidelis/config/theme.dart';

import 'audio_controller_test.dart';

/// flutter_tts-fallback-like engine with a deterministic, test-driven word
/// sweep: fires onSentenceStart once per chunk (the fallback path's
/// signature — the trigger of the frozen-verse Bible defect), then emits
/// word-boundary events ONE PER [tick] call as the test advances them. When
/// the chunk's words are exhausted the chunk completes (the audio ran out)
/// and the controller advances to the next chunk. No timers: the test
/// controls every step, so assertions are exact.
class SweepEngine implements AudioEngine {
  final List<String> log = [];
  bool _paused = false;

  void Function(int, int)? _sink;
  final List<(int, int)> _pending = [];
  Completer<void>? _gate;

  @override
  Future<void> speakText(
    String text, {
    String? lang,
    void Function(int sentenceIndex)? onSentenceStart,
    void Function(int charStart, int charEnd, Duration? duration)?
        onSentenceTiming,
    void Function(int charStart, int charEnd)? onWordRange,
  }) async {
    log.add('speak:$text');
    onSentenceStart?.call(0);
    _sink = onWordRange;
    _pending.clear();
    final wordPattern = RegExp(r'[0-9A-Za-z\u00C0-\u024F]+');
    for (final m in wordPattern.allMatches(text)) {
      _pending.add((m.start, m.end));
    }
    _gate = Completer<void>();
    await _gate!.future;
  }

  /// Emits the next pending word event; when the chunk's words are
  /// exhausted, ends the chunk's playback so the next chunk starts.
  void tick() {
    final sink = _sink;
    if (sink == null) return;
    if (_pending.isEmpty) {
      finishChunk();
      return;
    }
    final (s, e) = _pending.removeAt(0);
    sink(s, e);
  }

  /// Ends the current chunk's playback (natural completion).
  void finishChunk() {
    final gate = _gate;
    _gate = null;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  @override
  Future<void> playAsset(String asset) async {
    log.add('asset:$asset');
    _gate = Completer<void>();
    await _gate!.future;
  }

  @override
  (Duration, Duration?)? get progress => null;

  @override
  Future<List<Duration>?> sentenceDurations(String text, String lang,
      {bool Function()? shouldAbort}) async => null;

  @override
  Future<void> pause() async {
    log.add('pause');
    _paused = true;
  }

  @override
  Future<void> resume() async {
    log.add('resume');
    _paused = false;
  }

  @override
  Future<void> stop() async {
    log.add('stop');
    finishChunk();
    _paused = false;
  }

  @override
  bool get isPaused => _paused;
}

/// Mimics a device where every step's audio fails/ends instantly (e.g. a
/// broken asset load): each chunk completes without waiting. With the old
/// natural-completion auto-advance this chained the page to the ending
/// prayers within a second of pressing play.
class InstantAssetEngine extends FakeAudioEngine {
  @override
  Future<void> speakText(
    String text, {
    String? lang,
    void Function(int sentenceIndex)? onSentenceStart,
    void Function(int charStart, int charEnd, Duration? duration)?
        onSentenceTiming,
    void Function(int charStart, int charEnd)? onWordRange,
  }) async {
    log.add('speak:$text');
  }

  @override
  Future<void> playAsset(String asset) async {
    log.add('asset:$asset');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Each test must load the manifest in its own FakeAsync zone: futures
    // completed in a previous test's zone never resume when awaited here.
    RosaryAudioFiles.resetForTest();
    // AppStrings._locale is global static state — reset per test.
    await AppStrings.setLanguage('en');
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
  /// [lang] also sets the app language, warming that language's text cache.
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
    });
  }

  /// The rosary screen's current step index, read from the progress bar
  /// (value = (step + 1) / stepCount) — exact, no label parsing.
  int rosaryStep(WidgetTester tester) {
    final count = RosaryController.buildRosarySteps(
      mysteryTypes: List.filled(5, 'joyful'),
      includeLuminous: false,
      isForDead: false,
    ).length;
    final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator));
    return ((bar.value! * count) - 1).round();
  }

  /// The joined text of the recited line's gold spans (the line may be
  /// split around the highlighted word), or null when nothing highlights.
  String? speakingLineText(WidgetTester tester) {
    final parts = <String>[];
    void walk(TextSpan s) {
      if (s.style?.color == FidelisTheme.gold &&
          s.style?.fontWeight == FontWeight.w600 &&
          s.text != null) {
        parts.add(s.text!);
      }
      for (final c in s.children ?? const <InlineSpan>[]) {
        if (c is TextSpan) walk(c);
      }
    }

    for (final w in tester.widgetList<Widget>(find.byType(SelectableText))) {
      final span = (w as SelectableText).textSpan;
      if (span is TextSpan) walk(span);
    }
    return parts.isEmpty ? null : parts.join();
  }

  tearDown(() async {
    await AudioController.instance.stop();
    AudioController.instance.engineForTest = const TtsAudioEngine();
    BillingService.premium.value = false;
    await AppStrings.setLanguage('en');
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

    testWidgets('Next while playing continues into the next chapter '
        '(regression: Bible Next auto-continue)', (tester) async {
      BillingService.premium.value = true;
      await warmBibleCache(tester);
      const book = BibleBook(
        key: 'Genesis',
        name: 'Genesis',
        testament: 'OT',
        order: 1,
        chapters: 50,
      );
      // The next chapter's text must be warm too: the pushed screen loads
      // it inside pump-driven frames, which never complete otherwise.
      await tester.runAsync(() => BibleService.chapter(book, 2));
      final engine = FakeAudioEngine();
      AudioController.instance.engineForTest = engine;
      await tester.pumpWidget(const MaterialApp(
        home: BibleChapterScreen(book: book, chapter: 1),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(AudioController.instance.isPlayingFor('bible'), isTrue);

      await tester.tap(find.text('Next'));
      // Let the route transition finish and the old screen dispose (both
      // screens coexist mid-transition, each with its own toggle).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump();

      // The pushed chapter screen auto-continued the audio.
      expect(AudioController.instance.isPlayingFor('bible'), isTrue,
          reason: 'Next while playing must carry the audio into the next '
              'chapter');
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('a chapter ending naturally leaves the page; Next then '
        'starts the next chapter without pressing play (listening mode '
        'persists past the natural end)', (tester) async {
      BillingService.premium.value = true;
      await warmBibleCache(tester);
      const book = BibleBook(
        key: 'Genesis',
        name: 'Genesis',
        testament: 'OT',
        order: 1,
        chapters: 50,
      );
      await tester.runAsync(() => BibleService.chapter(book, 2));
      final engine = FakeAudioEngine();
      AudioController.instance.engineForTest = engine;
      await tester.pumpWidget(const MaterialApp(
        home: BibleChapterScreen(book: book, chapter: 1),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(AudioController.instance.isPlayingFor('bible'), isTrue);

      // Let the whole chapter play out chunk by chunk (natural end).
      for (var i = 0;
          i < 12 &&
              AudioController.instance.state != AudioState.stopped;
          i++) {
        engine.finishChunk();
        await tester.pump();
        await tester.pump();
      }
      expect(AudioController.instance.state, AudioState.stopped);
      expect(find.text('Genesis 1'), findsOneWidget,
          reason: 'the page never advances on its own');

      // Next after the natural end: the next chapter auto-plays — no play
      // press needed (the listening flag persisted).
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump();
      expect(find.text('Genesis 2'), findsOneWidget);
      expect(AudioController.instance.isPlayingFor('bible'), isTrue,
          reason: 'listening persists past the natural chapter end: Next '
              'starts the next chapter without pressing play');
    });

    testWidgets('explicit pause ends listening: Next navigates silently',
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
      await tester.runAsync(() => BibleService.chapter(book, 2));
      final engine = FakeAudioEngine();
      AudioController.instance.engineForTest = engine;
      await tester.pumpWidget(const MaterialApp(
        home: BibleChapterScreen(book: book, chapter: 1),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(AudioController.instance.isPlayingFor('bible'), isTrue);

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      await tester.pump();
      expect(AudioController.instance.state, AudioState.paused);
      final speaksBefore = engine.log.where((e) => e.startsWith('speak:')).length;

      // Next while paused: silent navigation — the next chapter must NOT
      // auto-play.
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump();
      expect(find.text('Genesis 2'), findsOneWidget);
      expect(AudioController.instance.state, AudioState.stopped,
          reason: 'Next after an explicit pause must navigate silently');
      expect(engine.log.where((e) => e.startsWith('speak:')).length,
          speaksBefore);
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
      // The next step's audio actually started (not just a state flip).
      expect(
        engine.log
            .where((e) => e.startsWith('asset:') || e.startsWith('speak:'))
            .length,
        greaterThanOrEqualTo(2),
        reason: "the next step's audio must start, not just the state flip",
      );
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

    testWidgets('a prayer ending naturally leaves the page in place; the '
        'next Next press plays the next prayer (no auto-advance)',
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
      expect(rosaryStep(tester), 0);

      // The step's audio runs out on its own (natural completion).
      engine.finishChunk();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // The page NEVER advances on its own (the governing rule).
      expect(rosaryStep(tester), 0,
          reason: 'a natural completion must leave the page exactly where it '
              'is — no hands-free flow');
      expect(AudioController.instance.state, AudioState.stopped);
      final playsAfterEnd = engine.log
          .where((e) => e.startsWith('asset:') || e.startsWith('speak:'))
          .length;
      expect(playsAfterEnd, 1,
          reason: 'no next-step audio may start on its own');

      // The user is still listening (never paused): Next auto-plays the
      // next prayer.
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(rosaryStep(tester), 1);
      expect(AudioController.instance.isPlayingFor('rosary'), isTrue,
          reason: 'listening persists past the natural end: Next plays the '
              'next prayer without pressing play');
      expect(
        engine.log
            .where((e) => e.startsWith('asset:') || e.startsWith('speak:'))
            .length,
        greaterThan(playsAfterEnd),
      );
    });

    testWidgets('Next while listening advances exactly ONE step — including '
        'right as a prayer ends (never a cascade, never a jump to the end)',
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
      expect(rosaryStep(tester), 0);

      // Next while playing: exactly one step.
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(rosaryStep(tester), 1,
          reason: 'one Next press = exactly one step advance');
      expect(AudioController.instance.isPlayingFor('rosary'), isTrue);

      // Next pressed right as the step's audio ends naturally: the
      // completion must not add its own advance — exactly one step.
      engine.finishChunk();
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(rosaryStep(tester), 2,
          reason: 'a Next press landing on a natural completion advances '
              'exactly one step, never a cascade');
      expect(AudioController.instance.isPlayingFor('rosary'), isTrue);

      // And again after the new step ends untouched.
      engine.finishChunk();
      await tester.pump();
      await tester.pump();
      expect(rosaryStep(tester), 2);
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(rosaryStep(tester), 3);
    });

    testWidgets('the page never advances on its own even when every step '
        'completes instantly (the v1.4.62 cascade repro)', (tester) async {
      await warmRosaryManifest(tester);
      final engine = InstantAssetEngine();
      AudioController.instance.engineForTest = engine;
      await tester.pumpWidget(const MaterialApp(
        home: RosaryPrayerScreen(mysteryType: 'joyful'),
      ));
      await tester.pumpAndSettle();

      // One play press: with the old natural-completion auto-advance, every
      // instantly-completing step chained the page to the ending prayers.
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(rosaryStep(tester), 0,
          reason: 'no auto-advance: a natural completion must never move the '
              'page, even when completions chain instantly');
      expect(AudioController.instance.state, AudioState.stopped);
    });

    testWidgets('explicit pause ends listening: Next navigates silently and '
        'stops the stale stream; play then starts the shown step',
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

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      await tester.pump();
      expect(AudioController.instance.state, AudioState.paused);

      // Next while paused: silent navigation, no autoplay.
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(rosaryStep(tester), 1);
      expect(AudioController.instance.state, AudioState.stopped,
          reason: "the abandoned step's paused stream is stopped on silent "
              'navigation so play always means the shown step');
      final playsAfterNav = engine.log
          .where((e) => e.startsWith('asset:') || e.startsWith('speak:'))
          .length;

      // Play on the new step starts THAT step's audio fresh.
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(AudioController.instance.isPlayingFor('rosary'), isTrue);
      expect(
        engine.log
            .where((e) => e.startsWith('asset:') || e.startsWith('speak:'))
            .length,
        greaterThan(playsAfterNav),
      );
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

  /// True when the verse numbered [number] currently carries the
  /// recited-verse style (an accent-colored w600 span inside its RichText).
  /// The verse number span is excluded (bold w700, fontSize 12), as is the
  /// recited-word span (w700 + tint).
  bool verseIsSpeaking(WidgetTester tester, int number) {
    final accents = [FidelisTheme.gold, FidelisTheme.deepRed];
    bool isAccent(Color? c) =>
        c != null &&
        accents.any((a) =>
            (c.r - a.r).abs() < 0.01 &&
            (c.g - a.g).abs() < 0.01 &&
            (c.b - a.b).abs() < 0.01);
    final richTexts = tester.widgetList<Widget>(find.byType(RichText));
    for (final w in richTexts) {
      final root = (w as RichText).text;
      if (root is TextSpan && root.toPlainText().startsWith('$number ')) {
        var speaking = false;
        root.visitChildren((span) {
          if (span is TextSpan &&
              span.text != null &&
              isAccent(span.style?.color) &&
              span.style?.fontWeight == FontWeight.w600) {
            speaking = true;
          }
          return true;
        });
        if (speaking) return true;
      }
    }
    return false;
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

    testWidgets('highlight advances past verse 1 across a long multi-chunk '
        'passage (defect: only the first verse ever highlighted)',
        (tester) async {
      BillingService.premium.value = true;
      await warmBibleCache(tester);
      // The flutter_tts-fallback signature: onSentenceStart fires once per
      // chunk, then word events sweep the whole chunk text. The verse
      // highlight must track the recited range across verse boundaries.
      final engine = SweepEngine();
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

      // Verse 1 starts highlighted (the chunk's first sentence).
      expect(verseIsSpeaking(tester, 1), isTrue);

      // Advance the recited word event-by-event until the highlight leaves
      // verse 1 (the defect's core assertion) — bounded so a regression
      // fails fast instead of hanging.
      var leftVerse1 = false;
      for (var i = 0; i < 400 && !leftVerse1; i++) {
        engine.tick();
        await tester.pump(const Duration(milliseconds: 50));
        leftVerse1 = !verseIsSpeaking(tester, 1);
      }
      expect(leftVerse1, isTrue,
          reason: 'the verse highlight must advance past verse 1 as the '
              'recited range crosses verse boundaries');
      expect(countWordTintSpans(tester), greaterThan(0),
          reason: 'the word-level highlight must be visible in the recited '
              'verse');

      // Keep advancing until the highlight reaches chunk 1 (verses 11-20):
      // it must cross the chunk boundary of the multi-chunk passage.
      var reachedChunk1 = false;
      for (var i = 0; i < 600 && !reachedChunk1; i++) {
        engine.tick();
        await tester.pump(const Duration(milliseconds: 50));
        for (var n = 11; n <= 20 && !reachedChunk1; n++) {
          reachedChunk1 = verseIsSpeaking(tester, n);
        }
      }
      expect(reachedChunk1, isTrue,
          reason: 'the verse highlight must keep advancing into the second '
              'chunk of the passage');
      // A few more words so the recited range is inside the verse and the
      // word-level tint is visible (the chunk's onSentenceStart fires
      // before its first word event).
      for (var i = 0; i < 3; i++) {
        engine.tick();
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(countWordTintSpans(tester), greaterThan(0));

      await AudioController.instance.stop();
      await tester.pump();
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

    testWidgets('asset highlight tracks per-sentence REAL timing — no '
        'accumulated drift (the last words stay in sync)', (tester) async {
      await warmRosaryManifest(tester);
      // Per-sentence durations INVERTED relative to character lengths: the
      // invocation is long text but short audio, 'Amen.' is short text but
      // long audio. A whole-text proportional estimate (the old model)
      // drifts badly; the per-sentence timeline must track the real audio
      // and reset at every sentence boundary.
      final engine = TimingFakeEngine(
        sentenceTimings: [],
        position: Duration.zero,
        duration: const Duration(seconds: 10),
      )..durationsToReport = [
          const Duration(seconds: 1),
          const Duration(seconds: 9),
        ];
      AudioController.instance.engineForTest = engine;
      await tester.pumpWidget(const MaterialApp(
        home: RosaryPrayerScreen(mysteryType: 'joyful'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      final text = RosaryPrayers.get('sign_of_the_cross', 'en');
      final ranges = TtsService.sentenceRanges(text);
      expect(ranges.length, 2);

      // 0.5s of the 10s asset: inside sentence 1's window ([0, 1s)).
      engine.position = const Duration(milliseconds: 500);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(speakingLineText(tester),
          text.substring(ranges[0].$1, ranges[0].$2),
          reason: 'the highlight tracks the per-sentence timeline, not a '
              'whole-text proportional estimate');

      // 5s: the old whole-text model would put the offset at 50% of the
      // text (still inside the long invocation); the per-sentence timeline
      // puts it inside 'Amen.' (sentence 2's window is [1s, 10s)).
      engine.position = const Duration(seconds: 5);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(speakingLineText(tester),
          text.substring(ranges[1].$1, ranges[1].$2),
          reason: 'sentence boundaries reset the mapping — drift cannot '
              'accumulate across the prayer');

      // The last words still highlight in sync at the very end.
      engine.position = const Duration(milliseconds: 9500);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(speakingLineText(tester),
          text.substring(ranges[1].$1, ranges[1].$2),
          reason: 'the last words highlight in sync — no accumulated lag');
    });
  });

  group('Bible language (defect: Spanish mode showed English verse text)', () {
    const book = BibleBook(
      key: 'Genesis',
      name: 'Genesis',
      testament: 'OT',
      order: 1,
      chapters: 50,
    );

    Future<void> pumpChapter(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: BibleChapterScreen(book: book, chapter: 1),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('Spanish mode displays the Spanish (Torres Amat) text',
        (tester) async {
      BillingService.premium.value = true;
      await warmBibleCache(tester, 'es');
      await pumpChapter(tester);

      // Genesis 1:1 in the Torres Amat translation.
      expect(
        find.textContaining('En el principio creó Dios el cielo y la tierra.'),
        findsOneWidget,
      );
      // The English Douay-Rheims text is gone.
      expect(
        find.textContaining('In the beginning God created heaven'),
        findsNothing,
      );
    });

    testWidgets('Spanish mode recites the displayed text with lang es',
        (tester) async {
      BillingService.premium.value = true;
      await warmBibleCache(tester, 'es');
      final engine = FakeAudioEngine();
      AudioController.instance.engineForTest = engine;
      await pumpChapter(tester);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(engine.langs, isNotEmpty);
      expect(engine.langs.every((l) => l == 'es'), isTrue,
          reason: 'the Spanish text must be recited through the existing '
              'Spanish voice path (lang es)');
      expect(
        engine.log.any((e) => e.startsWith(
            'speak:En el principio creó Dios el cielo y la tierra.')),
        isTrue,
        reason: 'the recited text must be the displayed Spanish text',
      );
    });

    testWidgets('Spanish mode highlights the recited verse in sync',
        (tester) async {
      BillingService.premium.value = true;
      await warmBibleCache(tester, 'es');
      // Kokoro-like engine: one sentence (chars 0..12 of the chunk text)
      // with a 10s duration; the live position sits mid-sentence.
      final engine = TimingFakeEngine(
        sentenceTimings: [(0, 12, const Duration(seconds: 10))],
        position: const Duration(seconds: 5),
        duration: const Duration(seconds: 10),
      );
      AudioController.instance.engineForTest = engine;
      await pumpChapter(tester);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      expect(countWordTintSpans(tester), greaterThan(0),
          reason: 'the sentence→verse mapping must run on the Spanish text');
    });

    testWidgets('English mode is unchanged: Douay-Rheims text, lang en',
        (tester) async {
      BillingService.premium.value = true;
      await warmBibleCache(tester, 'en');
      final engine = FakeAudioEngine();
      AudioController.instance.engineForTest = engine;
      await pumpChapter(tester);

      expect(
        find.textContaining('In the beginning God created heaven and earth.'),
        findsOneWidget,
      );
      expect(find.textContaining('En el principio'), findsNothing);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(engine.langs, isNotEmpty);
      expect(engine.langs.every((l) => l == 'en'), isTrue);
      expect(
        engine.log.any((e) =>
            e.startsWith('speak:In the beginning God created heaven and earth.')),
        isTrue,
      );
    });
  });
}