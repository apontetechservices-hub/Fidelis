import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'novena_data.dart';
import 'novena_storage.dart';
import 'novena_detail_screen.dart';

class NovenasScreen extends StatefulWidget {
  const NovenasScreen({super.key});

  @override
  State<NovenasScreen> createState() => _NovenasScreenState();
}

class _NovenasScreenState extends State<NovenasScreen> {
  Map<String, NovenaProgress> _progress = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final data = await NovenaStorage.loadAll();
    setState(() => _progress = data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Novenas')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: catholicNovenas.length,
        itemBuilder: (context, index) {
          final novena = catholicNovenas[index];
          final progress = _progress[novena.id];
          final completedDays = progress?.completedDays.length ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NovenaDetailScreen(novena: novena),
                  ),
                );
                _loadProgress(); // refresh on return
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: novena.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(novena.icon, color: novena.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(novena.title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(novena.subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                          if (completedDays > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: completedDays / 9,
                                      backgroundColor: theme.brightness == Brightness.dark
                                          ? Colors.white12
                                          : Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        completedDays >= 9 ? Colors.green : FidelisTheme.gold,
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  completedDays >= 9 ? 'Complete ✓' : '$completedDays/9 days',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: completedDays >= 9 ? Colors.green : FidelisTheme.gold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}