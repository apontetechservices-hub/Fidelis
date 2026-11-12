import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'audio_controller.dart' show AudioChunk;
import 'tts_service.dart';

/// THE RENDER-AHEAD SERVICE (round 4, defect A): the WHOLE chapter or
/// rosary renders to completion in the BACKGROUND — begun on screen-open
/// and on every Play — into the persistent render cache, and playback
/// plays from COMPLETED audio. The structural direction this implements:
/// STOP CHASING REALTIME. Live synthesis runs at roughly realtime (zero
/// slack), so playback outran production and every boundary was a wait —
/// Next worst of all, because it jumped past everything already
/// synthesized. Rendering the whole content ahead — and caching it
/// persistently — decouples playback from synthesis: a Play press, a
/// verse boundary, and a Next/Previous all resolve from completed audio
/// (cache hits are pure I/O), and live synthesis only serves the
/// UNCACHED frontier of brand-new content.
///
/// The walk resolves every sentence through [TtsService.obtainSentence] —
/// the ONE shared path the playback lookahead uses — so the render-ahead
/// and a playing stream never duplicate a render and never starve each
/// other's worker requests: the walk issues ONE render at a time
/// (sequential), yields to the playback's lookahead, and skips cached
/// sentences instantly. A cache hit costs nothing; a miss renders and
/// STORES, so the next play — this session or any later one — starts
/// from completed audio.
///
/// Latest-wins: a new [begin] supersedes the running walk (the user
/// moved — the new content's sentences are the urgent ones; the old
/// walk's in-flight render completes harmlessly and its already-cached
/// sentences skip instantly on any later pass). The walk is
/// fire-and-forget: it never blocks the caller, never plays anything,
/// and never throws.
class RenderAhead {
  RenderAhead._();

  /// Bumped by every [begin] and [cancel]; the running walk exits at its
  /// next checkpoint when its generation is stale.
  static int _generation = 0;

  /// The running walk's future (the test hook awaits it).
  static Future<void>? _walk;

  /// Whether a walk is currently running (the walk's own finally clears
  /// it — a superseded walk leaves it to its successor).
  static bool _running = false;

  /// Whether a walk is currently running.
  static bool get isRunning => _running;

  /// The current walk's label (the diagnostics readout).
  static String? _label;

  /// The current walk's label (null when idle).
  static String? get currentLabel => _label;

  /// Begins rendering [chunks]' whole sentence stream to completion in
  /// the background, walking from [fromSentence] (the played position's
  /// first sentence — the urgent sentences render first). en/es only:
  /// Latin keeps the flutter_tts path, which needs no render cache.
  /// Fire-and-forget; supersedes any running walk.
  static void begin({
    required List<AudioChunk> chunks,
    required String lang,
    int fromSentence = 0,
    String? label,
  }) {
    if (lang != 'en' && lang != 'es') return;
    if (chunks.isEmpty) return;
    final gen = ++_generation;
    _label = label;
    _running = true;
    _walk = _walkStream(chunks, lang, fromSentence, gen, label);
    // Wake any walk parked on the render-demand gap: the superseded walk
    // re-checks its generation and exits promptly instead of waiting for
    // the next drain.
    TtsService.notifyRenderGap();
  }

  /// Stops the running walk (a screen exit that wants the background
  /// rendering to stop; a [begin] supersedes without needing this).
  static void cancel() {
    _generation++;
    _label = null;
  }

  /// Test hook: awaits the current walk (the fire-and-forget future).
  @visibleForTesting
  static Future<void> debugWaitIdle() async {
    final walk = _walk;
    if (walk != null) await walk;
  }

  static Future<void> _walkStream(List<AudioChunk> chunks, String lang,
      int from, int gen, String? label) async {
    try {
      final stream = TtsService.buildStream(chunks, lang);
      if (stream.isEmpty || from >= stream.length) return;
      TtsService.measureLine('render-ahead begin label=${label ?? '-'} '
          'sentences=${stream.length} from=$from');
      var rendered = 0;
      var cached = 0;
      var yieldedMs = 0;
      final sw = Stopwatch()..start();
      for (var i = from; i < stream.length; i++) {
        if (gen != _generation) {
          TtsService.measureLine('render-ahead superseded at=$i '
              'rendered=$rendered cached=$cached');
          return;
        }
        // THE YIELD (round 5, the Bible/rosary latency asymmetry and the
        // frontier stalls): the worker is FIFO — a walk render issued
        // while the playback pipeline has synthesis in flight would queue
        // ahead of the pipeline's FUTURE lookahead requests and halve the
        // playback's synthesis throughput. The rosary's step pipeline
        // covers only the CURRENT step, so the whole-rosary walk's theft
        // starved the step's own frontier; the Bible's pipeline covers
        // the whole chapter, so its walk only ever deduped onto the
        // pipeline's own renders — the measured asymmetry. Wait for a
        // gap: the pipeline's renders land first, the walk fills the idle
        // capacity; cache-hit stretches leave the gap open instantly.
        // The wait is COMPLETER-BASED (no timers): the walk parks until a
        // render lands and the demand drains — a timer-based poll would
        // keep a timer pending at every instant (the widget tests'
        // pending-timer invariant, and pointless production wakeups).
        final waitStart = DateTime.now();
        while (gen == _generation && TtsService.liveEngineRenders > 0) {
          await TtsService.waitForRenderGap();
        }
        yieldedMs += DateTime.now().difference(waitStart).inMilliseconds;
        if (gen != _generation) {
          TtsService.measureLine('render-ahead superseded at=$i '
              'rendered=$rendered cached=$cached');
          return;
        }
        final prepared =
            await TtsService.obtainSentence(stream[i], chunks, lang);
        if (gen != _generation) return;
        if (prepared == null) {
          // The engine failed (sticky): the walk aborts — playback's own
          // path falls back to flutter_tts; the next begin retries.
          TtsService.measureLine('render-ahead abort at=$i '
              'rendered=$rendered cached=$cached reason=synthesis-failed');
          return;
        }
        if (prepared.source == 'cache') {
          cached++;
        } else {
          rendered++;
        }
      }
      TtsService.measureLine('render-ahead done rendered=$rendered '
          'cached=$cached ms=${sw.elapsedMilliseconds} '
          'yieldedMs=$yieldedMs');
    } catch (_) {
      // Never throws into the caller: the render-ahead is background
      // preparation, not playback.
    } finally {
      if (gen == _generation) _running = false;
    }
  }
}
