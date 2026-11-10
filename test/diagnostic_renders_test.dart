import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/features/rosary/rosary_prayers.dart';
import 'package:fidelis/services/kokoro_engine.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// THE REFERENCE RENDERS: the six fixed passages rendered through the app's
/// OWN production synthesis function — [KokoroEngine.synthesize], the exact
/// code path a playback calls (no host-side replica) — and written as WAV
/// assets the diagnostic screen plays back (assets/diagnostics_renders/).
///
/// Two groups:
///  - WIRING (always runs): the six render files are bundled, pubspec
///    declares them, and the passage texts are the app's own sources (the
///    Bible JSON with the asterisk markup stripped exactly as
///    BibleService.chapter does, and RosaryPrayers verbatim).
///  - RENDER PASS (engine + env gated): re-renders the WAVs through the
///    production path. Run with the host's sherpa native lib on the loader
///    path AND FIDELIS_RENDER_DIAGNOSTICS=1:
///      LD_LIBRARY_PATH=~/.pub-cache/hosted/pub.dev/sherpa_onnx_linux-1.13.8/linux/x64 \
///        FIDELIS_RENDER_DIAGNOSTICS=1 flutter test test/diagnostic_renders_test.dart
///    Without the env the group skips cleanly — the unit suite stays green.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // The pre-warmed engine dir (the same one test/runtime_slot_readout_test
    // uses): the kokoro model files with a matching .ready marker, so the
    // 155 MB asset copy never runs inside the test session.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => '/tmp/fidelis_kokoro_readout');
    JustAudioPlatform.instance = _UnusedPlatform();
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'), null);
  });

  /// One reference render: the bundled WAV name, the language, the directed
  /// slot voice, and the passage text (resolved from the app's own sources).
  final renders = <({String file, String lang, KokoroVoice voice, Future<String> Function() text})>[
    (
      file: 'psalm23_en.wav',
      lang: 'en',
      voice: KokoroVoice.bible,
      text: () => biblePassage('en'),
    ),
    (
      file: 'psalm23_es.wav',
      lang: 'es',
      voice: KokoroVoice.bible,
      text: () => biblePassage('es'),
    ),
    (
      file: 'our_father_en.wav',
      lang: 'en',
      voice: KokoroVoice.rosary,
      text: () async => RosaryPrayers.ourFather['en']!,
    ),
    (
      file: 'our_father_es.wav',
      lang: 'es',
      voice: KokoroVoice.rosary,
      text: () async => RosaryPrayers.ourFather['es']!,
    ),
    (
      file: 'hail_mary_en.wav',
      lang: 'en',
      voice: KokoroVoice.rosary,
      text: () async => RosaryPrayers.hailMary['en']!,
    ),
    (
      file: 'hail_mary_es.wav',
      lang: 'es',
      voice: KokoroVoice.rosary,
      text: () async => RosaryPrayers.hailMary['es']!,
    ),
  ];

  group('reference render wiring', () {
    test('the six reference renders are bundled', () {
      for (final r in renders) {
        final f = File('assets/diagnostics_renders/${r.file}');
        expect(f.existsSync(), isTrue,
            reason: '${r.file} must ship in the APK — render it with '
                'FIDELIS_RENDER_DIAGNOSTICS=1 (see the file header)');
        expect(f.lengthSync(), greaterThan(10000),
            reason: '${r.file} holds real audio, not an empty stub');
      }
    });

    test('pubspec declares the render assets', () {
      expect(File('pubspec.yaml').readAsStringSync(),
          contains('assets/diagnostics_renders/'));
    });

    test('the EN Bible render text is the app\'s Psalm 23 (Douay ch. 22) '
        'verses 1-3, markup stripped', () async {
      final text = await biblePassage('en');
      // The shepherd psalm's opening (Douay-Rheims wording), with the
      // asterisk markup stripped exactly as BibleService.chapter does.
      expect(text, contains('The Lord ruleth me'));
      expect(text, contains('pasture'));
      expect(text, isNot(contains('*')));
      // Verses 1-3 only: the passage ends at "for his own name's sake."
      expect(text, contains("for his own name's sake."));
      expect(text, isNot(contains('shadow of death')));
    });

    test('the ES Bible render text is the app\'s Spanish Psalm 23 verses '
        '1-3', () async {
      final text = await biblePassage('es');
      expect(text, contains('El Señor es mi pastor'));
      expect(text, isNot(contains('*')));
    });

    test('the rosary render texts are the app\'s own prayers verbatim',
        () async {
      expect(await renders[2].text(), RosaryPrayers.ourFather['en']!);
      expect(await renders[3].text(), RosaryPrayers.ourFather['es']!);
      expect(await renders[4].text(), RosaryPrayers.hailMary['en']!);
      expect(await renders[5].text(), RosaryPrayers.hailMary['es']!);
      // The EN Hail Mary carries 'blessed' — the rosary slot's bless-ed
      // correction applies to it in the production synthesis input.
      expect(await renders[4].text(), contains('blessed art thou'));
    });

    test('the render slots are the directed grid', () {
      // The Bible renders go through the Bible slot (Michael+Echo EN blend
      // / Alex ES at 0.81); the rosary renders through the rosary slot
      // (Aoede EN / Aoede+Dora ES blend at 0.9).
      expect(renders[0].voice.enSid, 16);
      expect(renders[0].voice.enBlendSid, 12);
      expect(renders[1].voice.esSid, 29);
      expect(renders[1].voice.esBlendSid, isNull);
      expect(renders[2].voice.enSid, 1);
      expect(renders[3].voice.esSid, 1);
      expect(renders[3].voice.esBlendSid, 28);
      expect(renders[4].voice.enSid, 1);
      expect(renders[5].voice.esBlendSid, 28);
    });
  });

  group('reference render pass', () {
    final doRender =
        Platform.environment['FIDELIS_RENDER_DIAGNOSTICS'] == '1';

    test('renders the six passages through the production path', () async {
      if (!doRender) {
        markTestSkipped('set FIDELIS_RENDER_DIAGNOSTICS=1 (with '
            'LD_LIBRARY_PATH) to re-render the bundled WAVs');
        return;
      }
      if (!await KokoroEngine.ensureReady('en') ||
          !await KokoroEngine.ensureReady('es')) {
        markTestSkipped('the host sherpa native lib is not on the loader '
            'path — run with LD_LIBRARY_PATH (see the file header)');
        return;
      }
      final outDir = Directory('assets/diagnostics_renders');
      if (!outDir.existsSync()) outDir.createSync(recursive: true);
      for (final r in renders) {
        final text = await r.text();
        final audio = await KokoroEngine.synthesize(text, r.lang, voice: r.voice);
        expect(audio, isNotNull, reason: '${r.file}: the production '
            'synthesis must deliver (KokoroEngine.lastError='
            '${KokoroEngine.lastError})');
        expect(audio!.samples, isNotEmpty);
        // The blend proof: the directed blends EXECUTE in the render.
        final expectBlend = r.voice.blendSidFor(r.lang) != null;
        expect(audio.blended, expectBlend,
            reason: '${r.file}: blend execution record must match the '
                'directed slot');
        final wav = encodeWav16(
            resamplePcmTo48k(audio.samples, audio.sampleRate),
            audio.sampleRate == 24000 ? 48000 : audio.sampleRate);
        File('assets/diagnostics_renders/${r.file}').writeAsBytesSync(wav);
        // ignore: avoid_print
        print('RENDER ${r.file}: ${audio.samples.length} samples at '
            '${audio.sampleRate} Hz, blended=${audio.blended} '
            '(primary=${audio.primarySamples}, '
            'partner=${audio.partnerSamples}), ${wav.length} bytes');
      }
    }, timeout: const Timeout(Duration(minutes: 10)));
  });
}

