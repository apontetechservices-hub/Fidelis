import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/app_strings.dart';
import '../../config/theme.dart';
import '../../services/audio_controller.dart';
import '../../services/bible_service.dart';
import '../../services/billing_service.dart';
import '../../services/kokoro_engine.dart';
import '../../services/render_ahead.dart';
import '../../services/tts_service.dart';
import '../diagnostics/playback_readout.dart';
import '../premium/paywall_screen.dart';

/// Arguments for the named '/bible/chapter' route.
class BibleChapterArgs {
  final BibleBook book;
  final int chapter;
  const BibleChapterArgs({required this.book, required this.chapter});
}

/// One chapter of the Douay-Rheims: scrollable verses, prev/next chapter
/// navigation, a book/chapter picker, and read-aloud audio in ~10-verse
/// chunks so playback starts quickly.
///
/// All audio routes through the central [AudioController] (one stream
/// app-wide): a centered play/pause toggle below the navigation bar, verse
/// highlighting synced to the recited sentences, and auto-continue —
/// navigating to another chapter while playing carries the audio over.
class BibleChapterScreen extends StatefulWidget {
  final BibleBook book;
  final int chapter;

  /// Start playing automatically once the chapter loads (auto-continue:
  /// the previous screen was playing when the user navigated here).
  final bool autoPlay;

  const BibleChapterScreen({
    super.key,
    required this.book,
    required this.chapter,
    this.autoPlay = false,
  });

  @override
  State<BibleChapterScreen> createState() => _BibleChapterScreenState();
}

class _BibleChapterScreenState extends State<BibleChapterScreen> {
  static const _jobId = 'bible';

  /// Verses per TTS chunk — keeps the first spoken sentence fast.
  static const _versesPerChunk = 10;

  List<BibleVerse>? _verses;

  /// Language of the loaded [_verses] ('en' | 'es') — lets a language
  /// switch while the chapter is open trigger a reload.
  String? _loadedLang;
  int? _speakingVerse;

  /// Listening mode (the governing rule): ON when the user starts playback;
  /// stays ON across a natural chapter end — the user is still listening;
  /// cleared ONLY by an explicit pause or leaving the screen (dispose).
  /// While ON, chapter navigation auto-plays the new chapter, including the
  /// Next press after a chapter finished on its own. Seeded from
  /// [widget.autoPlay]: auto-continue into this screen means the previous
  /// screen was listening.
  bool _listening = false;

  /// Character range of the word being recited within [_speakingVerse]'s
  /// text (word-level highlight; null when no word estimate is available).
  (int, int)? _speakingWord;

  /// Per chunk: verse start offsets within the chunk's joined text, and the
  /// chunk's absolute first verse index — used to map the controller's
  /// chunk-text word range back to a verse + range within it.
  final Map<int, List<int>> _chunkVerseStarts = {};
  final Map<int, int> _chunkFirstVerse = {};

  /// Per chunk: the sentence count of the chunk's joined text — the
  /// notification's verse-level Next/Previous maps the controller's
  /// chunk/sentence position to a global stream sentence index through
  /// these counts.
  final Map<int, int> _chunkSentenceCounts = {};

  /// Per verse (global index): the stream sentence index that starts it —
  /// the notification's verse-level Next/Previous seeks the live pipeline
  /// to this sentence. Built with the job (see [_buildJob]); null before.
  List<int>? _verseFirstStreamSentence;

  /// The first verse of the currently loaded job (a unit-move restart
  /// starts mid-chapter; the verse maps are keyed to that job's layout).
  int _jobFromVerse = 0;

  final Map<int, GlobalKey> _verseKeys = {};

  @override
  void initState() {
    super.initState();
    _listening = widget.autoPlay;
    AudioController.instance.listenable.addListener(_onAudioChanged);
    AudioController.instance.wordRangeListenable.addListener(_onWordRangeChanged);
    AppStrings.localeNotifier.addListener(_onLocaleChanged);
    _load();
  }

