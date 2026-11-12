import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../config/app_strings.dart';
import '../../config/constants.dart';
import 'rosary_controller.dart';
import 'rosary_prayers.dart';
import 'mystery_data.dart';
import '../../services/audio_controller.dart';
import '../../services/kokoro_engine.dart';
import '../../services/render_ahead.dart';
import '../../services/tts_service.dart';
import '../diagnostics/playback_readout.dart';
import 'litany_of_loreto.dart';
import 'rosary_state.dart';

class RosaryPrayerScreen extends StatefulWidget {
  final String mysteryType;
  final bool includeLuminous;
  final bool isForDead;
  final String language;
  final String? deceasedName;
  final String deceasedPronoun; // them, him, her
  final int startStep;

  const RosaryPrayerScreen({
    super.key,
    required this.mysteryType,
    this.includeLuminous = false,
    this.isForDead = false,
    this.language = 'en',
    this.deceasedName,
    this.deceasedPronoun = 'them',
    this.startStep = 0,
  });

  @override
  State<RosaryPrayerScreen> createState() => _RosaryPrayerScreenState();
}

class _RosaryPrayerScreenState extends State<RosaryPrayerScreen> {
  static const _jobId = 'rosary';

  late List<RosaryStep> _steps;
  int _currentStep = 0;
  bool _showLitany = false;
  int _litanyIndex = 0;
  late String _language;

  /// True while this screen's step audio is loaded in the central
  /// controller (playing or paused) — drives the recited-text highlight.
  bool _audioLoadedForMe = false;

  /// Line-level + word-level highlight of the recited prayer text: the line
  /// index within the displayed text and the word's absolute character
  /// range. Null when nothing is recited or the step's content is not a
  /// single recited text (litany keeps its manual advance; mystery
  /// announcements keep the step-level border).
  int? _speakingLine;
  (int, int)? _speakingWord;

  /// Listening mode (the governing rule): ON when the user starts playback;
  /// stays ON across a natural step completion — the user is still
  /// listening; cleared ONLY by an explicit pause or leaving the screen
  /// (dispose). While ON, Next/Previous auto-play the new step's audio;
  /// while OFF (paused or never started), navigation is silent.
  bool _listening = false;

  static const List<String> _laOrdinals = ['Primum', 'Secundum', 'Tertium', 'Quartum', 'Quintum'];

  String _ordinalFor(int n) {
    if (_language == 'es') return n == 1 ? '1er' : '$nº';
    if (_language == 'la') return _laOrdinals[(n - 1).clamp(0, 4)];
    const suf = ['st', 'nd', 'rd', 'th', 'th'];
    return '$n${suf[(n - 1).clamp(0, 4)]}';
  }

  String _stepLabel(RosaryStep step) {
    String F(String key) => AppStrings.tFor(key, _language);
    final dec = step.mysteryIndex == null ? null : step.mysteryIndex! + 1;
    switch (step.type) {
      case RosaryStepType.signOfTheCross:
        return F('lbl_sign_of_cross');
      case RosaryStepType.creed:
        return F('lbl_creed');
      case RosaryStepType.ourFather:
        return dec == null ? F('lbl_our_father') : F('lbl_our_father_decade').replaceAll('{{n}}', '$dec');
      case RosaryStepType.hailMary:
        final n = step.hailMaryCount ?? 1;
        final m = dec == null ? 3 : 10;
        final base = F('lbl_hail_mary').replaceAll('{{n}}', '$n').replaceAll('{{m}}', '$m');
        return dec == null ? base : '$base — ${F('lbl_decade').replaceAll('{{n}}', '$dec')}';
      case RosaryStepType.gloryBe:
        return dec == null ? F('lbl_glory_be') : F('lbl_glory_be_decade').replaceAll('{{n}}', '$dec');
      case RosaryStepType.fatimaPrayer:
        return F('lbl_fatima').replaceAll('{{n}}', '$dec');
      case RosaryStepType.hailHolyQueen:
        return F('lbl_hail_holy_queen');
      case RosaryStepType.litany:
        return F('lbl_litany_bvm');
      case RosaryStepType.concludingPrayer:
        return F('lbl_concluding');
      case RosaryStepType.deProfundis:
        return F('lbl_de_profundis');
      case RosaryStepType.eternalRest:
        return F('lbl_eternal_rest').replaceAll('{{n}}', '$dec');
      case RosaryStepType.deadRosaryClosing:
        return F('lbl_dead_closing');
      case RosaryStepType.mysteryAnnouncement:
      case RosaryStepType.mysteryMeditation:
        try {
          return MysteryData.getMysteries(widget.mysteryType)[_step.mysteryIndex!].title(_language);
        } catch (_) {
          return step.label;
        }
    }
  }
  final ScrollController _scrollController = ScrollController();

