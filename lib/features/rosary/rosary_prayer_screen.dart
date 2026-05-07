import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import 'rosary_controller.dart';
import 'rosary_prayers.dart';
import 'mystery_data.dart';
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
  late List<RosaryStep> _steps;
  int _currentStep = 0;
  bool _showLitany = false;
  int _litanyIndex = 0;
  late String _language;
  final ScrollController _scrollController = ScrollController();

  // GlobalKey per litany line for precise scroll positioning
  static const int _maxLitanyLines = 70;
  final List<GlobalKey> _litanyKeys = List.generate(_maxLitanyLines, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _saveState();
    super.dispose();
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
          title: Text(widget.isForDead ? 'Rosary for the Dead' : 'Holy Rosary'),
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
                    _step.label,
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
        border: Border.all(color: FidelisTheme.gold.withValues(alpha: 0.3)),
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
                    mystery.verseRef,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDarkMode(context) ? FidelisTheme.gold : FidelisTheme.deepRed,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mystery.verseText,
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
            'Spiritual Fruit: ${mystery.fruit(_language)}',
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

  Widget _buildPrayerText(BuildContext context) {
    final theme = Theme.of(context);
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
        return const SizedBox.shrink();
      case RosaryStepType.mysteryAnnouncement:
        return const SizedBox.shrink(); // Mystery content shown separately
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      decoration: BoxDecoration(
        color: isDarkMode(context) ? const Color(0xFF1E2D3D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SelectableText(
        prayerText,
        style: theme.textTheme.bodyLarge?.copyWith(
          height: 1.8,
          fontSize: 18,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

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
              'Three Hail Marys for the increase of Faith, Hope, and Charity',
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isFirstStep ? null : _previousStep,
                child: const Text('Previous'),
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

  void _nextStep() {
    if (_step.type == RosaryStepType.litany) {
      final invocations = LitanyOfLoreto.getInvocations(_language);
      if (_litanyIndex < invocations.length) {
        setState(() => _litanyIndex++);
        _scrollToLitanyItem();
        return;
      }
    }

    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
        _showLitany = _steps[_currentStep].type == RosaryStepType.litany;
        _litanyIndex = 0;
      });
      _scrollToTop();
      _saveState();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _showLitany = _steps[_currentStep].type == RosaryStepType.litany;
        _litanyIndex = 0;
      });
      _scrollToTop();
      _saveState();
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
        title: const Text('🌹 Rosary Complete'),
        content: Text(
          widget.isForDead
              ? 'You have completed the Rosary for the Dead. May the souls of the faithful departed rest in peace.'
              : 'You have completed the Holy Rosary. May the Blessed Virgin Mary intercede for you.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text('Amen'),
          ),
        ],
      ),
    );
  }



  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave Rosary?'),
        content: const Text('Your progress will be saved. Resume from the Rosary tab later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveState(); // Ensure state is saved before leaving
              Navigator.pop(dialogContext); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Progress saved! Resume from the Rosary tab.'),
                  duration: Duration(seconds: 3),
                ),
              );
              Navigator.of(context).popUntil((route) => route.isFirst); // Go to home
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}