import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidelis/config/app_strings.dart';
import 'package:fidelis/features/bible/bible_chapter_screen.dart';
import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/billing_service.dart';
import 'package:fidelis/services/bible_service.dart';
import 'package:fidelis/services/tts_service.dart';
import 'package:fidelis/services/tts_text.dart';

import 'audio_controller_test.dart';

/// The owner's voice-grid Bible slot: EN am_michael (sid 16) SOLO at
/// speed 0.81 — the softening is the English slot's boom-softening
/// equalizer, nothing else; ES em_alex (sid 29, voice unchanged) solo.
/// Michael's round-2 pronunciation list is the Bible's standing per-voice
/// lexicon. The readings/rosary-timing voices keep the long-standing
/// standard configuration.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('KokoroVoice profiles', () {
    test('bible profile is the owner voice-grid configuration', () {
      const v = KokoroVoice.bible;
      expect(v.enSid, 16); // am_michael
      expect(v.esSid, 29); // em_alex
      expect(v.speed, 0.81);
      expect(v.enName, 'am_michael');
      expect(v.esName, 'em_alex');
      expect(v.sidFor('en'), 16);
      expect(v.sidFor('es'), 29);
      // EN speaks Michael SOLO — the softening is the equalizer, not a
      // blend; ES solo.
      // EQ: the gentle boom softening on the ENGLISH slot only.
      expect(v.enEqualizer, {0: -4.0, 1: -2.0});
      expect(v.esEqualizer, isNull);
      expect(v.equalizerFor('en'), {0: -4.0, 1: -2.0});
      expect(v.equalizerFor('es'), isNull);
    });

    test('standard profile is unchanged (readings + rosary timing)', () {
      const v = KokoroVoice.standard;
      expect(v.enSid, 26); // bm_george
      expect(v.esSid, 29); // em_alex
      expect(v.speed, 0.9);
      expect(v.enName, 'bm_george');
      expect(v.esName, 'em_alex');
    });

    test('lexicon is per-voice data: Michael verified, Alex clean', () {
      // The owner's addendum: ruleth + pasture corrections; the round-2
      // 'Salm' respelling is REMOVED ('psalm' phonemizes natively under
      // en-us with no audible L — the Bible-EN lexicon must not carry a
      // psalm entry).
      expect(kokoroVoiceLexicon['am_michael'],
          {'ruleth': 'Rouleth', 'pasture': 'Pastsher'});
      // Round 2 verified Alex's Spanish clean — no corrections.
      expect(kokoroVoiceLexicon['em_alex'], isEmpty);
      // Daniel no longer ships in any slot — his entry is gone.
      expect(kokoroVoiceLexicon.containsKey('bm_daniel'), isFalse);
      // Lookup through the profiles.
      expect(KokoroVoice.bible.lexiconFor('en'),
          {'ruleth': 'Rouleth', 'pasture': 'Pastsher'});
      expect(KokoroVoice.bible.lexiconFor('es'), isEmpty);
      expect(KokoroVoice.standard.lexiconFor('en'), isEmpty);
      expect(KokoroVoice.standard.lexiconFor('es'), isEmpty);
    });
  });

  group('applyPronunciationLexicon', () {
    const lex = {'ruleth': 'Rouleth'};

    test('replaces the verified word as specified', () {
      const text = 'The Lord ruleth me: and I shall want nothing.';
      final (spoken, _) = applyPronunciationLexicon(text, lex);
      expect(spoken, 'The Lord Rouleth me: and I shall want nothing.');
    });

    test('matches case-insensitively, whole words only', () {
      final (spoken, _) =
          applyPronunciationLexicon('Ruleth over them; rulethly, unruleth.', lex);
      // Sentence-initial capital still gets the specified respelling;
      // "rulethly" and "unruleth" are different words and stay untouched.
      expect(spoken, 'Rouleth over them; rulethly, unruleth.');
    });

    test('is idempotent (respellings never match their source words)', () {
      const text = 'The Lord ruleth me: and I shall want nothing.';
      final (spoken, _) = applyPronunciationLexicon(text, lex);
      final (again, _) = applyPronunciationLexicon(spoken, lex);
      expect(again, spoken);
    });

    test('empty lexicon returns the text unchanged', () {
      const text = 'El Señor es mi pastor, nada me falta.';
      final (spoken, align) = applyPronunciationLexicon(text, const {});
      expect(spoken, text);
      expect(align.length, text.length + 1);
      for (var i = 0; i < align.length; i++) {
        expect(align[i], i);
      }
    });

    test('alignment maps spoken sentence ranges back to the original text', () {
      const text =
          'The Lord ruleth me: and I shall want nothing. He restoreth my soul.';
      final (spoken, align) = applyPronunciationLexicon(text, lex);
      expect(spoken.contains('Rouleth'), isTrue);
      // The spoken text is one char longer (Rouleth vs ruleth).
      expect(spoken.length, text.length + 1);
      // Every sentence boundary of the SPOKEN text maps back to the exact
      // boundary of the ORIGINAL text — the highlight ranges the synthesis
      // path reports stay on the displayed words.
      final spokenRanges = speakableSentenceRanges(spoken);
      final originalRanges = speakableSentenceRanges(text);
      expect(spokenRanges.length, originalRanges.length);
      for (var i = 0; i < spokenRanges.length; i++) {
        expect(align[spokenRanges[i].$1], originalRanges[i].$1);
        expect(align[spokenRanges[i].$2], originalRanges[i].$2);
      }
      // Interior positions map monotonically and stay within bounds.
      for (var i = 1; i < align.length; i++) {
        expect(align[i], greaterThanOrEqualTo(align[i - 1]));
      }
    });

    test('handles adjacent replacements and punctuation adjacency', () {
      const lex = {'ab': 'X', 'cd': 'YY'};
      final (spoken, align) = applyPronunciationLexicon('ab,cd. ab', lex);
      expect(spoken, 'X,YY. X');
      expect(align.length, spoken.length + 1);
      // The final boundary maps to the original text's end.
      expect(align[spoken.length], 'ab,cd. ab'.length);
    });
  });

  group('computeWordSchedule', () {
    test('maps words proportionally within real sentence durations', () {
      const text = 'Hello world. Peace be.';
      // splitSentences: ["Hello world.", "Peace be."]; ranges (0,12),(13,22).
      final schedule = computeWordSchedule(text, const [
        Duration(milliseconds: 1000),
        Duration(milliseconds: 500),
      ]);
      expect(schedule.length, 4);
      // Sentence 1 spans 0-1000ms over chars 0-12.
      // "Hello" chars 0-5: 0ms → 5/12*1000 = 417ms.
      expect(schedule[0].charStart, 0);
      expect(schedule[0].charEnd, 5);
      expect(schedule[0].start.inMilliseconds, 0);
      expect(schedule[0].end.inMilliseconds, 417);
      // "world" chars 6-11: 6/12*1000 = 500ms → 11/12*1000 = 917ms.
      expect(schedule[1].charStart, 6);
      expect(schedule[1].charEnd, 11);
      expect(schedule[1].start.inMilliseconds, 500);
      expect(schedule[1].end.inMilliseconds, 917);
      // Sentence 2 starts at 1000ms over chars 13-22.
      // "Peace" chars 13-18: 1000ms → 1000 + 5/9*500 = 1278ms.
      expect(schedule[2].charStart, 13);
      expect(schedule[2].charEnd, 18);
      expect(schedule[2].start.inMilliseconds, 1000);
      expect(schedule[2].end.inMilliseconds, 1278);
      // "be" chars 19-21: 1000 + 6/9*500 = 1333ms → 1000 + 8/9*500 = 1444ms.
      expect(schedule[3].charStart, 19);
      expect(schedule[3].charEnd, 21);
      expect(schedule[3].start.inMilliseconds, 1333);
      expect(schedule[3].end.inMilliseconds, 1444);
    });

    test('returns [] on a split/duration count mismatch', () {
      expect(computeWordSchedule('One two.', const [Duration(milliseconds: 100),
        Duration(milliseconds: 100)]), isEmpty);
    });

    test('sentence windows are contiguous (no drift accumulation by design)',
        () {
      const text = 'First sentence here. Second one follows. Third is last.';
      final schedule = computeWordSchedule(text, const [
        Duration(milliseconds: 900),
        Duration(milliseconds: 700),
        Duration(milliseconds: 1100),
      ]);
      // The last WORD ends inside the last sentence's window (its charEnd
      // precedes the trailing period, so 13/14 of 1100ms remain: 2621ms) —
      // the sentence window itself spans the full 2700ms.
      expect(schedule.last.end.inMilliseconds, 2621);
      expect(schedule.last.end.inMilliseconds, lessThan(2700));
      // Every word sits inside its sentence's window.
      final s2 = schedule.firstWhere((w) => w.charStart >= 21);
      expect(s2.start.inMilliseconds,
          greaterThanOrEqualTo(900)); // sentence 2 starts at 900ms
      final s3 = schedule.last;
      expect(s3.start.inMilliseconds, greaterThanOrEqualTo(1600));
    });
  });

  group('Bible voice wiring', () {
    tearDown(() async {
      await AudioController.instance.stop();
      AudioController.instance.engineForTest = const TtsAudioEngine();
      BillingService.premium.value = false;
      await AppStrings.setLanguage('en');
    });

    testWidgets('chapter chunks request the Bible voice profile', (tester) async {
      BillingService.premium.value = true;
      const book = BibleBook(
        key: 'Genesis',
        name: 'Genesis',
        testament: 'OT',
        order: 1,
        chapters: 50,
      );
      // Load the Bible assets through real async (outside the test's
      // FakeAsync zone) so the screen's initState load finds warm caches.
      await tester.runAsync(() async {
        await AppStrings.setLanguage('en');
        await BibleService.books();
        await BibleService.chapter(book, 1);
      });
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

      // Every chunk the Bible screen starts carries the Bible profile —
      // Michael EN / Alex ES at 0.81 (the readings/rosary paths stay on
      // the standard profile by not passing a voice).
      expect(engine.voices, isNotEmpty);
      for (final voice in engine.voices) {
        expect(voice, same(KokoroVoice.bible));
      }
      expect(AudioController.instance.isPlayingFor('bible'), isTrue);
    });

    testWidgets('the chapter screen prefetches the opening chunk on open',
        (tester) async {
      BillingService.premium.value = true;
      const book = BibleBook(
        key: 'Genesis',
        name: 'Genesis',
        testament: 'OT',
        order: 1,
        chapters: 50,
      );
      await tester.runAsync(() async {
        await AppStrings.setLanguage('en');
        await BibleService.books();
        await BibleService.chapter(book, 1);
      });
      final engine = FakeAudioEngine();
      AudioController.instance.engineForTest = engine;
      await tester.pumpWidget(const MaterialApp(
        home: BibleChapterScreen(book: book, chapter: 1),
      ));
      await tester.pumpAndSettle();

      // THE SCREEN-OPEN PREFETCH: the opening chunk's synthesis started
      // before Play — the engine recorded the prefetch of the first ~10
      // verses with the Bible voice, and nothing is playing yet.
      final prefetched = engine.log
          .where((l) => l.startsWith('prefetch:'))
          .map((l) => l.substring('prefetch:'.length))
          .toList();
      expect(prefetched, isNotEmpty,
          reason: 'the chapter screen prefetches the opening chunk on open');
      final verses = await BibleService.chapter(book, 1);
      final expectedOpening = verses
          .take(10)
          .map((v) => v.text)
          .join(' ');
      expect(prefetched.first, expectedOpening,
          reason: 'the prefetched text is the opening chunk, composed the '
              'same way _startAudio composes its first chunk');
      expect(engine.prefetchLangs.first, 'en');
      expect(engine.prefetchVoices.first, same(KokoroVoice.bible));
      // Silent preparation: nothing is playing until the user presses Play.
      expect(AudioController.instance.state, AudioState.stopped);
    });

    test('TtsService sentence helpers delegate to the shared pipeline', () {
      const text = 'The Lord ruleth me. He restoreth my soul.';
      expect(TtsService.splitSentences(text),
          splitSpeakableSentences(text));
      expect(TtsService.sentenceRanges(text),
          speakableSentenceRanges(text));
    });
  });
}