  // GlobalKey per litany line for precise scroll positioning
  static const int _maxLitanyLines = 70;
  final List<GlobalKey> _litanyKeys = List.generate(_maxLitanyLines, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    AudioController.instance.listenable.addListener(_onAudioChanged);
    AudioController.instance.wordRangeListenable.addListener(_onHighlightChanged);
    _language = widget.language;
    final mysteryTypes = List.filled(5, widget.mysteryType);
    _steps = RosaryController.buildRosarySteps(
      mysteryTypes: mysteryTypes,
      includeLuminous: widget.includeLuminous,
      isForDead: widget.isForDead,
    );
    // If starting from a saved position, set step and litany state
    if (widget.startStep > 0) {
      _currentStep = widget.startStep;
      _showLitany = _steps[_currentStep].type == RosaryStepType.litany;
    }
    // Save state on first load
    _saveState();
    // Screen-open prefetch (playback latency): the CURRENT step's
    // synthesis starts the moment the prayer screen opens — engine
    // warm-up plus the first sentences rendered into the prefetch cache —
    // so pressing Play finds the opening audio READY and starts
    // instantly. Fire-and-forget; never blocks the open.
    _prefetchCurrentStep();
    // THE RENDER-AHEAD (round 4): the WHOLE rosary renders to completion
    // in the background — begun the moment the prayer screen opens — into
    // the persistent render cache, so Play and every Next/Previous start
    // from completed audio (no synthesis wait). Fire-and-forget; never
    // blocks the open.
    _beginRenderAhead();
  }

  @override
  void dispose() {
    AudioController.instance.listenable.removeListener(_onAudioChanged);
    AudioController.instance.wordRangeListenable
        .removeListener(_onHighlightChanged);
    // Step audio is tied to this screen — never keep playing after exit.
    // Deferred out of the unmount phase: stop() notifies listeners, and a
    // synchronous notification while the widget tree is locked (unmount)
    // would throw markNeedsBuild on a locked tree.
    scheduleMicrotask(() => AudioController.instance.stopIfOwner(this));
    _scrollController.dispose();
    _saveState();
    super.dispose();
  }

  /// Tracks whether the currently loaded audio stream belongs to this
  /// screen, so the recited text can be highlighted while it plays.
  void _onAudioChanged() {
    final info = AudioController.instance.listenable.value;
    final loaded = info.jobId == _jobId && info.state != AudioState.stopped;
    if (loaded != _audioLoadedForMe && mounted) {
      setState(() => _audioLoadedForMe = loaded);
    }
    // Stopped (or replaced by another screen's stream): clear the recited
    // line/word. Paused keeps them frozen so the user sees where they are.
    if (!loaded && (_speakingLine != null || _speakingWord != null) && mounted) {
      setState(() {
        _speakingLine = null;
        _speakingWord = null;
      });
    }
  }

  /// Recomputes the recited line + word from the controller's word-range
  /// stream — the single timing source for BOTH audio kinds: runtime TTS
  /// chunks (per-sentence Kokoro timing) and pre-rendered assets (the
  /// controller's per-sentence timeline built from real synthesized
  /// durations, or its coarse fallback). The screen never estimates from
  /// raw position/total itself, so no model drift can accumulate here.
  void _onHighlightChanged() {
    if (!mounted) return;
    final info = AudioController.instance.listenable.value;
    if (info.jobId != _jobId || info.state != AudioState.playing) return;
    final text = _currentPrayerText();
    if (text.isEmpty) return; // litany/announcement: their own highlight UX
    final ranges = TtsService.sentenceRanges(text);

    int? line;
    (int, int)? word;
    final range = AudioController.instance.wordRangeListenable.value;
    if (range != null) {
      line = _lineContaining(ranges, range.charStart);
      if (line != null) {
        final (start, end) = ranges[line];
        final s = range.charStart.clamp(start, end);
        final e = range.charEnd.clamp(start, end);
        if (e > s) word = (s, e);
      }
    }
    if (line != _speakingLine || word != _speakingWord) {
      setState(() {
        _speakingLine = line;
        _speakingWord = word;
      });
    }
  }

  /// Index of the line (speakable sentence) containing [offset], clamped to
  /// the last line for offsets in trailing whitespace.
  int? _lineContaining(List<(int, int)> ranges, int offset) {
    for (var i = 0; i < ranges.length; i++) {
      if (offset >= ranges[i].$1 && offset < ranges[i].$2) return i;
    }
    return ranges.isEmpty ? null : ranges.length - 1;
  }

