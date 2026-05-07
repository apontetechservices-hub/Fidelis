import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import 'stations_data.dart';
import 'stations_prayer_screen.dart';
import 'stabat_mater_screen.dart';

class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  String _method = 'francis';

  static const List<String> _romanNumerals = [
    'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X',
    'XI', 'XII', 'XIII', 'XIV',
  ];

  @override
  void initState() {
    super.initState();
    _loadMethod();
  }

  Future<void> _loadMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('stations_method') ?? 'francis';
    if (mounted) setState(() => _method = saved);
  }

  Future<void> _saveMethod(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stations_method', method);
    setState(() => _method = method);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark ? FidelisTheme.gold : FidelisTheme.deepRed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stations of the Cross'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_music),
            tooltip: 'Stabat Mater',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StabatMaterScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Method selection chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _MethodChip(
                  label: 'St. Francis',
                  selected: _method == 'francis',
                  color: accentColor,
                  onTap: () => _saveMethod('francis'),
                ),
                const SizedBox(width: 12),
                _MethodChip(
                  label: 'Traditional',
                  selected: _method == 'traditional',
                  color: accentColor,
                  onTap: () => _saveMethod('traditional'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              _method == 'francis'
                  ? 'Method of St. Francis of Assisi'
                  : 'Traditional method with Stabat Mater',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Station list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.of(context).viewPadding.bottom + MediaQuery.of(context).viewInsets.bottom),
              itemCount: stationInfo.length,
              itemBuilder: (context, index) {
                final station = stationInfo[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StationsPrayerScreen(
                            initialStation: station.number,
                            method: _method,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            // Roman numeral circle
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentColor.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: accentColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _romanNumerals[index],
                                  style: TextStyle(
                                    fontFamily: 'Cinzel',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    station.title,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    station.titleLa,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: accentColor.withValues(alpha: 0.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _MethodChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : color,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}