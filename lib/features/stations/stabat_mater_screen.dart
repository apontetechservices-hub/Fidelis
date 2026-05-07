import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'stations_data.dart';

class StabatMaterScreen extends StatefulWidget {
  const StabatMaterScreen({super.key});

  @override
  State<StabatMaterScreen> createState() => _StabatMaterScreenState();
}

class _StabatMaterScreenState extends State<StabatMaterScreen> {
  // 0 = Latin, 1 = English, 2 = Both
  int _mode = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark ? FidelisTheme.gold : FidelisTheme.deepRed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stabat Mater'),
      ),
      body: Column(
        children: [
          // Toggle Latin / English / Both
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _toggleChip('Latin', _mode == 0, accentColor, () => setState(() => _mode = 0)),
                const SizedBox(width: 8),
                _toggleChip('English', _mode == 1, accentColor, () => setState(() => _mode = 1)),
                const SizedBox(width: 8),
                _toggleChip('Both', _mode == 2, accentColor, () => setState(() => _mode = 2)),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Stabat Mater Dolorosa',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: accentColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hymn of the Sorrowful Mother',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: FidelisTheme.gold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (_mode == 0 || _mode == 2)
                    _sectionCard(context, 'Latin', stabatMaterFullLatin, isDark),
                  if (_mode == 2) const SizedBox(height: 20),
                  if (_mode == 1 || _mode == 2)
                    _sectionCard(context, 'English', stabatMaterFullEnglish, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleChip(String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, String label, String text, bool isDark) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: FidelisTheme.gold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
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
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.9,
              fontStyle: label == 'Latin' ? FontStyle.italic : FontStyle.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}