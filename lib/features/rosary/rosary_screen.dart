import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import 'rosary_prayer_screen.dart';
import 'rosary_state.dart';
import 'mystery_data.dart';

class RosaryScreen extends StatefulWidget {
  const RosaryScreen({super.key});

  @override
  State<RosaryScreen> createState() => _RosaryScreenState();
}

class _RosaryScreenState extends State<RosaryScreen> with WidgetsBindingObserver {
  String _rosaryType = AppConstants.rosaryTraditional;
  String _language = AppConstants.langEnglish;
  String _mysteryFilter = 'all';
  Map<String, dynamic>? _savedState;
  bool _checkingSaved = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPrefs();
    _checkSavedState();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rosaryType = prefs.getString('rosary_type') ?? AppConstants.rosaryTraditional;
      _language = prefs.getString('rosary_language') ?? AppConstants.langEnglish;
    });
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) await prefs.setString(key, value);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSavedState();
    }
  }

  Future<void> _checkSavedState() async {
    final hasState = await RosaryState.hasSavedState();
    if (hasState) {
      final data = await RosaryState.load();
      if (mounted) {
        setState(() {
          _savedState = data;
          _checkingSaved = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _savedState = null;
          _checkingSaved = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayMystery = _getDayMystery();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Holy Rosary'),
        actions: [
          // Rosary type dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: DropdownButton<String>(
              value: _rosaryType,
              underline: const SizedBox.shrink(),
              icon: Icon(Icons.arrow_drop_down, size: 20, color: theme.brightness == Brightness.dark ? FidelisTheme.gold : FidelisTheme.deepRed),
              style: TextStyle(
                fontSize: 12,
                color: theme.brightness == Brightness.dark ? FidelisTheme.gold : FidelisTheme.deepRed,
              ),
              dropdownColor: theme.brightness == Brightness.dark ? const Color(0xFF1E2D3D) : Colors.white,
              items: const [
                DropdownMenuItem(
                  value: AppConstants.rosaryTraditional,
                  child: Text('Traditional'),
                ),
                DropdownMenuItem(
                  value: AppConstants.rosaryNovusOrdo,
                  child: Text('Novus Ordo'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _rosaryType = value);
                  _savePref('rosary_type', value);
                }
              },
            ),
          ),
          // Language dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: DropdownButton<String>(
              value: _language,
              underline: const SizedBox.shrink(),
              icon: Icon(Icons.arrow_drop_down, size: 20, color: theme.brightness == Brightness.dark ? FidelisTheme.gold : FidelisTheme.deepRed),
              style: TextStyle(
                fontSize: 12,
                color: theme.brightness == Brightness.dark ? FidelisTheme.gold : FidelisTheme.deepRed,
              ),
              dropdownColor: theme.brightness == Brightness.dark ? const Color(0xFF1E2D3D) : Colors.white,
              items: const [
                DropdownMenuItem(value: AppConstants.langEnglish, child: Text('🇺🇸 EN')),
                DropdownMenuItem(value: AppConstants.langLatin, child: Text('🏛️ LA')),
                DropdownMenuItem(value: AppConstants.langSpanish, child: Text('🇪🇸 ES')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _language = value);
                  _savePref('rosary_language', value);
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Today's mysteries card
            _TodayMysteryCard(
              mysteryType: todayMystery,
              language: _language,
              rosaryType: _rosaryType,
            ),
            const SizedBox(height: 16),

            // Resume saved rosary
            if (_savedState != null) ...[
              Card(
                color: FidelisTheme.gold.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: FidelisTheme.gold, width: 1.5),
                ),
                child: InkWell(
                  onTap: () => _resumeRosary(),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.play_circle_fill, size: 32, color: Theme.of(context).brightness == Brightness.dark ? FidelisTheme.gold : FidelisTheme.deepRed),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Resume Rosary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(
                                _getResumeLabel(),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            RosaryState.clear();
                            setState(() => _savedState = null);
                          },
                          tooltip: 'Discard saved progress',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Start today's rosary
            ElevatedButton.icon(
              onPressed: () => _startRosary(mysteryType: todayMystery),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Pray Today\'s Rosary'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? FidelisTheme.gold : FidelisTheme.deepRed,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Rosary for the Dead
            OutlinedButton.icon(
              onPressed: () => _startDeadRosary(),
              icon: const Icon(Icons.church),
              label: const Text('Rosary for the Dead'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            // Pray a specific mystery set
            Text('Pray a Specific Mystery', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _MysterySetCard(
              type: AppConstants.joyfulMysteries,
              language: _language,
              onTap: () => _startRosary(mysteryType: AppConstants.joyfulMysteries),
            ),
            _MysterySetCard(
              type: AppConstants.sorrowfulMysteries,
              language: _language,
              onTap: () => _startRosary(mysteryType: AppConstants.sorrowfulMysteries),
            ),
            _MysterySetCard(
              type: AppConstants.gloriousMysteries,
              language: _language,
              onTap: () => _startRosary(mysteryType: AppConstants.gloriousMysteries),
            ),
            if (_rosaryType == AppConstants.rosaryNovusOrdo)
              _MysterySetCard(
                type: AppConstants.luminousMysteries,
                language: _language,
                onTap: () => _startRosary(mysteryType: AppConstants.luminousMysteries),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getDayMystery() {
    final day = DateTime.now().weekday;
    switch (day) {
      case 1: return AppConstants.joyfulMysteries;
      case 2: return AppConstants.sorrowfulMysteries;
      case 3: return AppConstants.gloriousMysteries;
      case 4: return _rosaryType == AppConstants.rosaryNovusOrdo
          ? AppConstants.luminousMysteries
          : AppConstants.joyfulMysteries;
      case 5: return AppConstants.sorrowfulMysteries;
      case 6: return AppConstants.joyfulMysteries;
      case 7: return AppConstants.gloriousMysteries;
      default: return AppConstants.joyfulMysteries;
    }
  }

  void _startRosary({required String mysteryType}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RosaryPrayerScreen(
          mysteryType: mysteryType,
          includeLuminous: _rosaryType == AppConstants.rosaryNovusOrdo,
          isForDead: false,
          language: _language,
        ),
      ),
    );
  }

  void _resumeRosary() {
    if (_savedState == null) return;
    final state = _savedState!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RosaryPrayerScreen(
          mysteryType: state['mysteryType'] as String,
          includeLuminous: state['includeLuminous'] as bool,
          isForDead: state['isForDead'] as bool,
          language: state['language'] as String ?? 'en',
          deceasedName: state['deceasedName'] as String?,
          deceasedPronoun: state['deceasedPronoun'] as String? ?? 'them',
          startStep: state['currentStep'] as int? ?? 0,
        ),
      ),
    );
  }

  String _getResumeLabel() {
    if (_savedState == null) return '';
    final step = _savedState!['currentStep'] as int? ?? 0;
    final isForDead = _savedState!['isForDead'] as bool? ?? false;
    final mysteryType = _savedState!['mysteryType'] as String? ?? 'joyful';
    final typeName = MysteryData.getMysteries(mysteryType).isNotEmpty ? mysteryType : 'joyful';
    final label = isForDead ? 'Rosary for the Dead' : '${typeName[0].toUpperCase()}${typeName.substring(1)} Mysteries';
    return '$label \u2022 Step ${step + 1}';
  }

  void _startDeadRosary() {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        String pronoun = 'him'; // default
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Rosary for the Dead'),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter the name of the faithful departed. Their name and pronouns will be included in the prayers.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Name of the deceased',
                      hintText: 'Enter name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => name = value,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: pronoun,
                    decoration: const InputDecoration(
                      labelText: 'Sex',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'him', child: Text('Male')),
                      DropdownMenuItem(value: 'her', child: Text('Female')),
                    ],
                    onChanged: (value) => setState(() => pronoun = value ?? 'him'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RosaryPrayerScreen(
                        mysteryType: _getDayMystery(),
                        includeLuminous: _rosaryType == AppConstants.rosaryNovusOrdo,
                        isForDead: true,
                        language: _language,
                        deceasedName: name,
                        deceasedPronoun: pronoun,
                      ),
                    ),
                  );
                },
                child: const Text('Begin'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TodayMysteryCard extends StatelessWidget {
  final String mysteryType;
  final String language;
  final String rosaryType;

  const _TodayMysteryCard({
    required this.mysteryType,
    required this.language,
    required this.rosaryType,
  });

  String get _title {
    switch (mysteryType) {
      case AppConstants.joyfulMysteries:
        return {AppConstants.langEnglish: 'Joyful Mysteries', AppConstants.langLatin: 'Mysteria Gaudiosa', AppConstants.langSpanish: 'Misterios Gozosos'}[language] ?? 'Joyful Mysteries';
      case AppConstants.sorrowfulMysteries:
        return {AppConstants.langEnglish: 'Sorrowful Mysteries', AppConstants.langLatin: 'Mysteria Dolorosa', AppConstants.langSpanish: 'Misterios Dolorosos'}[language] ?? 'Sorrowful Mysteries';
      case AppConstants.gloriousMysteries:
        return {AppConstants.langEnglish: 'Glorious Mysteries', AppConstants.langLatin: 'Mysteria Gloriosa', AppConstants.langSpanish: 'Misterios Gloriosos'}[language] ?? 'Glorious Mysteries';
      case AppConstants.luminousMysteries:
        return {AppConstants.langEnglish: 'Luminous Mysteries', AppConstants.langLatin: 'Mysteria Luminosa', AppConstants.langSpanish: 'Misterios Luminosos'}[language] ?? 'Luminous Mysteries';
      default: return 'Joyful Mysteries';
    }
  }

  String get _dayName {
    final days = {
      1: {AppConstants.langEnglish: 'Monday', AppConstants.langLatin: 'Feria Secunda', AppConstants.langSpanish: 'Lunes'},
      2: {AppConstants.langEnglish: 'Tuesday', AppConstants.langLatin: 'Feria Tertia', AppConstants.langSpanish: 'Martes'},
      3: {AppConstants.langEnglish: 'Wednesday', AppConstants.langLatin: 'Feria Quarta', AppConstants.langSpanish: 'Miércoles'},
      4: {AppConstants.langEnglish: 'Thursday', AppConstants.langLatin: 'Feria Quinta', AppConstants.langSpanish: 'Jueves'},
      5: {AppConstants.langEnglish: 'Friday', AppConstants.langLatin: 'Feria Sexta', AppConstants.langSpanish: 'Viernes'},
      6: {AppConstants.langEnglish: 'Saturday', AppConstants.langLatin: 'Sabbato', AppConstants.langSpanish: 'Sábado'},
      7: {AppConstants.langEnglish: 'Sunday', AppConstants.langLatin: 'Dominica', AppConstants.langSpanish: 'Domingo'},
    };
    return days[DateTime.now().weekday]?[language] ?? 'Today';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF3C2A5C), const Color(0xFF1A2332)]
              : [FidelisTheme.deepRed, const Color(0xFF6B2020)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, size: 36, color: FidelisTheme.gold),
          const SizedBox(height: 12),
          Text(
            'Today — $_dayName',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            _title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: FidelisTheme.gold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MysterySetCard extends StatelessWidget {
  final String type;
  final String language;
  final VoidCallback onTap;

  const _MysterySetCard({
    required this.type,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mysteries = MysteryData.getMysteries(type);
    final title = mysteries.first.title(language).replaceFirst(RegExp(r'^The (First|1st)\s'), '');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTitle(),
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                mysteries.map((m) => m.title(language).split(':').last.trim()).join(' • '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (type) {
      case AppConstants.joyfulMysteries: return '🌹 Joyful Mysteries';
      case AppConstants.sorrowfulMysteries: return '✝️ Sorrowful Mysteries';
      case AppConstants.gloriousMysteries: return '👑 Glorious Mysteries';
      case AppConstants.luminousMysteries: return '☀️ Luminous Mysteries';
      default: return 'Mysteries';
    }
  }
}

class _LanguageToggle extends StatelessWidget {
  final String currentLanguage;
  final ValueChanged<String> onChanged;

  const _LanguageToggle({required this.currentLanguage, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Prayer Language', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: AppConstants.langEnglish, label: Text('🇺🇸 EN')),
            ButtonSegment(value: AppConstants.langLatin, label: Text('🏛️ LA')),
            ButtonSegment(value: AppConstants.langSpanish, label: Text('🇪🇸 ES')),
          ],
          selected: {currentLanguage},
          onSelectionChanged: (selected) => onChanged(selected.first),
        ),
      ],
    );
  }
}