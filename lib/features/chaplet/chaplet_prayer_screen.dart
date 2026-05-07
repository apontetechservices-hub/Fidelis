import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'chaplet_data.dart';

class ChapletPrayerScreen extends StatefulWidget {
  final ChapletId chapletId;

  const ChapletPrayerScreen({super.key, required this.chapletId});

  @override
  State<ChapletPrayerScreen> createState() => _ChapletPrayerScreenState();
}

class _ChapletPrayerScreenState extends State<ChapletPrayerScreen> {
  late List<ChapletPrayerStep> _steps;
  int _currentStep = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _steps = buildChapletSteps(widget.chapletId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double get _progress => (_currentStep + 1) / _steps.length;
  ChapletPrayerStep get _step => _steps[_currentStep];
  ChapletMeta get _meta => getChapletMeta(widget.chapletId);

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

  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);

    return Scaffold(
        appBar: AppBar(
          title: Text(_meta.name),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: isDark ? const Color(0xFF243447) : FidelisTheme.ivory,
              valueColor: AlwaysStoppedAnimation<Color>(_meta.accentColor),
              minHeight: 3,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _step.label,
                      style: theme.textTheme.titleLarge?.copyWith(color: _meta.accentColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (_step.decadeIndex != null && _step.totalDecades != null && _step.type != ChapletStepType.hailMary)
                      _buildDecadeHeader(context),
                    if (_step.type == ChapletStepType.meditation)
                      _buildMeditationContent(context),
                    if (_step.type != ChapletStepType.meditation)
                      _buildPrayerText(context),
                    const SizedBox(height: 16),
                    if (_step.type == ChapletStepType.hailMary && _step.beadIndex != null && _step.totalBeads != null)
                      _buildBeadProgress(context),
                    if (_step.repeatIndex != null && _step.totalRepeats != null)
                      _buildRepeatIndicator(context),
                  ],
                ),
              ),
            ),
            _buildNavigation(context),
          ],
        ),
    );
  }

  Widget _buildDecadeHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _meta.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _meta.accentColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${_step.decadeIndex} of ${_step.totalDecades}',
        style: theme.textTheme.titleMedium?.copyWith(color: _meta.accentColor, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMeditationContent(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _meta.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _meta.accentColor.withValues(alpha: 0.3)),
      ),
      child: SelectableText(
        _step.prayerText,
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.8, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPrayerText(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2D3D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: SelectableText(
        _step.prayerText,
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.8, fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBeadProgress(BuildContext context) {
    final isDark = _isDark(context);
    final current = _step.beadIndex ?? 1;
    final total = _step.totalBeads ?? 10;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (index) {
          final filled = index < current;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: total > 7 ? 2 : 4),
            child: Icon(
              Icons.circle,
              size: total > 7 ? 16 : 20,
              color: filled ? _meta.accentColor : (isDark ? const Color(0xFF3A4A5A) : FidelisTheme.ivory),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRepeatIndicator(BuildContext context) {
    final current = _step.repeatIndex ?? 1;
    final total = _step.totalRepeats ?? 3;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (index) {
          final filled = index < current;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.favorite,
              size: 20,
              color: filled ? _meta.accentColor : Colors.grey.shade300,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigation(BuildContext context) {
    final isDark = _isDark(context);
    final isLastStep = _currentStep >= _steps.length - 1;
    final isFirstStep = _currentStep == 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14202E) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))],
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
                style: ElevatedButton.styleFrom(backgroundColor: _meta.accentColor, foregroundColor: Colors.white),
                child: Text(isLastStep ? 'Finish' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _finishChaplet(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_meta.emoji} ${_meta.name} Complete'),
        content: const Text('May God bless your prayers. Amen.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            style: ElevatedButton.styleFrom(backgroundColor: _meta.accentColor, foregroundColor: Colors.white),
            child: const Text('Amen'),
          ),
        ],
      ),
    );
  }
}