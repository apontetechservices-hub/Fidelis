import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'features/rosary/rosary_screen.dart';
import 'features/rosary/rosary_prayer_screen.dart';
import 'features/readings/readings_screen.dart';
import 'features/readings/missal_service.dart';
import 'features/readings/missal_cache.dart';
import 'features/saints/saints_screen.dart';
import 'features/novenas/novenas_screen.dart';
import 'features/prayers/prayers_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/chaplet/chaplet_list_screen.dart';
import 'features/stations/stations_screen.dart';
import 'features/readings/reflection_service.dart';
import 'features/readings/reflection_screen.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  CalendarDay? _todayFeast;
  bool _loadingFeast = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTodayFeast();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadTodayFeast() async {
    try {
      final now = DateTime.now();
      final calendar = (await MissalCache.getCalendar(now.year)) ?? await MissalService.getCalendar(now.year);
      await MissalCache.saveCalendar(now.year, calendar);
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      for (final day in calendar) {
        if (day.id == dateStr) {
          setState(() { _todayFeast = day; _loadingFeast = false; });
          return;
        }
      }
    } catch (_) {}
    setState(() { _loadingFeast = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = [
      _DashboardPage(
        todayFeast: _todayFeast,
        loadingFeast: _loadingFeast,
        onTabChange: (index) => setState(() => _currentIndex = index),
      ),
      const RosaryScreen(),
      const ReadingsScreen(),
      const PrayersScreen(),
      const SaintsScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // On non-home tabs, go back to home
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }
        // On home tab, confirm exit
        _confirmExit(context);
      },
      child: Scaffold(
        body: pages[_currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: isDark ? const Color(0xFF14202E) : FidelisTheme.rosePink,
          indicatorColor: isDark ? FidelisTheme.gold.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(icon: Icon(Icons.home, color: isDark ? FidelisTheme.gold : Colors.white), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.auto_awesome, color: isDark ? FidelisTheme.gold : Colors.white), label: 'Rosary'),
            NavigationDestination(icon: Icon(Icons.menu_book, color: isDark ? FidelisTheme.gold : Colors.white), label: 'Readings'),
            NavigationDestination(icon: Icon(Icons.church, color: isDark ? FidelisTheme.gold : Colors.white), label: 'Prayers'),
            NavigationDestination(icon: Icon(Icons.calendar_month, color: isDark ? FidelisTheme.gold : Colors.white), label: 'Calendar'),
          ],
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Fidelis?'),
        content: const Text('Are you sure you want to close the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

class _DashboardPage extends StatefulWidget {
  final CalendarDay? todayFeast;
  final bool loadingFeast;
  final ValueChanged<int> onTabChange;

  const _DashboardPage({
    this.todayFeast,
    this.loadingFeast = true,
    required this.onTabChange,
  });

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  DailyReflection? _reflection;
  bool _loadingReflection = true;

  @override
  void initState() {
    super.initState();
    _loadReflection();
  }

  Future<void> _loadReflection() async {
    try {
      final r = await ReflectionService.getTodayReflection();
      if (mounted) setState(() { _reflection = r; _loadingReflection = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingReflection = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final todayFeast = widget.todayFeast;
    final loadingFeast = widget.loadingFeast;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Fidelis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/marian_watermark.png'),
            repeat: ImageRepeat.repeat,
            opacity: 1.0,
            scale: 3.5,
            filterQuality: FilterQuality.medium,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Today's feast card
            _buildFeastCard(context, todayFeast, loadingFeast),
            const SizedBox(height: 20),

            // Quick actions
            Text('Quick Actions', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _QuickAction(
                    icon: Icons.wb_twilight,
                    label: hour < 18 ? 'Morning Prayer' : 'Evening Prayer',
                    color: hour < 18 ? FidelisTheme.gold : const Color(0xFF7E57C2),
                    onTap: () => PrayersScreen.openPrayerByName(context, hour < 18 ? 'Short Morning Prayer' : 'Short Evening Prayer'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickAction(
                    icon: Icons.local_florist,
                    label: 'Novenas',
                    color: const Color(0xFFEC407A),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NovenasScreen())),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _QuickAction(
                    icon: Icons.favorite_border,
                    label: 'More Chaplets',
                    color: const Color(0xFFE57373),
                    onTap: () => _startChapletList(context),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickAction(
                    icon: Icons.menu_book_outlined,
                    label: 'About the Rosary',
                    color: Theme.of(context).brightness == Brightness.dark ? FidelisTheme.gold : FidelisTheme.deepRed,
                    onTap: () => _showRosaryGuide(context),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _QuickActionWide(
              icon: Icons.church,
              label: 'Stations of the Cross',
              color: FidelisTheme.deepPurple,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StationsScreen())),
            ),
            const SizedBox(height: 24),

            // Today's rosary — full-width tappable card
            _buildMysteryCard(context),
            const SizedBox(height: 20),

            // Daily Gospel reflection
            _buildDailyReflectionCard(context),
            const SizedBox(height: 20),

            // Liturgy of the Hours — coming soon
            _buildLiturgyOfTheHoursCard(context),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildFeastCard(BuildContext context, CalendarDay? todayFeast, bool loadingFeast) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (loadingFeast) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark ? [const Color(0xFF2A1A3C), const Color(0xFF1A2332)] : [FidelisTheme.rosePink, FidelisTheme.lightBlue],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator(color: FidelisTheme.gold)),
      );
    }

    final feast = todayFeast;
    final colorCode = feast?.primaryColor ?? 'w';

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReadingsScreen())),
      borderRadius: BorderRadius.circular(16),
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF2A1A3C), const Color(0xFF1A2332)] : [FidelisTheme.rosePink, FidelisTheme.lightBlue],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: Color(MissalService.colorValue(colorCode)),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 1),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Today — ${MissalService.colorName(colorCode)}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            feast?.title ?? 'Fidelis',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: isDark ? FidelisTheme.gold : const Color(0xFFB5335E),
            ),
            textAlign: TextAlign.center,
          ),
          if (feast?.commemorations.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              feast!.commemorations.join(', '),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
            const SizedBox(height: 4),
            Icon(Icons.touch_app, size: 16, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildMysteryCard(BuildContext context) {
    final theme = Theme.of(context);
    final day = DateTime.now().weekday;
    final (mystery, emoji, mysteryType) = switch (day) {
      1 => ('Joyful Mysteries', '🌹', AppConstants.joyfulMysteries),
      2 => ('Sorrowful Mysteries', '✝️', AppConstants.sorrowfulMysteries),
      3 => ('Glorious Mysteries', '👑', AppConstants.gloriousMysteries),
      4 => ('Joyful Mysteries', '🌹', AppConstants.joyfulMysteries), // Traditional Thursday
      5 => ('Sorrowful Mysteries', '✝️', AppConstants.sorrowfulMysteries),
      6 => ('Joyful Mysteries', '🌹', AppConstants.joyfulMysteries),
      7 => ('Glorious Mysteries', '👑', AppConstants.gloriousMysteries),
      _ => ('Joyful Mysteries', '🌹', AppConstants.joyfulMysteries),
    };

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RosaryPrayerScreen(
                mysteryType: mysteryType,
                includeLuminous: false,
                isForDead: false,
                language: AppConstants.langEnglish,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pray Today\'s Rosary',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark ? FidelisTheme.gold : FidelisTheme.deepRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mystery,
                      style: theme.textTheme.bodyLarge?.copyWith(color: FidelisTheme.gold),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_arrow, size: 32, color: Theme.of(context).brightness == Brightness.dark ? FidelisTheme.gold : FidelisTheme.deepRed),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiturgyOfTheHoursCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Liturgy of the Hours — coming in a future update!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text('🕯️', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liturgy of the Hours',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coming Soon',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: FidelisTheme.gold.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.hourglass_top, size: 28, color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyReflectionCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loadingReflection) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily Reflection', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
      );
    }

    if (_reflection == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily Reflection', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Unable to load today\'s reflection. Check your connection and try again.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final r = _reflection!;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReflectionScreen(reflection: r)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_stories, size: 20,
                    color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Daily Reflection', style: theme.textTheme.titleMedium),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.white54),
                ],
              ),
              const SizedBox(height: 8),
              if (r.feastDay.isNotEmpty)
                Text(r.feastDay,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              if (r.feastDay.isNotEmpty) const SizedBox(height: 6),
              if (r.gospelVerse.isNotEmpty)
                Text(r.gospelVerse,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
                  ),
                ),
              if (r.title.isNotEmpty && r.title != r.gospelVerse) ...[
                const SizedBox(height: 4),
                Text(r.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _startChapletList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChapletListScreen()),
    );
  }

  void _showRosaryGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '📿 The Holy Rosary',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: FidelisTheme.gold),
              ),
              const SizedBox(height: 16),
              Text(
                'The Rosary is a meditative prayer honoring the Blessed Virgin Mary. '
                'It combines vocal prayer with meditation on the life of Christ and His Mother.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8),
              ),
              const SizedBox(height: 16),
              _guideSection(context, 'How to Pray', [
                '1. Make the Sign of the Cross and pray the Apostles\' Creed',
                '2. Pray the Our Father',
                '3. Pray 3 Hail Marys (for faith, hope, and charity)',
                '4. Pray the Glory Be',
                '5. For each decade:',
                '   • Announce the mystery and meditate on it',
                '   • Pray the Our Father',
                '   • Pray 10 Hail Marys',
                '   • Pray the Glory Be and Fatima Prayer',
                '6. After 5 decades: Hail Holy Queen',
                '7. Pray the Litany of Loreto',
                '8. Concluding prayers',
              ]),
              const SizedBox(height: 12),
              _guideSection(context, 'Mystery Schedule (Traditional)', [
                'Monday — Joyful Mysteries',
                'Tuesday — Sorrowful Mysteries',
                'Wednesday — Glorious Mysteries',
                'Thursday — Joyful Mysteries',
                'Friday — Sorrowful Mysteries',
                'Saturday — Joyful Mysteries',
                'Sunday — Glorious Mysteries',
              ]),
              const SizedBox(height: 12),
              _guideSection(context, 'Mystery Schedule (Novus Ordo)', [
                'Monday — Joyful Mysteries',
                'Tuesday — Sorrowful Mysteries',
                'Wednesday — Glorious Mysteries',
                'Thursday — Luminous Mysteries',
                'Friday — Sorrowful Mysteries',
                'Saturday — Joyful Mysteries',
                'Sunday — Glorious Mysteries',
              ]),
              const SizedBox(height: 12),
              _guideSection(context, 'The 15 Promises of Mary', [
                'The Blessed Virgin Mary made 15 promises to those who faithfully pray the Rosary, '
                'as revealed to St. Dominic and Blessed Alan de la Roche. Among them:',
                '',
                '• I promise my special protection and the greatest graces to all who pray the Rosary.',
                '• The Rosary shall be a powerful armor against hell; it will destroy vice, decrease sin, and defeat heresies.',
                '• Those who pray the Rosary shall never be conquered by misfortune.',
                '• Whoever recites the Rosary devoutly shall never perish.',
                '• I have obtained from my Divine Son that those who promote the Rosary shall have the intercession of the entire heavenly court during their life and at the hour of death.',
              ]),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onTabChange(1);
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Go to Rosary'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark ? FidelisTheme.gold : FidelisTheme.deepRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guideSection(BuildContext context, String title, List<String> lines) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark ? FidelisTheme.gold : FidelisTheme.deepRed,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
      ],
    );
  }
}

class _QuickActionWide extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionWide({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                size: 24,
                color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}