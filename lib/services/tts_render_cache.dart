import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';

/// THE PERSISTENT RENDER CACHE (round 4, defect A): completed sentence
/// audio, cached on disk keyed by content + voice config, so a chapter or
/// rosary heard once is INSTANT FOREVER — the next open finds every
/// sentence's prepared playback WAV already on disk and plays from
/// completed audio with zero synthesis.
///
/// Layout: one flat entry per sentence under the app-support directory's
/// `render_cache/`:
///   - `s_<key>.wav`  — the EXACT prepared playback WAV the playlist
///     plays (gain-staged, resampled to 48 kHz mono 16-bit — the
///     proven-clean output path on the owner's phone), and
///   - `s_<key>.json` — the entry's record: the spoken text (verified on
///     every hit), the language, the voice identity, the audio duration
///     (the timing data the highlight schedule derives from — the
///     schedule comes from the same synthesis that produced the cached
///     audio), the gain-staging evidence (peaks, clip counts, staging
///     flag), the byte size, and the LRU access stamp.
///
/// The key is the FNV-1a 64-bit hash of
/// `pipelineVersion|lang|voiceIdentity|spokenText`: the spoken text is
/// post-lexicon (a lexicon change re-keys the affected sentences), the
/// voice identity is the stable sid/name/speed triple (never an identity
/// hash, which does not survive a restart), and [pipelineVersion] is
/// bumped whenever the render pipeline itself changes (gain staging,
/// resampler) so stale-format audio is never served.
///
/// FORMAT DECISION (WAV vs compressed): WAV — the prepared 48 kHz mono
/// 16-bit WAV is the exact bytes the playlist plays, so a cache hit is
/// pure I/O (no decode, no re-encode, no per-play CPU) and the write path
/// needs no encoder. Compressed (OGG/Opus) would quarter the size but
/// requires an on-device encoder (a new native dependency plus encode CPU
/// on a phone already saturated by synthesis) and a decode per play. The
/// size cost (~96 KB/s of audio) is bounded by the LRU cap.
///
/// EVICTION: LRU with a size cap ([capBytes], 512 MB ≈ 90 minutes of
/// audio). Every hit re-stamps the entry's access time; the sweep evicts
/// the LEAST recently accessed entries first and never touches entries
/// accessed within the last 10 minutes (an active listening session's
/// sentences are all freshly stamped, so the sweep cannot evict audio the
/// playlist is about to play). Orphan files (a crashed store's half
/// entry) are swept after an hour.
///
/// LIFECYCLE: the cache is INERT until [init] resolves its directory —
/// production wires it at startup (main.dart); without init every lookup
/// and store is a no-op and the pipeline behaves exactly as before. Audio
/// NEVER depends on the cache: every failure degrades to the historical
/// temp-file path (prepare, play, delete).
class TtsRenderCache {
  TtsRenderCache._();

  /// Bump when the render pipeline changes (gain staging, resampler, WAV
  /// format) so cached audio from an older pipeline is never served.
  static const int pipelineVersion = 1;

  /// The LRU size cap: 512 MB ≈ 90 minutes of 48 kHz mono 16-bit audio —
  /// roughly the last week of daily listening; older content evicts
  /// first.
  static const int defaultCapBytes = 512 * 1024 * 1024;

  /// The active-session guard: entries accessed within this window are
  /// never evicted (the playlist may be about to play them).
  static const int _activeMs = 10 * 60 * 1000;

  /// Orphan files (a crashed store's half entry) are swept after this age.
  static const int _orphanMs = 60 * 60 * 1000;

  static Directory? _dir;
  static bool _failed = false;
  static DateTime? _lastSweepCheck;

  /// The effective size cap (tests shrink it to drive eviction).
  @visibleForTesting
  static int capBytes = defaultCapBytes;

  /// True when [init] (or the test hook) resolved the cache directory —
  /// lookups and stores are live. False: the cache is inert and the
  /// pipeline behaves exactly as before the cache existed.
  static bool get isReady => !_failed && _dir != null;

  /// Resolves the cache directory (the app-support directory's
  /// `render_cache/`). Called once at startup (main.dart). Any failure
  /// leaves the cache inert for the session — audio never depends on it.
  static Future<void> init() async {
    if (_dir != null || _failed) return;
    try {
      final support = await getApplicationSupportDirectory();
      final dir = Directory('${support.path}/render_cache');
      await dir.create(recursive: true);
      _dir = dir;
    } catch (_) {
      _failed = true;
    }
  }

  /// Test hook: points the cache at an explicit directory (a fresh temp
  /// dir per test) — the ONLY way the cache activates in tests, so the
  /// existing suites' isolation is untouched.
  @visibleForTesting
  static Future<void> debugInit(String path) async {
    _failed = false;
    final dir = Directory(path);
    await dir.create(recursive: true);
    _dir = dir;
  }

