import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import 'missal_service.dart';
import 'missal_cache.dart';
import 'usccb_service.dart';

class ReadingsScreen extends StatefulWidget {
  final DateTime? initialDate;

  const ReadingsScreen({super.key, this.initialDate});

  @override
  State<ReadingsScreen> createState() => _ReadingsScreenState();
}

class _ReadingsScreenState extends State<ReadingsScreen> {
  List<Proper>? _propers;
  UsccbReadings? _usccbReadings;
  bool _loading = true;
  String? _error;
  bool _showLatin = false;
  late DateTime _selectedDate;
  String _missal = '1962'; // '1962' or 'novus_ordo'

  @override
  void initState() {
    _selectedDate = widget.initialDate ?? DateTime.now();
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _missal = prefs.getString('missal') ?? '1962';
    });
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    try {
      if (_missal == 'novus_ordo') {
        await _loadUsccbReadings(dateStr);
      } else {
        await _loadTraditionalReadings(dateStr);
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadTraditionalReadings(String dateStr) async {
    List<Proper> propers;
    try {
      propers = await MissalService.getProper(_selectedDate);
      await MissalCache.saveProper(dateStr, propers);
    } catch (e) {
      final cached = await MissalCache.getProper(dateStr);
      if (cached != null) {
        propers = cached;
      } else {
        rethrow;
      }
    }
    setState(() {
      _propers = propers;
      _usccbReadings = null;
    });
  }

  Future<void> _loadUsccbReadings(String dateStr) async {
    UsccbReadings readings;
    try {
      readings = await UsccbService.getReadings(_selectedDate);
      readings = UsccbReadings(
        title: readings.title,
        lectionary: readings.lectionary,
        sections: readings.sections,
        date: _selectedDate,
      );
      await MissalCache.saveUsccbReadings(dateStr, readings);
    } catch (e) {
      final cached = await MissalCache.getUsccbReadings(dateStr);
      if (cached != null) {
        readings = cached;
      } else {
        rethrow;
      }
    }
    setState(() {
      _usccbReadings = readings;
      _propers = null;
    });
  }

  Future<void> _switchMissal(String missal) async {
    setState(() => _missal = missal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('missal', missal);
    _loadReadings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Mass Readings'),
        actions: [
          // Missal toggle
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Select Missal',
            onSelected: _switchMissal,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: '1962',
                child: ListTile(
                  leading: Icon(Icons.history_edu),
                  title: Text('Traditional (1962)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'novus_ordo',
                child: ListTile(
                  leading: Icon(Icons.church),
                  title: Text('Novus Ordo'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          // Latin toggle (only for 1962)
          if (_missal == '1962')
            IconButton(
              icon: Icon(_showLatin ? Icons.translate : Icons.language),
              tooltip: _showLatin ? 'Show English' : 'Show Latin',
              onPressed: () => setState(() => _showLatin = !_showLatin),
            ),
          // Date picker
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select date',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(context)
              : _missal == 'novus_ordo'
                  ? _buildNovusOrdoReadings(context)
                  : _buildTraditionalReadings(context),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: FidelisTheme.gold),
            const SizedBox(height: 16),
            Text(
              'Unable to load readings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReadings,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Traditional (1962) Readings ─────────────────────────────

  Widget _buildTraditionalReadings(BuildContext context) {
    if (_propers == null || _propers!.isEmpty) {
      return const Center(child: Text('No readings available for this date.'));
    }

    final proper = _propers!.first;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _loadReadings,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFeastCard(context, proper, isDark),
            const SizedBox(height: 16),
            _buildMissalChip(),
            const SizedBox(height: 8),
            Center(
              child: FilterChip(
                label: Text(_showLatin ? '🏛️ Latin' : '🇺🇸 English'),
                onSelected: (_) => setState(() => _showLatin = !_showLatin),
                selected: true,
              ),
            ),
            const SizedBox(height: 16),
            for (final section in proper.sections)
              _buildSectionCard(context, section, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFeastCard(BuildContext context, Proper proper, bool isDark) {
    final theme = Theme.of(context);
    final colorCode = proper.info.primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A1A3C), const Color(0xFF1A2332)]
              : [FidelisTheme.deepRed, const Color(0xFF6B2020)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(MissalService.colorValue(colorCode)),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 1),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                MissalService.colorName(colorCode),
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            proper.info.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: FidelisTheme.gold,
            ),
            textAlign: TextAlign.center,
          ),
          if (proper.info.commemorations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Commemoration: ${proper.info.commemorations.map((c) => c.title).join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _formatDate(_selectedDate),
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, ProperSection section, bool isDark) {
    final theme = Theme.of(context);

    final isKey = ['Lectio', 'Evangelium', 'Oratio'].contains(section.id);
    final isEpistle = section.id == 'Lectio';
    final isGospel = section.id == 'Evangelium';

    final text = _showLatin && section.hasLatin ? section.latin : section.english;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2D3D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isGospel
            ? Border.all(color: FidelisTheme.gold, width: 2)
            : isEpistle
                ? Border.all(color: isDark ? FidelisTheme.gold.withValues(alpha: 0.4) : FidelisTheme.deepRed.withValues(alpha: 0.3))
                : null,
        boxShadow: [
          if (isKey)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (isGospel) ...[
                  const Icon(Icons.auto_stories, size: 20, color: FidelisTheme.gold),
                  const SizedBox(width: 8),
                ] else if (isEpistle) ...[
                  Icon(Icons.menu_book, size: 20, color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed),
                  const SizedBox(width: 8),
                ],
                Text(
                  section.label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    color: isGospel
                        ? FidelisTheme.gold
                        : isEpistle
                            ? (isDark ? FidelisTheme.gold : FidelisTheme.deepRed)
                            : theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (section.hasLatin)
                  Text(
                    _showLatin ? 'LA' : 'EN',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.8,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Novus Ordo Readings ─────────────────────────────────────

  Widget _buildNovusOrdoReadings(BuildContext context) {
    final readings = _usccbReadings;
    if (readings == null) {
      return const Center(child: Text('No readings available for this date.'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _loadReadings,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNovusOrdoFeastCard(context, readings),
            const SizedBox(height: 16),
            _buildMissalChip(),
            const SizedBox(height: 16),
            for (final section in readings.sections)
              _buildNovusOrdoSectionCard(context, section, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildNovusOrdoFeastCard(BuildContext context, UsccbReadings readings) {
    final theme = Theme.of(context);
    final colorCode = readings.liturgicalColorCode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(MissalService.colorValue(colorCode)),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 1),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                MissalService.colorName(colorCode),
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            readings.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (readings.lectionary != null) ...[
            const SizedBox(height: 6),
            Text(
              'Lectionary: ${readings.lectionary}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _formatDate(_selectedDate),
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildNovusOrdoSectionCard(BuildContext context, UsccbSection section, bool isDark) {
    final theme = Theme.of(context);

    final isGospel = section.label.toLowerCase() == 'gospel';
    final isReading1 = section.label.toLowerCase() == 'reading 1';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2D3D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isGospel
            ? Border.all(color: FidelisTheme.gold, width: 2)
            : isReading1
                ? Border.all(color: isDark ? FidelisTheme.gold.withValues(alpha: 0.4) : const Color(0xFF1565C0).withValues(alpha: 0.3))
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (isGospel) ...[
                  const Icon(Icons.auto_stories, size: 20, color: FidelisTheme.gold),
                  const SizedBox(width: 8),
                ] else if (isReading1) ...[
                  Icon(Icons.menu_book, size: 20, color: isDark ? FidelisTheme.gold : const Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    section.label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      color: isGospel
                          ? FidelisTheme.gold
                          : isReading1
                              ? (isDark ? FidelisTheme.gold : const Color(0xFF1565C0))
                              : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            if (section.reference.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: FidelisTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  section.reference,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: FidelisTheme.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SelectableText(
              section.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.8,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared Widgets ──────────────────────────────────────────

  Widget _buildMissalChip() {
    return Center(
      child: FilterChip(
        label: Text(
          _missal == '1962' ? '📖 1962 Roman Missal' : '📖 Novus Ordo',
        ),
        onSelected: (_) {
          _switchMissal(_missal == '1962' ? 'novus_ordo' : '1962');
        },
        selected: true,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadReadings();
    }
  }
}