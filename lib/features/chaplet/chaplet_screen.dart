import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../features/rosary/rosary_prayers.dart';
import 'chaplet_prayers.dart';

class ChapletScreen extends StatefulWidget {
  final String language;
  const ChapletScreen({super.key, this.language = 'en'});

  @override
  State<ChapletScreen> createState() => _ChapletScreenState();
}

class _ChapletScreenState extends State<ChapletScreen> {
  late List<ChapletStep> _steps;
  int _currentStep = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _steps = ChapletController.buildSteps(language: widget.language);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double get _progress => (_currentStep + 1) / _steps.length;
  ChapletStep get _step => _steps[_currentStep];

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _scrollToTop();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _scrollToTop();
    }
  }

  String _getPrayerText() {
    switch (_step.type) {
      case ChapletStepType.signOfCross:
        return RosaryPrayers.get('sign_of_the_cross', widget.language);
      case ChapletStepType.creed:
        return RosaryPrayers.get('apostles_creed', widget.language);
      case ChapletStepType.ourFather:
        return RosaryPrayers.get('our_father', widget.language);
      case ChapletStepType.hailMary:
        return RosaryPrayers.get('hail_mary', widget.language);
      case ChapletStepType.eternalFather:
        return ChapletPrayers.get('decade', widget.language);
      case ChapletStepType.sorrowfulPassion:
        return ChapletPrayers.get('small_bead', widget.language);
      case ChapletStepType.holyGod:
        return ChapletPrayers.get('closing', widget.language);
      case ChapletStepType.finalPrayer:
        return ChapletPrayers.get('final', widget.language);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLastStep = _currentStep >= _steps.length - 1;
    final isFirstStep = _currentStep == 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Divine Mercy Chaplet'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _confirmExit(context),
          ),
        ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: isDark ? const Color(0xFF243447) : FidelisTheme.ivory,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE57373)),
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
                      color: const Color(0xFFE57373),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Decade indicator for Eternal Father
                  if (_step.type == ChapletStepType.eternalFather && _step.decadeIndex != null)
                    _buildDecadeHeader(context),

                  // Prayer text
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2D3D) : Colors.white,
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
                      _getPrayerText(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.8,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bead progress for 3 Hail Marys
                  if (_step.type == ChapletStepType.hailMary && _step.beadCount != null)
                    _buildHailMaryProgress(context),

                  // Bead progress for sorrowful passion
                  if (_step.type == ChapletStepType.sorrowfulPassion && _step.beadCount != null)
                    _buildBeadProgress(context),

                  // Holy God repeat indicator
                  if (_step.type == ChapletStepType.holyGod && _step.repeatCount != null)
                    _buildRepeatIndicator(context),
                ],
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14202E) : Colors.white,
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
                      onPressed: isLastStep ? () => _finishChaplet(context) : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE57373),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isLastStep ? 'Finish' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildDecadeHeader(BuildContext context) {
    final theme = Theme.of(context);
    final d = _step.decadeIndex!;
    final decades = [
      'For the whole world',
      'For the souls of priests and religious',
      'For the conversion of sinners',
      'For the faithful departed',
      'For the intentions of the Holy Father',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE57373).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE57373).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Decade $d of 5',
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFFE57373),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            decades[d - 1],
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: FidelisTheme.gold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHailMaryProgress(BuildContext context) {
    final theme = Theme.of(context);
    final current = _step.beadCount ?? 1;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final filled = index < current;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.circle,
              size: 20,
              color: filled
                  ? const Color(0xFFE57373)
                  : (isDark ? const Color(0xFF3A4A5A) : FidelisTheme.ivory),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBeadProgress(BuildContext context) {
    final theme = Theme.of(context);
    final current = _step.beadCount ?? 1;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(10, (index) {
          final filled = index < current;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.circle,
              size: 20,
              color: filled
                  ? const Color(0xFFE57373)
                  : (isDark ? const Color(0xFF3A4A5A) : FidelisTheme.ivory),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRepeatIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final current = _step.repeatCount ?? 1;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final filled = index < current;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.favorite,
              size: 20,
              color: filled ? const Color(0xFFE57373) : Colors.grey.shade300,
            ),
          );
        }),
      ),
    );
  }

  void _finishChaplet(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🙏 Chaplet Complete'),
        content: const Text(
          'You have completed the Chaplet of Divine Mercy. May His mercy flow through you and upon the whole world.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              foregroundColor: Colors.white,
            ),
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
        title: const Text('Leave Chaplet?'),
        content: const Text('Your progress will be lost. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}