  /// Test hook: fully resets the cache (deletes the directory, clears the
  /// statics) — test isolation between cache suites.
  @visibleForTesting
  static Future<void> debugReset() async {
    final dir = _dir;
    _dir = null;
    _failed = false;
    _lastSweepCheck = null;
    capBytes = defaultCapBytes;
    if (dir != null) {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    }
  }

  /// The stable cache key for one sentence render: the pipeline version,
  /// the language, the voice identity (name(sid)@speed — stable across
  /// restarts), and the SPOKEN text (post-lexicon — a lexicon change
  /// re-keys the affected sentences).
  static String keyFor({
    required String lang,
    required String voiceId,
    required String text,
  }) {
    var hash = 0xcbf29ce484222325;
    final material = '$pipelineVersion|$lang|$voiceId|$text';
    for (var i = 0; i < material.length; i++) {
      hash ^= material.codeUnitAt(i);
      hash *= 0x100000001b3; // Dart ints wrap mod 2^64 — exact FNV-1a
    }
    return (hash & 0x7fffffffffffffff).toRadixString(16);
  }

  /// Looks up one entry and re-stamps its LRU access time. The recorded
  /// spoken text must match [expectText] exactly (hash-collision and
  /// stale-entry protection). Returns null on any miss or failure — the
  /// caller synthesizes instead. Synchronous: one small JSON read plus
  /// the touch rewrite per hit.
  static TtsCacheHit? lookupSync(String key, {required String expectText}) {
    if (!isReady) return null;
    try {
      final jsonFile = File('${_dir!.path}/s_$key.json');
      if (!jsonFile.existsSync()) return null;
      final decoded = jsonDecode(jsonFile.readAsStringSync());
      if (decoded is! Map || decoded['t'] != expectText) return null;
      final ms = (decoded['ms'] as num?)?.toInt() ?? 0;
      if (ms <= 0) return null;
      final wavFile = File('${_dir!.path}/s_$key.wav');
      if (!wavFile.existsSync()) return null;
      // LRU touch: re-stamp the access time (a tiny rewrite per hit —
      // the playing content's entries stay fresh, so the sweep can never
      // evict audio the playlist is about to play).
      try {
        decoded['a'] = DateTime.now().millisecondsSinceEpoch;
        jsonFile.writeAsStringSync(jsonEncode(decoded), flush: false);
      } catch (_) {}
      return TtsCacheHit(
        file: wavFile,
        duration: Duration(milliseconds: ms),
        peakInDb: (decoded['pin'] as String?) ?? '-inf',
        peakOutDb: (decoded['pout'] as String?) ?? '-inf',
        clipIn: (decoded['cin'] as num?)?.toInt() ?? 0,
        clipOut: (decoded['cout'] as num?)?.toInt() ?? 0,
        scaled: decoded['scaled'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  /// Stores one completed sentence render: the prepared WAV (the exact
  /// bytes the playlist plays) plus its record. Both files are written
  /// atomically (temp + rename), the JSON last — an entry exists only
  /// when complete. Returns the final WAV path for playback, or null when
  /// the store failed (the caller falls back to the temp-file path).
  /// Fire-and-forget eviction follows every store.
  static Future<File?> store({
    required String key,
    required String text,
    required String lang,
    required String voiceId,
    required int durationMs,
    required Uint8List wav,
    required String peakInDb,
    required String peakOutDb,
    required int clipIn,
    required int clipOut,
    required bool scaled,
  }) async {
    if (!isReady) return null;
    try {
      final wavFile = File('${_dir!.path}/s_$key.wav');
      final wavTmp = File('${wavFile.path}.tmp');
      await wavTmp.writeAsBytes(wav, flush: true);
      await wavTmp.rename(wavFile.path);
      final record = jsonEncode({
        'pv': pipelineVersion,
        't': text,
        'lang': lang,
        'v': voiceId,
        'ms': durationMs,
        'a': DateTime.now().millisecondsSinceEpoch,
        'size': wav.length,
        'pin': peakInDb,
        'pout': peakOutDb,
        'cin': clipIn,
        'cout': clipOut,
        'scaled': scaled,
      });
      final jsonFile = File('${_dir!.path}/s_$key.json');
      final jsonTmp = File('${jsonFile.path}.tmp');
      await jsonTmp.writeAsString(record, flush: true);
      await jsonTmp.rename(jsonFile.path);
      unawaited(_sweepIfNeeded());
      return wavFile;
    } catch (_) {
      return null;
    }
  }

  /// Throttled eviction check: at most one sweep per 30 s (the sweep
  /// stats the directory; a per-store sweep would stat on every sentence).
  static Future<void> _sweepIfNeeded() async {
    final now = DateTime.now();
    final last = _lastSweepCheck;
    if (last != null && now.difference(last) < const Duration(seconds: 30)) {
      return;
    }
    _lastSweepCheck = now;
    await sweep();
  }

  /// LRU eviction: when the cache exceeds [capBytes], evict the LEAST
  /// recently accessed entries (whole entries: wav + json) until under the
  /// cap, never touching entries accessed within the last 10 minutes (the
  /// active session's audio). Also sweeps orphan files (a crashed store's
  /// half entry, stale .tmp files) older than an hour. Never throws.
  static Future<void> sweep() async {
    if (!isReady) return;
    try {
      final dir = _dir!;
      final now = DateTime.now().millisecondsSinceEpoch;
      final entries = <_CacheEntry>[];
      final orphans = <File>[];
      final jsonsByKey = <String, (File, Map<Object?, Object?>)>{};
      final wavsByKey = <String, File>{};
      for (final entity in dir.listSync()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (name.endsWith('.tmp')) {
          orphans.add(entity);
          continue;
        }
        if (name.endsWith('.json')) {
          final key = name.substring(2, name.length - '.json'.length);
          try {
            final decoded = jsonDecode(entity.readAsStringSync());
            if (decoded is Map) jsonsByKey[key] = (entity, decoded);
          } catch (_) {
            orphans.add(entity); // corrupt record: sweepable
          }
        } else if (name.endsWith('.wav')) {
          wavsByKey[name.substring(2, name.length - '.wav'.length)] = entity;
        }
      }
      for (final entry in jsonsByKey.entries) {
        final wav = wavsByKey.remove(entry.key);
        if (wav == null) {
          orphans.add(entry.value.$1); // record without audio: broken
          continue;
        }
        final ms = (entry.value.$2['ms'] as num?)?.toInt() ?? 0;
        if (ms <= 0) {
          orphans.add(entry.value.$1);
          orphans.add(wav);
          continue;
        }
        entries.add(_CacheEntry(
          key: entry.key,
          jsonFile: entry.value.$1,
          wavFile: wav,
          size: wav.lengthSync(),
          accessed: (entry.value.$2['a'] as num?)?.toInt() ?? 0,
        ));
      }
      orphans.addAll(wavsByKey.values); // audio without record: broken
      var total = entries.fold<int>(0, (a, e) => a + e.size);
      if (total > capBytes) {
        entries.sort((a, b) => a.accessed.compareTo(b.accessed));
        for (final entry in entries) {
          if (total <= capBytes) break;
          if (now - entry.accessed < _activeMs) continue; // active session
          try {
            entry.wavFile.deleteSync();
          } catch (_) {}
          try {
            entry.jsonFile.deleteSync();
          } catch (_) {}
          total -= entry.size;
        }
      }
      // Orphans: a crashed store's half entry or a stale temp file —
      // sweepable after an hour (a just-written half entry may still be
      // mid-store).
      for (final orphan in orphans) {
        try {
          if (now - orphan.lastModifiedSync().millisecondsSinceEpoch >
              _orphanMs) {
            orphan.deleteSync();
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// The cache's on-device state (the diagnostics readout): ready, the
  /// entry count, the total bytes, and the cap.
  static Future<Map<String, Object?>> stats() async {
    if (!isReady) return {'ready': false};
    var count = 0;
    var bytes = 0;
    try {
      for (final entity in _dir!.listSync()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (name.endsWith('.json') && !name.endsWith('.json.tmp')) count++;
        if (!name.endsWith('.tmp')) bytes += entity.lengthSync();
      }
    } catch (_) {}
    return {
      'ready': true,
      'entries': count,
      'bytes': bytes,
      'cap': capBytes,
      'dir': _dir!.path,
    };
  }
}

/// One cache entry during the sweep: its key, both files, its byte size,
/// and its last access stamp.
class _CacheEntry {
  final String key;
  final File jsonFile;
  final File wavFile;
  final int size;
  final int accessed;

  const _CacheEntry({
    required this.key,
    required this.jsonFile,
    required this.wavFile,
    required this.size,
    required this.accessed,
  });
}

/// One cache hit: the prepared playback WAV (the exact bytes the playlist
/// plays), the audio duration (the timing data the highlight schedule
/// derives from), and the gain-staging evidence recorded at store time.
class TtsCacheHit {
  final File file;
  final Duration duration;
  final String peakInDb;
  final String peakOutDb;
  final int clipIn;
  final int clipOut;
  final bool scaled;

  const TtsCacheHit({
    required this.file,
    required this.duration,
    required this.peakInDb,
    required this.peakOutDb,
    required this.clipIn,
    required this.clipOut,
    required this.scaled,
  });
}
