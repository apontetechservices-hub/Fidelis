import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'lot_service.dart';

class LotHourScreen extends StatefulWidget {
  final LotHour hour;

  const LotHourScreen({super.key, required this.hour});
  @override
  State<LotHourScreen> createState() => _LotHourScreenState();
}

class _LotHourScreenState extends State<LotHourScreen> {
  bool _showLatin = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.hour.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Text(
              'LA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _showLatin ? FidelisTheme.gold : null,
              ),
            ),
            tooltip: 'Latin',
            onPressed: () => setState(() => _showLatin = !_showLatin),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: widget.hour.sections.length,
        itemBuilder: (context, i) {
          final s = widget.hour.sections[i];
          final text = _showLatin ? s.la : s.vernacular;
          if (text.isEmpty) return const SizedBox.shrink();
          final isPsalm = s.type == 'antiphon_psalm';
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (s.label.isNotEmpty) ...[
                  Text(
                    s.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.7,
                    fontStyle: isPsalm ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}