  @override
  void dispose() {
    AudioController.instance.listenable.removeListener(_onAudioChanged);
    AudioController.instance.wordRangeListenable
        .removeListener(_onWordRangeChanged);
    AppStrings.localeNotifier.removeListener(_onLocaleChanged);
    // Audio is tied to this screen — never keep playing after exit. Owner-
    // scoped so a replacement chapter screen that already auto-continued is
    // not cut off. Deferred out of the unmount phase: stop() notifies
    // listeners, and a synchronous notification while the widget tree is
    // locked (unmount) would throw markNeedsBuild on a locked tree.
    scheduleMicrotask(() => AudioController.instance.stopIfOwner(this));
    super.dispose();
  }

  /// Clears the verse highlight when this screen's audio stops or is
  /// replaced by another screen's stream.
  void _onAudioChanged() {
    final info = AudioController.instance.listenable.value;
    final gone = info.state == AudioState.stopped || info.jobId != _jobId;
    if (gone && (_speakingVerse != null || _speakingWord != null) && mounted) {
      setState(() {
        _speakingVerse = null;
        _speakingWord = null;
      });
    }
  }

  /// Maps the controller's word-level range (character offsets within the
  /// active chunk's text) to the recited verse + range within it, so the
  /// spoken word highlights in sync with the voice. The verse itself is
  /// derived from the word range — the Rosary's mechanic: when the recited
  /// range crosses into another verse, the verse highlight advances with it.
  /// (onSentenceStart alone cannot drive this on the flutter_tts path, which
  /// fires it only once per chunk, so the verse would freeze at the first
  /// verse for the whole passage.)
  void _onWordRangeChanged() {
    if (!mounted) return;
    final info = AudioController.instance.listenable.value;
    final range = AudioController.instance.wordRangeListenable.value;
    (int, int)? word;
    if (range != null &&
        info.jobId == _jobId &&
        info.state != AudioState.stopped &&
        _verses != null) {
      final starts = _chunkVerseStarts[info.chunkIndex];
      final first = _chunkFirstVerse[info.chunkIndex];
      if (starts != null && first != null) {
        var relative = 0;
        for (var k = 0; k < starts.length; k++) {
          if (starts[k] <= range.charStart) relative = k;
        }
        final verse = first + relative;
        if (verse != _speakingVerse) {
          setState(() => _speakingVerse = verse);
          _scrollToVerse(verse);
        }
        final verseStart = starts[relative];
        final verseLength = _verses![verse].text.length;
        final s = (range.charStart - verseStart).clamp(0, verseLength);
        final e = (range.charEnd - verseStart).clamp(0, verseLength);
        if (e > s) word = (s, e);
      }
    }
    if (word != _speakingWord) {
      setState(() => _speakingWord = word);
    }
  }

  Future<void> _load() async {
    final lang = BibleService.textLang;
    final verses = await BibleService.chapter(widget.book, widget.chapter);
    await BibleService.savePosition(widget.book, widget.chapter);
    if (mounted) {
      setState(() {
        _verses = verses;
        _loadedLang = lang;
      });
      // Screen-open prefetch (playback latency): the opening chunk's
      // synthesis STARTS the moment the chapter's text is on screen —
      // engine warm-up plus the first sentences rendered into the
      // prefetch cache — so pressing Play finds the opening audio READY
      // and starts instantly. Fire-and-forget; never blocks the load.
      _prefetchOpeningChunk();
      // THE RENDER-AHEAD (round 4): the WHOLE chapter renders to
      // completion in the background — begun the moment the chapter is
      // on screen — into the persistent render cache, so Play and the
      // verse-level Next/Previous start from completed audio (no
      // synthesis wait). Fire-and-forget; never blocks the load.
      _beginRenderAhead();
      if (widget.autoPlay) unawaited(_startAudio());
    }
  }

  /// The opening chunk's text (the first ~10 verses joined), composed the
  /// same way [_startAudio] composes its first chunk — the screen-open
  /// prefetch renders exactly the audio Play will ask for first.
  String _openingChunkText(List<BibleVerse> verses) {
    final end = _versesPerChunk < verses.length
        ? _versesPerChunk
        : verses.length;
    return verses.sublist(0, end).map((v) => v.text).join(' ');
  }