  double get _progress => (_currentStep + 1) / _steps.length;

  RosaryStep get _step => _steps[_currentStep];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isForDead ? AppStrings.t('rosary_for_the_dead') : AppStrings.t('title_holy_rosary')),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _confirmExit(context),
          ),
          // Language set on Rosary selection screen, persisted in SharedPreferences
        ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: isDark ? const Color(0xFF243447) : FidelisTheme.ivory,
            valueColor: const AlwaysStoppedAnimation<Color>(FidelisTheme.gold),
            minHeight: 3,
          ),

          // The playback readout lives behind Settings → About → Audio
          // diagnostics; the off-by-default toggle puts it back on this
          // screen for on-screen debugging during playback.
          ValueListenableBuilder<bool>(
            valueListenable: PlaybackReadoutVisibility.onPrayerScreens,
            builder: (context, show, _) => show
                ? const PlaybackReadout()
                : const SizedBox.shrink(),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step label
                  Text(
                    _stepLabel(_step),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: FidelisTheme.gold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Mystery content (title, image, verse, meditation, fruit)
                  if (_step.type == RosaryStepType.mysteryAnnouncement)
                    _buildMysteryContent(context),

                  // Prayer text
                  if (!_showLitany)
                    _buildPrayerText(context),

                  // Litany display
                  if (_showLitany)
                    _buildLitanyContent(context),

                  // Bead progress for Hail Mary decades
                  if (_step.type == RosaryStepType.hailMary)
                    _buildBeadProgress(context),
                ],
              ),
            ),
          ),

          // Navigation buttons
          _buildNavigation(context),
        ],
      ),
    ),
    );
  }

  Widget _buildMysteryContent(BuildContext context) {
    if (_step.mysteryIndex == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    final mysteries = MysteryData.getMysteries(widget.mysteryType);
    if (_step.mysteryIndex! >= mysteries.length) return const SizedBox.shrink();
    final mystery = mysteries[_step.mysteryIndex!];
    final hasImage = mystery.imageAsset.isNotEmpty;
    final hasVerse = mystery.verseRef.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      decoration: BoxDecoration(
        color: FidelisTheme.deepRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: _recitedBorder() ??
            Border.all(color: FidelisTheme.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Mystery image
          if (hasImage) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                mystery.imageAsset,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
              ),
            ),
          ],
          // Bible verse
          if (hasVerse) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    mystery.verseRefFor(_language),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDarkMode(context) ? FidelisTheme.gold : FidelisTheme.deepRed,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mystery.verseTextFor(_language),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          // Meditation
          const SizedBox(height: 12),
          Text(
            mystery.meditation(_language),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          // Spiritual fruit
          const SizedBox(height: 8),
          Text(
            AppStrings.tFor('lbl_spiritual_fruit', _language).replaceAll('{{v}}', mystery.fruit(_language)),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDarkMode(context) ? FidelisTheme.gold : FidelisTheme.deepRed,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the current step's playback job: RUNTIME SYNTHESIS ONLY (the
  /// rosary's directed slot — [KokoroVoice.rosary] — EN af_aoede; ES
  /// af_aoede under Spanish phonemization — one voice in both languages,
  /// speed 0.9, the rosary-scoped bless-ed correction), with the highlight
  /// schedule derived from the SAME synthesis that produces the audio
  /// (the Kokoro pipeline's per-sentence timing — ONE source).
  ///
  /// The pre-rendered assets under assets/rosary_audio/ are NO LONGER in
  /// the playback path: they were rendered with the standard voices
  /// (bm_george / em_alex) — the wrong voices for the directed grid — and
  /// their bundled timing predates the current texts, so their timeline
  /// drifted from the audio they played. The files stay dormant on disk,
  /// unused.
  ///
  /// The job carries the prayer-level unit move (the media notification's
  /// Next/Previous: one prayer/step per press — see [_movePrayer]).
  AudioJob _stepJob() {
    final step = _steps[_currentStep];
    return AudioJob(
      id: _jobId,
      chunks: [
        AudioChunk(
            text: _fallbackSpeechText(step),
            lang: _language,
            voice: KokoroVoice.rosary),
      ],
      // The media notification's title: the prayer being recited.
      title: widget.isForDead
          ? AppStrings.t('rosary_for_the_dead')
          : AppStrings.t('title_holy_rosary'),
      onUnitMove: _movePrayer,
    );
  }

  /// Starts the current step's audio through the central controller.
  /// Starting playback turns listening mode ON (the governing rule): it
  /// persists across the step's natural completion until an explicit pause
  /// or leaving the screen.
  Future<void> _startCurrentStepAudio() async {
    _listening = true;
    _speakingLine = null;
    _speakingWord = null;
    await AudioController.instance.start(_stepJob(), owner: this);
    // Lookahead: while this step plays, the NEXT step's sentences are
    // already rendering into the prefetch cache (queued behind the playing
    // pipeline's own syntheses), so pressing Next starts without synthesis
    // latency. The decade's repeated Hail Marys hit the cache instantly.
    _prefetchNextStep();
    // THE RENDER-AHEAD (round 4): every step start re-targets the
    // background walk at the played step — the whole rosary still renders
    // to completion, the played step's sentences first (the Next/Previous
    // restarts and the uncached frontier serve from the walk).
    _beginRenderAhead(fromStep: _currentStep);
  }

  /// THE RENDER-AHEAD (round 4): the WHOLE rosary — every step's text, in
  /// order — as the playback chunks the background walk renders into the
  /// persistent render cache. The decade's repeated Hail Marys resolve to
  /// the same cached sentences (the same spoken text, the same slot
  /// configuration). en/es only: Latin keeps the flutter_tts path, which
  /// needs no render cache.
  List<AudioChunk> _allStepChunks() {
    if (_language != 'en' && _language != 'es') return const [];
    return [
      for (final step in _steps)
        AudioChunk(
            text: _fallbackSpeechText(step),
            lang: _language,
            voice: KokoroVoice.rosary),
    ];
  }

  /// [stepIndex]'s first sentence index within the all-steps stream (the
  /// render-ahead walks from the played step forward — the urgent
  /// sentences first).
  int _stepSentenceIndex(int stepIndex) {
    var index = 0;
    for (var i = 0; i < stepIndex && i < _steps.length; i++) {
      index +=
          TtsService.splitSentences(_fallbackSpeechText(_steps[i])).length;
    }
    return index;
  }

  /// Begins (or re-targets) the whole-rosary background render — on
  /// screen-open (fromStep 0) and on every step start (from the played
  /// step). Fire-and-forget; never blocks the caller.
  void _beginRenderAhead({int fromStep = 0}) {
    final chunks = _allStepChunks();
    if (chunks.isEmpty) return;
    RenderAhead.begin(
      chunks: chunks,
      lang: _language,
      fromSentence: _stepSentenceIndex(fromStep),
      label: 'rosary ${widget.mysteryType}',
    );
  }

  /// Renders the CURRENT step's sentences into the prefetch cache (en/es
  /// only; Latin keeps the flutter_tts path, which needs no prefetch) —
  /// the screen-open prefetch, composed exactly as [_startCurrentStepAudio]
  /// composes its chunk, so a Play press finds the opening audio ready.
  void _prefetchCurrentStep() {
    if (_language != 'en' && _language != 'es') return;
    final text = _fallbackSpeechText(_steps[_currentStep]);
    if (text.isEmpty) return;
    AudioController.instance.prefetch(
        AudioChunk(text: text, lang: _language, voice: KokoroVoice.rosary));
  }

  /// Renders the next step's sentences into the prefetch cache (en/es
  /// only; Latin keeps the flutter_tts path, which needs no prefetch).
  void _prefetchNextStep() {
    final next = _currentStep + 1;
    if (next >= _steps.length) return;
    if (_language != 'en' && _language != 'es') return;
    final text = _fallbackSpeechText(_steps[next]);
    if (text.isEmpty) return;
    AudioController.instance.prefetch(
        AudioChunk(text: text, lang: _language, voice: KokoroVoice.rosary));
  }

  /// Centered play/pause toggle: pauses/resumes this screen's stream, or
  /// starts it for the current step. An explicit pause ends listening mode
  /// (the governing rule); resuming or starting turns it back on.
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
      await _startCurrentStepAudio();
    }
  }

  /// Spoken text for steps without a pre-rendered file. The litany and
  /// mystery announcements return '' from _currentPrayerText() (their content
  /// is displayed separately), so their speech text is composed here.
  String _fallbackSpeechText(RosaryStep step) {
    switch (step.type) {
      case RosaryStepType.litany:
        // Same composition as the pre-rendered litany file: invocations plus
        // the closing prayer with displayed V./R. markers stripped.
        final closing = LitanyOfLoreto.getClosingPrayer(_language)
            .replaceAll(RegExp(r'^V\.\s*|^R\.\s*', multiLine: true), '');
        return '${LitanyOfLoreto.getInvocations(_language).join('\n')}\n\n$closing';
      case RosaryStepType.mysteryAnnouncement:
        return _mysteryAnnouncementText();
      default:
        return _currentPrayerText();
    }
  }

  /// Announcement text matching the pre-rendered mystery files: announcement
  /// line, verse, meditation, spiritual fruit.
  String _mysteryAnnouncementText() {
    final mysteries = MysteryData.getMysteries(widget.mysteryType);
    if (_step.mysteryIndex == null || _step.mysteryIndex! >= mysteries.length) {
      return '';
    }
    final m = mysteries[_step.mysteryIndex!];
    final n = m.number.clamp(1, 5);
    if (_language == 'es') {
      const ord = ['Primer', 'Segundo', 'Tercer', 'Cuarto', 'Quinto'];
      const set = {
        'joyful': 'Gozoso',
        'sorrowful': 'Doloroso',
        'glorious': 'Glorioso',
        'luminous': 'Luminoso',
      };
      final v = mysteryVersesEs[m.id] ?? [m.verseRef, m.verseText];
      return '${ord[n - 1]} Misterio ${set[m.type] ?? m.type}: ${m.titleEs}.\n\n'
          '${v[0]}.\n\n${v[1]}\n\n${m.meditationEs}\n\n'
          'Fruto Espiritual: ${m.fruitEs}.';
    }
    const ord = ['First', 'Second', 'Third', 'Fourth', 'Fifth'];
    const set = {
      'joyful': 'Joyful',
      'sorrowful': 'Sorrowful',
      'glorious': 'Glorious',
      'luminous': 'Luminous',
    };
    return 'The ${ord[n - 1]} ${set[m.type] ?? m.type} Mystery: ${m.titleEn}.\n\n'
        '${m.verseRef}.\n\n${m.verseText}\n\n${m.meditationEn}\n\n'
        'Spiritual Fruit: ${m.fruitEn}.';
  }

  String _currentPrayerText() {
    String prayerText = '';

    switch (_step.type) {
      case RosaryStepType.signOfTheCross:
        prayerText = RosaryPrayers.get('sign_of_the_cross', _language);
        break;
      case RosaryStepType.creed:
        prayerText = RosaryPrayers.get('apostles_creed', _language);
        break;
      case RosaryStepType.ourFather:
        prayerText = RosaryPrayers.get('our_father', _language);
        break;
      case RosaryStepType.hailMary:
        prayerText = RosaryPrayers.get('hail_mary', _language);
        break;
      case RosaryStepType.gloryBe:
        prayerText = RosaryPrayers.get('glory_be', _language);
        break;
      case RosaryStepType.fatimaPrayer:
        prayerText = RosaryPrayers.get('fatima_prayer', _language);
        break;
      case RosaryStepType.hailHolyQueen:
        prayerText = RosaryPrayers.get('hail_holy_queen', _language);
        break;
      case RosaryStepType.concludingPrayer:
        prayerText = RosaryPrayers.get('concluding_prayer', _language);
        break;
      case RosaryStepType.deProfundis:
        prayerText = RosaryPrayers.get('de_profundis', _language);
        if (widget.deceasedName != null && widget.deceasedName!.isNotEmpty) {
          final name = widget.deceasedName!;
          if (_language == 'en') {
            prayerText = prayerText
                .replaceFirst('Eternal rest grant unto them', 'Eternal rest grant unto $name')
                .replaceFirst('shine upon them', 'shine upon $_objectPronoun')
                .replaceFirst('May they rest', 'May $_subjectPronoun rest');
          } else if (_language == 'la') {
            // Réquiem ætérnam dona eis → dona [name], lúceat eis → lúceat [pronoun]
            final latinObj = _objectPronoun == 'him' ? 'ei' : 'ei'; // Latin doesn't distinguish easily, use name
            prayerText = prayerText
                .replaceFirst('dona eis', 'dona $name')
                .replaceFirst('lúceat eis', 'lúceat $latinObj')
                .replaceFirst('Requiéscant in pace', 'Requiéscat in pace');
          } else if (_language == 'es') {
            final esObj = _objectPronoun == 'him' ? 'él' : 'ella';
            final esSubj = _subjectPronoun == 'he' ? 'él' : 'ella';
            prayerText = prayerText
                .replaceFirst('Dales, Señor', 'Dale a $name, Señor')
                .replaceFirst('para ellos', 'para $esObj')
                .replaceFirst('Descansen en paz', 'Descanse $esSubj en paz');
          }
        }
        break;
      case RosaryStepType.eternalRest:
        prayerText = RosaryPrayers.get('eternal_rest', _language);
        if (widget.deceasedName != null && widget.deceasedName!.isNotEmpty) {
          final name = widget.deceasedName!;
          if (_language == 'en') {
            // Replace first "them" with name, second "them" with object pronoun
            // "May they rest in peace" => "May [subject pronoun] rest in peace"
            prayerText = prayerText
                .replaceFirst('them', name)
                .replaceFirst('them', _objectPronoun)
                .replaceFirst('May they rest', 'May $_subjectPronoun rest');
          } else if (_language == 'la') {
            final latinObj = _objectPronoun == 'him' ? 'ei' : 'ei';
            prayerText = prayerText
                .replaceFirst('dona eis', 'dona $name')
                .replaceFirst('lúceat eis', 'lúceat $latinObj')
                .replaceFirst('Requiéscant in pace', 'Requiéscat in pace');
          } else if (_language == 'es') {
            final esObj = _objectPronoun == 'him' ? 'él' : 'ella';
            final esSubj = _subjectPronoun == 'he' ? 'él' : 'ella';
            prayerText = prayerText
                .replaceFirst('Dales, Señor', 'Dale a $name, Señor')
                .replaceFirst('para ellos', 'para $esObj')
                .replaceFirst('Descansen en paz', 'Descanse $esSubj en paz');
          }
        }
        break;
      case RosaryStepType.deadRosaryClosing:
        prayerText = RosaryPrayers.get('dead_rosary_closing', _language);
        if (widget.deceasedName != null && widget.deceasedName!.isNotEmpty) {
          final name = widget.deceasedName!;
          if (_language == 'en') {
            prayerText = 'May the soul of $name, and all the faithful departed, through the mercy of God, rest in peace. Amen.';
          } else if (_language == 'la') {
            prayerText = 'Animæ $name, et ómnium fidélium defunctórum, per misericórdiam Dei, requiéscant in pace. Amen.';
          } else if (_language == 'es') {
            final esSubj = _subjectPronoun == 'he' ? 'él' : 'ella';
            prayerText = 'El alma de $name, y de todos los fieles difuntos, por la misericordia de Dios, descanse $esSubj en paz. Amén.';
          }
        }
        break;
      case RosaryStepType.litany:
        return '';
      case RosaryStepType.mysteryAnnouncement:
        return ''; // Mystery content shown separately
      default:
        break;
    }
    return prayerText;
  }

  /// Gold border marking the text currently being recited. Step-level
  /// companion to the line/word highlight (which the controller's word
  /// range drives for both runtime TTS and pre-rendered assets).
  Border? _recitedBorder() => _audioLoadedForMe
      ? Border.all(color: FidelisTheme.gold.withValues(alpha: 0.55), width: 1.5)
      : null;

  Widget _buildPrayerText(BuildContext context) {
    final theme = Theme.of(context);
    final prayerText = _currentPrayerText();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      decoration: BoxDecoration(
        color: isDarkMode(context) ? const Color(0xFF1E2D3D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: _recitedBorder(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SelectableText.rich(
        _prayerSpans(theme, prayerText),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Prayer text with the recited line highlighted (gold) and the word
  /// currently being recited washed with a stronger gold tint. Line/word
  /// positions come from the controller's timing streams; without an active
  /// highlight the text renders plain.
  TextSpan _prayerSpans(ThemeData theme, String text) {
    final base = theme.textTheme.bodyLarge?.copyWith(
      height: 1.8,
      fontSize: 18,
    );
    final line = _speakingLine;
    final word = _speakingWord;
    if (line == null || line >= _lineRanges(text).length) {
      return TextSpan(text: text, style: base);
    }
    final ranges = _lineRanges(text);
    final spans = <TextSpan>[];
    var cursor = 0;
    for (var i = 0; i < ranges.length; i++) {
      final (start, end) = ranges[i];
      if (start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, start)));
      }
      if (i == line) {
        final lineStyle = base?.copyWith(
          color: FidelisTheme.gold,
          fontWeight: FontWeight.w600,
        );
        if (word != null && word.$2 > word.$1) {
          final ws = word.$1.clamp(start, end);
          final we = word.$2.clamp(start, end);
          if (we > ws) {
            spans.add(TextSpan(text: text.substring(start, ws), style: lineStyle));
            spans.add(TextSpan(
              text: text.substring(ws, we),
              style: lineStyle?.copyWith(
                background: Paint()
                  ..color = FidelisTheme.gold.withValues(alpha: 0.35),
              ),
            ));
            spans.add(TextSpan(text: text.substring(we, end), style: lineStyle));
          } else {
            spans.add(TextSpan(text: text.substring(start, end), style: lineStyle));
          }
        } else {
          spans.add(TextSpan(text: text.substring(start, end), style: lineStyle));
        }
      } else {
        spans.add(TextSpan(text: text.substring(start, end)));
      }
      cursor = end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return TextSpan(children: spans, style: base);
  }

  /// Line (speakable-sentence) ranges of [text], cached per text identity —
  /// recomputed only when the step's text changes.
  List<(int, int)> _lineRanges(String text) {
    if (_cachedLineText != text) {
      _cachedLineText = text;
      _cachedLineRanges = TtsService.sentenceRanges(text);
    }
    return _cachedLineRanges!;
  }

  String? _cachedLineText;
  List<(int, int)>? _cachedLineRanges;

  String get deceasedNameRef => widget.deceasedName ?? 'the faithful departed';

  /// Get possessive form of pronoun: them>their, him>his, her>her
  String get _possessivePronoun => switch (widget.deceasedPronoun) {
    'him' => 'his',
    'her' => 'her',
    _ => 'their',
  };

  /// Get object pronoun: them, him, her
  String get _objectPronoun => widget.deceasedPronoun;

  /// Get subject pronoun: they, he, she
  String get _subjectPronoun => switch (widget.deceasedPronoun) {
    'him' => 'he',
    'her' => 'she',
    _ => 'they',
  };

  bool isDarkMode(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  Widget _buildLitanyContent(BuildContext context) {
    final theme = Theme.of(context);
    final invocations = LitanyOfLoreto.getInvocations(_language);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          decoration: BoxDecoration(
            color: isDarkMode(context) ? const Color(0xFF1E2D3D) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: _recitedBorder(),
          ),
          child: Column(
            children: [
              for (int i = 0; i <= _litanyIndex && i < invocations.length; i++)
                Padding(
                  key: _litanyKeys[i],
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    invocations[i],
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: i == _litanyIndex
                          ? FidelisTheme.gold
                          : theme.colorScheme.onSurface.withValues(alpha: i < _litanyIndex ? 0.5 : 1.0),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_litanyIndex < invocations.length)
          Text(
            '${_litanyIndex + 1} of ${invocations.length}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        if (_litanyIndex >= invocations.length)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
            decoration: BoxDecoration(
              color: FidelisTheme.deepRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              LitanyOfLoreto.getClosingPrayer(_language),
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildBeadProgress(BuildContext context) {
    final theme = Theme.of(context);
    final current = _step.hailMaryCount ?? 1;
    final isIntroductory = _step.mysteryIndex == null;
    final totalBeads = isIntroductory ? 3 : 10;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          if (isIntroductory)
            Text(
              AppStrings.t('three_hail_marys_note'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: FidelisTheme.gold,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          if (isIntroductory) const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalBeads, (index) {
              final filled = index < current;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.circle,
                  size: 20,
                  color: filled ? (isDarkMode(context) ? FidelisTheme.gold : FidelisTheme.deepRed) : (isDarkMode(context) ? const Color(0xFF3A4A5A) : FidelisTheme.ivory),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation(BuildContext context) {
    final theme = Theme.of(context);
    final isLastStep = _currentStep >= _steps.length - 1;
    final isFirstStep = _currentStep == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode(context) ? const Color(0xFF14202E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Centered play/pause toggle for the current step's audio.
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
                    backgroundColor: isDarkMode(context)
                        ? FidelisTheme.gold
                        : FidelisTheme.deepRed,
                    foregroundColor: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isFirstStep ? null : _previousStep,
                    child: Text(AppStrings.t('previous')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLastStep ? () => _finishRosary(context) : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode(context) ? FidelisTheme.gold : FidelisTheme.deepRed,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isLastStep ? 'Finish' : 'Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
    ),
    );
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Scroll to the current litany line using its GlobalKey
  /// Positions it 1/3 from the top of the viewport so it's always visible
  void _scrollToLitanyItem() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final key = _litanyKeys[_litanyIndex];
      final context = key.currentContext;
      if (context == null) return;

      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final scrollableBox = _scrollController.position.context.storageContext.findRenderObject() as RenderBox;

      // Get the position of the litany line relative to the scrollable
      final offset = renderBox.localToGlobal(Offset.zero, ancestor: scrollableBox).dy;

      // Current scroll position
      final currentScroll = _scrollController.offset;

      // Target: position this line 1/3 from the top of the viewport
      final viewportHeight = _scrollController.position.viewportDimension;
      final targetScroll = currentScroll + offset - (viewportHeight / 3);

      final clamped = targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent);

      _scrollController.jumpTo(clamped);
    });
  }

  /// The page NEVER advances on its own (the governing rule): one Next
  /// press is exactly one step advance, every time — no completion event,
  /// queue, or race may move it further. While listening (flag ON — set by
  /// any playback start, persisting across natural completion, cleared only
  /// by an explicit pause), the new step's audio auto-plays. While OFF
  /// (paused or never started), navigation is silent and any paused stream
  /// of the abandoned step is stopped, so play always means the shown step.
  void _nextStep() {
    if (_step.type == RosaryStepType.litany) {
      final invocations = LitanyOfLoreto.getInvocations(_language);
      if (_litanyIndex < invocations.length) {
        setState(() => _litanyIndex++);
        _scrollToLitanyItem();
        return; // same step — its audio keeps playing
      }
    }

    _advanceStep(1);
  }

  void _previousStep() {
    _advanceStep(-1);
  }

  /// The media notification's prayer-level Next/Previous (the job's unit
  /// move): the same step navigation as the in-app buttons. Playing
  /// (listening): the newly selected prayer starts playing — start()
  /// replaces the stream. Paused: the step advances silently and the
  /// resume is re-armed to the new step — the position moves without
  /// starting audio and the notification keeps showing Play. The litany's
  /// in-step invocation advance (one invocation per press, the step's
  /// audio continues) mirrors the in-app Next exactly.
  Future<int?> _movePrayer(int direction) async {
    final controller = AudioController.instance;
    if (controller.currentJobId != _jobId) return null;
    if (direction > 0 && _step.type == RosaryStepType.litany) {
      final invocations = LitanyOfLoreto.getInvocations(_language);
      if (_litanyIndex < invocations.length) {
        setState(() => _litanyIndex++);
        _scrollToLitanyItem();
        return null; // the same step — its audio keeps playing
      }
    }
    _advanceStep(direction, keepPausedStream: true);
    return null;
  }

  /// Shared Next/Previous step navigation: exactly one step per press,
  /// auto-playing the new step's audio only while listening.
  /// [keepPausedStream] (the notification's move while paused): the
  /// abandoned step's paused stream is KEPT (the notification stays,
  /// showing Play) and the resume is re-armed to the new step — the
  /// position moved without starting audio.
  void _advanceStep(int direction, {bool keepPausedStream = false}) {
    final target = _currentStep + direction;
    if (target < 0 || target > _steps.length - 1) return;
    final listening = _listening;
    setState(() {
      _currentStep = target;
      _showLitany = _steps[_currentStep].type == RosaryStepType.litany;
      _litanyIndex = 0;
      _speakingLine = null;
      _speakingWord = null;
    });
    _scrollToTop();
    _saveState();
    final controller = AudioController.instance;
    if (listening) {
      // start() replaces the current stream (playing or paused).
      unawaited(_startCurrentStepAudio());
    } else if (keepPausedStream &&
        controller.state == AudioState.paused &&
        controller.currentJobId == _jobId) {
      controller.armResume(_stepJob(), owner: this);
    } else if (controller.currentJobId == _jobId) {
      // Silent navigation: the abandoned step's paused stream is stale —
      // stop it so a later play starts the shown step fresh.
      unawaited(controller.stop());
    }
  }

  Future<void> _saveState() async {
    final mysteryTypes = RosaryController.getDayMysteries(
      DateTime.now(),
      widget.includeLuminous,
    );
    await RosaryState.save(
      mysteryType: widget.mysteryType,
      includeLuminous: widget.includeLuminous,
      isForDead: widget.isForDead,
      language: _language,
      currentStep: _currentStep,
      mysteryTypes: mysteryTypes,
      deceasedName: widget.deceasedName,
      deceasedPronoun: widget.deceasedPronoun,
    );
  }

  void _finishRosary(BuildContext context) {
    RosaryState.clear(); // Clear saved state on completion
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.t('rosary_complete')),
        content: Text(
          widget.isForDead
              ? 'You have completed the Rosary for the Dead. May the souls of the faithful departed rest in peace.'
              : AppStrings.t('rosary_complete_body'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: Text(AppStrings.t('amen')),
          ),
        ],
      ),
    );
  }



  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.t('leave_rosary')),
        content: Text(AppStrings.t('progress_saved_note')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.t('stay')),
          ),
          ElevatedButton(
            onPressed: () {
              _saveState(); // Ensure state is saved before leaving
              Navigator.pop(dialogContext); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.t('progress_saved_toast')),
                  duration: Duration(seconds: 3),
                ),
              );
              Navigator.of(context).popUntil((route) => route.isFirst); // Go to home
            },
            child: Text(AppStrings.t('leave')),
          ),
        ],
      ),
    );
  }
}