/// The Bible passage text exactly as the app composes it: Psalms chapter 22
/// (the Douay-Rheims numbering of the shepherd psalm — modern Psalm 23),
/// verses 1-3, asterisk markup stripped (BibleService.chapter's
/// transformation), verses joined by a single space (the chapter screen's
/// chunk composition).
Future<String> biblePassage(String lang) async {
  final raw = await rootBundle
      .loadString(lang == 'es' ? 'assets/bible/sp_bible.json' : 'assets/bible/dr_bible.json');
  final bible = jsonDecode(raw) as Map<String, dynamic>;
  final psalms = bible['Psalms'] as Map<String, dynamic>;
  final chapter = psalms['22'] as Map<String, dynamic>;
  final verses = <(int, String)>[];
  for (final entry in chapter.entries) {
    final number = int.tryParse(entry.key);
    if (number == null || number < 1 || number > 3) continue;
    verses.add((number, (entry.value as String).replaceAll('*', '')));
  }
  verses.sort((a, b) => a.$1.compareTo(b.$1));
  return verses.map((v) => v.$2).join(' ');
}

/// Placeholder platform: the render pass never touches the player (pure
/// synthesis), but TtsService's static player constructs on first class
/// touch — a stub keeps the construction off the real channel.
class _UnusedPlatform extends JustAudioPlatform
    with MockPlatformInterfaceMixin {}