  /// Screen-open prefetch: renders the opening chunk's sentences into the
  /// engine's prefetch cache (en/es only) with the Bible slot's voice —
  /// the same (lang, voice) identity a Play press synthesizes through, so
  /// the cache serves it. No-op before the verses arrive.
  void _prefetchOpeningChunk() {
    final verses = _verses;
    if (verses == null || verses.isEmpty) return;
    final lang = AppStrings.isSpanish ? 'es' : 'en';
    AudioController.instance.prefetch(AudioChunk(
      text: _openingChunkText(verses),
      lang: lang,
      voice: KokoroVoice.bible,
    ));
  }

  /// THE RENDER-AHEAD (round 4): the WHOLE chapter renders to completion
  /// in the background — on screen-open (fromVerse 0) and on every Play
  /// (from the played verse, so the urgent sentences render first) — into
  /// the persistent render cache, so Play and the verse-level
  /// Next/Previous start from completed audio (no synthesis wait). The
  /// chunks compose through [_verseGroups] — the same grouping the
  /// playback job builds from, so the render-ahead renders exactly the
  /// audio Play asks for. Fire-and-forget; never blocks the caller.
  void _beginRenderAhead({int fromVerse = 0}) {
    final verses = _verses;
    if (verses == null || verses.isEmpty) return;
    final lang = AppStrings.isSpanish ? 'es' : 'en';
    final chunks = <AudioChunk>[
      for (final (_, group) in _verseGroups(fromVerse: fromVerse))
        AudioChunk(
          text: group.map((v) => v.text).join(' '),
          lang: lang,
          voice: KokoroVoice.bible,
        ),
    ];
    if (chunks.isEmpty) return;
    // The from-verse's first stream sentence index: the walk starts at
    // the played position (the urgent sentences first); everything before
    // it is usually already cached (heard) or covered by the screen-open
    // walk.
    var fromSentence = 0;
    for (final (start, group) in _verseGroups()) {
      if (start >= fromVerse) break;
      fromSentence +=
          TtsService.splitSentences(group.map((v) => v.text).join(' '))
              .length;
    }
    RenderAhead.begin(
      chunks: chunks,
      lang: lang,
      fromSentence: fromSentence,
      label: 'bible ${BibleService.bookName(widget.book)} ${widget.chapter}',
    );
  }

  /// Language switch while this chapter is open (the toggle lives in
  /// settings, above this screen in the nav stack): stop this screen's
  /// audio — it recited the other language's text — and reload the verses
  /// in the new language. Positions are book/chapter, so the reading spot
  /// carries over untouched.
  void _onLocaleChanged() {
    if (!mounted ||
        _loadedLang == null ||
        _loadedLang == BibleService.textLang) {
      return;
    }
    AudioController.instance.stopIfOwner(this);
    setState(() {
      _speakingVerse = null;
      _speakingWord = null;
      _verses = null;
    });
    _load();
  }

  /// Neighbouring chapter, walking across book boundaries in canon order.
  /// The boundary walk itself lives in [BibleService] (canonical book list,
  /// index-based neighbour lookup) so the owner's boundary check can test
  /// every book-to-book transition directly.
  Future<(BibleBook, int)?> _neighbour(int direction) async {
    if (direction < 0) {
      return BibleService.previousChapter(widget.book, widget.chapter);
    }
    return BibleService.nextChapter(widget.book, widget.chapter);
  }

