import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'stations_data.dart';

class StationsPrayerScreen extends StatefulWidget {
  final int initialStation;
  final String method; // 'francis' or 'traditional'

  const StationsPrayerScreen({
    super.key,
    required this.initialStation,
    this.method = 'francis',
  });

  @override
  State<StationsPrayerScreen> createState() => _StationsPrayerScreenState();
}

class _StationsPrayerScreenState extends State<StationsPrayerScreen> {
  late int _currentStation;
  final ScrollController _scrollController = ScrollController();

  static const List<String> _romanNumerals = [
    'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X',
    'XI', 'XII', 'XIII', 'XIV',
  ];

  @override
  void initState() {
    super.initState();
    _currentStation = widget.initialStation;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double get _progress => _currentStation / 14;
  bool get _isFirst => _currentStation == 1;
  bool get _isLast => _currentStation == 14;

  StationInfo get _info => stationInfo[_currentStation - 1];

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _nextStation() {
    if (!_isLast) {
      setState(() => _currentStation++);
      _scrollToTop();
    }
  }

  void _previousStation() {
    if (!_isFirst) {
      setState(() => _currentStation--);
      _scrollToTop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark ? FidelisTheme.gold : FidelisTheme.deepRed;

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Stations of the Cross'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress bar
              LinearProgressIndicator(
              value: _progress,
              backgroundColor: isDark ? const Color(0xFF243447) : FidelisTheme.ivory,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 3,
            ),

            // Station counter
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Station $_currentStation of 14',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _romanNumerals[_currentStation - 1],
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Station title + Latin
                    Text(
                      _info.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: accentColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _info.titleLa,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: FidelisTheme.gold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Meditation
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: isDark ? 0.08 : 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _info.meditation,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.7,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Method-specific content
                    if (widget.method == 'francis')
                      _buildFrancisContent(context, isDark, accentColor)
                    else
                      _buildTraditionalContent(context, isDark, accentColor),

                    const SizedBox(height: 24),

                    // Common prayers after each station
                    _buildCommonPrayers(context, isDark, accentColor),
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isFirst ? null : _previousStation,
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLast ? () => _finish(context) : _nextStation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isLast ? 'Finish' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildFrancisContent(BuildContext context, bool isDark, Color accentColor) {
    final theme = Theme.of(context);
    final station = stFrancisStations[_currentStation - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Leader
        Text(
          station.leader,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: accentColor,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        // Response
        Text(
          station.response,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Prayer
        Container(
          padding: const EdgeInsets.all(20),
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
            station.prayer,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        // Closing prayer
        Text(
          station.closingPrayer,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            height: 1.7,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTraditionalContent(BuildContext context, bool isDark, Color accentColor) {
    final theme = Theme.of(context);
    final station = traditionalStations[_currentStation - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Leader
        Text(
          station.leader,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: accentColor,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        // Response
        Text(
          station.response,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Prayer
        Container(
          padding: const EdgeInsets.all(20),
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
            station.prayer,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        // Stabat Mater verse
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FidelisTheme.gold.withValues(alpha: isDark ? 0.08 : 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: FidelisTheme.gold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Stabat Mater',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FidelisTheme.gold.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                station.stabatMaterVerse,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.7,
                  color: FidelisTheme.gold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommonPrayers(BuildContext context, bool isDark, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(color: accentColor.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        Text(
          'Prayers after each Station',
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: accentColor.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        _prayerBlock(context, 'Our Father', ourFather, isDark),
        const SizedBox(height: 12),
        _prayerBlock(context, 'Hail Mary', hailMary, isDark),
        const SizedBox(height: 12),
        _prayerBlock(context, 'Glory Be', gloryBe, isDark),
      ],
    );
  }

  Widget _prayerBlock(BuildContext context, String label, String text, bool isDark) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: FidelisTheme.gold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        SelectableText(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _finish(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? FidelisTheme.gold : FidelisTheme.deepRed;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✝️ Stations Complete'),
        content: SingleChildScrollView(
          child: Text(
            widget.method == 'francis' ? stFrancisClosing : traditionalClosing,
            style: const TextStyle(fontFamily: 'Lora', fontSize: 14, height: 1.7),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Amen'),
          ),
        ],
      ),
    );
  }
}