  /// Chapter navigation while LISTENING auto-continues with the new chapter
  /// (the new screen starts its own stream; the single-stream controller
  /// replaces the old one). The listening flag persists past a natural
  /// chapter end, so Next after a chapter finished on its own also plays —
  /// only an explicit pause ends the mode. Paused or never started:
  /// navigate silently.
  Future<void> _goTo(BibleBook book, int chapter) async {
    if (book.key == widget.book.key && chapter == widget.chapter) return;
    // NEXT ADVANCES IN BOTH ENGINE STATES (round 5, defect 1d): the
    // auto-continue decision reads the LIVE playback state — a stream
    // resumed from the notification plays without this screen's play
    // button having set the flag, and the stale-false flag opened the
    // next chapter SILENTLY (the playback stopped with the old screen —
    // the owner's 'Next stopped playback'). Playing now always
    // auto-continues; the paused semantics are unchanged.
    final controller = AudioController.instance;
    final listening = _listening ||
        (controller.currentJobId == _jobId &&
            controller.state == AudioState.playing);
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BibleChapterScreen(
          book: book,
          chapter: chapter,
          autoPlay: listening,
        ),
      ),
    );
  }

  /// Book/chapter picker: first the books, then a chapter grid.
  Future<void> _openPicker() async {
    final picked = await showModalBottomSheet<(BibleBook, int)>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BiblePickerSheet(
        currentBookKey: widget.book.key,
        currentChapter: widget.chapter,
      ),
    );
    if (picked != null) await _goTo(picked.$1, picked.$2);
  }

  Future<void> _toggleAudio() async {
    final controller = AudioController.instance;
    if (controller.isPlayingFor(_jobId)) {
      _listening = false; // explicit pause: listening mode ends
      await controller.pause();
    } else if (controller.state == AudioState.paused &&
        controller.currentJobId == _jobId) {
      _listening = true; // resuming is starting playback again
      await controller.resume();
    } else {
      await _startAudio();
    }
  }

  /// Plays the chapter from [fromVerse] onward as ~10-verse chunks (the
  /// sequence pipeline speaks them as ONE continuous stream — the
  /// chunking only shapes the highlight mapping). Each chunk reports its
  /// sentences as they start being recited; sentences are mapped back to
  /// verse indices so the spoken verse highlights in sync. Word-level
  /// advancement within the verse comes from the controller's word-range
  /// stream: engine-timed sentence boundaries (Kokoro) or word events
  /// (flutter_tts), with the position inside the sentence estimated
  /// character-proportionally (sherpa_onnx 1.13.8 exposes no token
  /// timestamps). Lang follows the displayed text: 'es' recites the
  /// Spanish (Torres Amat) text through the existing Spanish voice path,
  /// 'en' the Douay-Rheims as before. Voice: the owner's voice-grid Bible
  /// slot ([KokoroVoice.bible] — EN am_michael / ES em_alex at 0.81, with
  /// the per-voice pronunciation lexicon applied in the synthesis path and
  /// the English slot's equalizer shaping applied at playback).
  Future<void> _startAudio({int fromVerse = 0}) async {
    final verses = _verses;
    if (verses == null || verses.isEmpty) return;
    _listening = true; // starting playback: listening mode ON
    // THE RENDER-AHEAD re-targets BEFORE the start (round 5, defect C —
    // the frontier stalls): a jump must supersede the old walk
    // IMMEDIATELY — the old walk's renders (nearer content) would
    // otherwise keep the worker busy ahead of the target sentence's own
    // renders (the frontier stall). The new walk starts at the played
    // verse and YIELDS to the playback pipeline's own renders (the
    // live-render demand), so the target sentence wins the worker.
    _beginRenderAhead(fromVerse: fromVerse);
    await AudioController.instance.start(
      _buildJob(fromVerse: fromVerse),
      owner: this,
    );
  }

  /// The chapter's verse groups — the ~10-verse TTS chunks — as
  /// (firstVerseIndex, verses) pairs. The ONE grouping the playback job
  /// and the render-ahead both compose from: the same chunk texts, so the
  /// render-ahead renders exactly the audio Play asks for.
  List<(int, List<BibleVerse>)> _verseGroups({int fromVerse = 0}) {
    final verses = _verses!;
    final groups = <(int, List<BibleVerse>)>[];
    for (var start = fromVerse;
        start < verses.length;
        start += _versesPerChunk) {
      final end = (start + _versesPerChunk < verses.length)
          ? start + _versesPerChunk
          : verses.length;
      groups.add((start, verses.sublist(start, end)));
    }
    return groups;
  }

  /// Builds the chapter's playback job from [fromVerse] onward: the
  /// ~10-verse chunks with their highlight closures, the per-chunk
  /// sentence counts and each verse's first stream-sentence index (the
  /// notification's verse-level Next/Previous maps a verse to the stream
  /// sentence that starts it), and the verse-level unit move.
  AudioJob _buildJob({int fromVerse = 0}) {
    final verses = _verses!;
    final lang = AppStrings.isSpanish ? 'es' : 'en';
    final chunks = <AudioChunk>[];
    final firsts = List<int>.filled(verses.length, -1);
    _chunkVerseStarts.clear();
    _chunkFirstVerse.clear();
    _chunkSentenceCounts.clear();
    var streamIndex = 0;
    for (final (start, group) in _verseGroups(fromVerse: fromVerse)) {
      final text = group.map((v) => v.text).join(' ');
      final verseForSentence = _sentenceVerseIndices(group, start, text);
      final chunkIndex = chunks.length;
      _chunkVerseStarts[chunkIndex] = _verseOffsets(group);
      _chunkFirstVerse[chunkIndex] = start;
      final sentenceCount = TtsService.splitSentences(text).length;
      _chunkSentenceCounts[chunkIndex] = sentenceCount;
      for (var si = 0;
          si < verseForSentence.length && si < sentenceCount;
          si++) {
        final v = verseForSentence[si];
        if (v >= 0 && v < firsts.length && firsts[v] < 0) {
          firsts[v] = streamIndex + si;
        }
      }
      streamIndex += sentenceCount;
      chunks.add(AudioChunk(
        text: text,
        lang: lang,
        voice: KokoroVoice.bible,
        onSentenceStart: (sentence) {
          if (!mounted) return;
          final verse = sentence < verseForSentence.length
              ? verseForSentence[sentence]
              : verseForSentence.last;
          if (verse != _speakingVerse) {
            setState(() => _speakingVerse = verse);
            _scrollToVerse(verse);
          }
        },
      ));
    }
    // A verse with no sentence starting in it (a continuation) belongs to
    // the previous verse's sentence span.
    for (var v = 1; v < firsts.length; v++) {
      if (firsts[v] < 0) firsts[v] = firsts[v - 1];
    }
    _verseFirstStreamSentence = firsts;
    _jobFromVerse = fromVerse;
    return AudioJob(
      id: _jobId,
      chunks: chunks,
      // The media notification's title: the chapter being recited.
      title: '${BibleService.bookName(widget.book)} ${widget.chapter}',
      onUnitMove: _moveVerse,
    );
  }

  /// The media notification's verse-level Next/Previous (the job's unit
  /// move): returns the stream sentence index that starts the target
  /// verse when the controller can seek the live pipeline to it (playing
  /// continues into the verse, paused moves the position); null when the
  /// move is blocked (a chapter-edge boundary) or handled here — beyond
  /// the synthesized frontier or the loaded job's range, the position
  /// moves by restarting from the target verse while playing, or by
  /// arming a paused resume (the next Play starts that verse; nothing
  /// sounds until then).
  Future<int?> _moveVerse(int direction) async {
    final verses = _verses;
    final firsts = _verseFirstStreamSentence;
    if (verses == null || firsts == null || firsts.length != verses.length) {
      return null;
    }
    final controller = AudioController.instance;
    final info = controller.listenable.value;
    if (info.jobId != _jobId) return null;
    final counts = _chunkSentenceCounts;
    var global = 0;
    for (var c = 0; c < info.chunkIndex && c < counts.length; c++) {
      global += counts[c] ?? 0;
    }
    global += info.sentenceIndex;
    var current = _jobFromVerse;
    for (var v = _jobFromVerse; v < firsts.length; v++) {
      if (firsts[v] >= 0 && firsts[v] <= global) current = v;
    }
    final target = current + direction;
    if (target < 0 || target >= verses.length) return null;
    final targetSentence = target < firsts.length ? firsts[target] : -1;
    if (target >= _jobFromVerse &&
        targetSentence >= 0 &&
        targetSentence < controller.loadedSentenceCount) {
      return targetSentence; // the controller seeks the live pipeline
    }
    if (info.state == AudioState.playing) {
      unawaited(_startAudio(fromVerse: target));
    } else {
      setState(() => _speakingVerse = target);
      _scrollToVerse(target);
      controller.armResume(_buildJob(fromVerse: target), owner: this);
    }
    return null;
  }

  /// Verse start offsets within a chunk's joined text (verses joined by a
  /// single space), used to map chunk-text character ranges to verses.
  List<int> _verseOffsets(List<BibleVerse> group) {
    final starts = <int>[];
    var offset = 0;
    for (final v in group) {
      starts.add(offset);
      offset += v.text.length + 1; // +1 for the joining space
    }
    return starts;
  }

  /// Maps each speakable sentence of [text] (same split the TTS engine
  /// uses) to the index of the verse it starts in. Sentences are substrings
  /// of the joined chunk text, so offsets align with verse boundaries.
  List<int> _sentenceVerseIndices(
    List<BibleVerse> group,
    int firstVerse,
    String text,
  ) {
    final verseStarts = _verseOffsets(group);
    final indices = <int>[];
    var cursor = 0;
    for (final sentence in TtsService.splitSentences(text)) {
      var at = text.indexOf(sentence, cursor);
      if (at < 0) at = cursor;
      var verse = 0;
      for (var k = 0; k < verseStarts.length; k++) {
        if (verseStarts[k] <= at) verse = k;
      }
      indices.add(firstVerse + verse);
      cursor = at + sentence.length;
    }
    if (indices.isEmpty) indices.add(firstVerse);
    return indices;
  }

  void _scrollToVerse(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _verseKeys[index]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        alignment: 0.25,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Route-level premium guard: direct navigation to this screen
    // (named route, deep link, any push) still requires Premium.
    return ValueListenableBuilder<bool>(
      valueListenable: BillingService.premium,
      builder: (context, isPremium, _) {
        if (!isPremium) return const PaywallScreen();
        return _buildReader(context);
      },
    );
  }

  Widget _buildReader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? FidelisTheme.gold : FidelisTheme.deepRed;

    return Scaffold(
      appBar: AppBar(
        title: Text('${BibleService.bookName(widget.book)} ${widget.chapter}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: AppStrings.t('bible'),
            onPressed: _openPicker,
          ),
        ],
      ),
      body: _verses == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: _verses!.length,
              itemBuilder: (context, index) => _buildVerse(context, index, accent),
            ),
      bottomNavigationBar: _navigationBar(theme, accent),
    );
  }

  Widget _buildVerse(BuildContext context, int index, Color accent) {
    final verse = _verses![index];
    final theme = Theme.of(context);
    final speaking = index == _speakingVerse;
    final word = speaking ? _speakingWord : null;
    final hasWord = word != null &&
        word.$2 > word.$1 &&
        word.$2 <= verse.text.length &&
        word.$1 >= 0;

    // Recited verse: accent text on a faint accent wash; the word currently
    // being recited gets a stronger wash so advancement is unmistakable.
    final baseStyle = theme.textTheme.bodyLarge?.copyWith(
      height: 1.5,
      color: speaking ? accent : null,
      fontWeight: speaking ? FontWeight.w600 : null,
      background: speaking ? (Paint()..color = accent.withValues(alpha: 0.10)) : null,
    );

    return Padding(
      key: _verseKeys.putIfAbsent(index, GlobalKey.new),
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${verse.number} ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (hasWord) ...[
              TextSpan(
                text: verse.text.substring(0, word.$1),
                style: baseStyle,
              ),
              TextSpan(
                text: verse.text.substring(word.$1, word.$2),
                style: baseStyle?.copyWith(
                  background: Paint()
                    ..color = accent.withValues(alpha: 0.35),
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: verse.text.substring(word.$2),
                style: baseStyle,
              ),
            ] else
              TextSpan(text: verse.text, style: baseStyle),
          ],
        ),
      ),
    );
  }

  Widget _navigationBar(ThemeData theme, Color accent) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // THE SILENT-FALLBACK KILLER (round 5, defect 1c): the
            // system-voice banner — independent of the diagnostics
            // toggle: a substituted voice playing with no sign is worse
            // than a visible failure.
            const PlaybackFallbackBanner(),
            // The playback readout lives behind Settings → About → Audio
            // diagnostics; the off-by-default toggle puts it back on this
            // screen for on-screen debugging during playback.
            ValueListenableBuilder<bool>(
              valueListenable: PlaybackReadoutVisibility.onPrayerScreens,
              builder: (context, show, _) => show
                  ? const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: PlaybackReadout(),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 4),
            // Centered play/pause toggle for the chapter's read-aloud audio.
            ValueListenableBuilder<AudioPlaybackInfo>(
              valueListenable: AudioController.instance.listenable,
              builder: (context, info, _) {
                final mine = info.jobId == _jobId;
                final playing = mine && info.state == AudioState.playing;
                return IconButton.filled(
                  tooltip: playing
                      ? AppStrings.t('pause_audio')
                      : AppStrings.t('play_audio'),
                  onPressed: _toggleAudio,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  style: IconButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FutureBuilder<(BibleBook, int)?>(
                    future: _neighbour(-1),
                    builder: (context, snap) {
                      final prev = snap.data;
                      return OutlinedButton.icon(
                        onPressed: prev == null ? null : () => _goTo(prev.$1, prev.$2),
                        icon: const Icon(Icons.chevron_left),
                        label: Text(AppStrings.t('previous')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  tooltip: AppStrings.t('bible'),
                  onPressed: _openPicker,
                  icon: const Icon(Icons.menu_book),
                  style: IconButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<(BibleBook, int)?>(
                    future: _neighbour(1),
                    builder: (context, snap) {
                      final next = snap.data;
                      return OutlinedButton.icon(
                        onPressed: next == null ? null : () => _goTo(next.$1, next.$2),
                        icon: const Icon(Icons.chevron_right),
                        label: Text(AppStrings.t('next')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet picker: stage 1 lists the books (OT/NT), stage 2 the
/// chapters of the chosen book. Pops with (book, chapter).
class _BiblePickerSheet extends StatefulWidget {
  final String? currentBookKey;
  final int? currentChapter;

  const _BiblePickerSheet({this.currentBookKey, this.currentChapter});

  @override
  State<_BiblePickerSheet> createState() => _BiblePickerSheetState();
}

class _BiblePickerSheetState extends State<_BiblePickerSheet> {
  List<BibleBook>? _books;
  BibleBook? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final books = await BibleService.books();
    if (mounted) setState(() => _books = books);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? FidelisTheme.gold : FidelisTheme.deepRed;
    final selected = _selected;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  if (selected != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _selected = null),
                    ),
                  Expanded(
                    child: Text(
                      selected == null
                          ? AppStrings.t('bible')
                          : BibleService.bookName(selected),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _books == null
                  ? const Center(child: CircularProgressIndicator())
                  : selected == null
                      ? _buildBooks(theme, isDark, accent)
                      : _buildChapters(theme, accent, selected),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooks(ThemeData theme, bool isDark, Color accent) {
    final books = _books!;
    final ot = books.where((b) => b.testament == 'OT').toList();
    final nt = books.where((b) => b.testament == 'NT').toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _pickerSection(theme, isDark, AppStrings.t('old_testament')),
        for (final book in ot)
          ListTile(
            dense: true,
            title: Text(BibleService.bookName(book)),
            trailing: Text(
              AppStrings.t('chapters_count')
                  .replaceAll('{{n}}', '${book.chaptersInTextLang}'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            onTap: () => setState(() => _selected = book),
          ),
        _pickerSection(theme, isDark, AppStrings.t('new_testament')),
        for (final book in nt)
          ListTile(
            dense: true,
            title: Text(BibleService.bookName(book)),
            trailing: Text(
              AppStrings.t('chapters_count')
                  .replaceAll('{{n}}', '${book.chaptersInTextLang}'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            onTap: () => setState(() => _selected = book),
          ),
      ],
    );
  }

  Widget _pickerSection(ThemeData theme, bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChapters(ThemeData theme, Color accent, BibleBook book) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: book.chaptersInTextLang,
      itemBuilder: (context, index) {
        final chapter = index + 1;
        final isCurrent = book.key == widget.currentBookKey &&
            chapter == widget.currentChapter;
        return OutlinedButton(
          onPressed: () => Navigator.pop(context, (book, chapter)),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: BorderSide(
              color: isCurrent ? accent : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            backgroundColor: isCurrent ? accent.withValues(alpha: 0.15) : null,
          ),
          child: Text(
            '$chapter',
            style: TextStyle(
              color: isCurrent ? accent : null,
              fontWeight: isCurrent ? FontWeight.bold : null,
            ),
          ),
        );
      },
    );
  }
}