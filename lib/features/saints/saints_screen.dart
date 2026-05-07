import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../readings/missal_service.dart';

class SaintsScreen extends StatefulWidget {
  const SaintsScreen({super.key});

  @override
  State<SaintsScreen> createState() => _SaintsScreenState();
}

class _SaintsScreenState extends State<SaintsScreen> {
  List<CalendarDay>? _calendar;
  bool _loading = true;
  String? _error;
  int _year = DateTime.now().year;
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    setState(() { _loading = true; _error = null; });
    try {
      _calendar = await MissalService.getCalendar(_year);
      setState(() { _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  /// Get CalendarDay for a specific date
  CalendarDay? _getDay(DateTime date) {
    final id = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      return _calendar?.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('1962 Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Go to today',
            onPressed: () {
              setState(() {
                _year = today.year;
                _focusedMonth = DateTime(today.year, today.month, 1);
              });
              _loadCalendar();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Today's feast highlight
          if (!_loading && _error == null && _calendar != null)
            _buildTodayCard(context),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search saints and feasts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),

          // Calendar grid or search results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError(context)
                    : _searchQuery.isNotEmpty
                        ? _buildSearchResults(context)
                        : _buildCalendarGrid(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayCard(BuildContext context) {
    final today = DateTime.now();
    final todayEntry = _getDay(today);
    if (todayEntry == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorCode = todayEntry.primaryColor;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
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
                width: 14,
                height: 14,
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
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showDayDetail(context, today),
            child: Text(
              todayEntry.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: FidelisTheme.gold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (todayEntry.commemorations.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Commemorations: ${todayEntry.commemorations.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _rankName(todayEntry.rank),
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final today = DateTime.now();

    const monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Calculate grid data
    final firstDayOfMonth = _focusedMonth;
    final daysInMonth = DateTime(firstDayOfMonth.year, firstDayOfMonth.month + 1, 0).day;
    // weekday: Mon=1..Sun=7 → index 0..6
    final startWeekday = firstDayOfMonth.weekday - 1;
    final totalCells = startWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                    if (_focusedMonth.year != _year) {
                      _year = _focusedMonth.year;
                      _loadCalendar();
                    }
                  });
                },
              ),
              Text(
                '${monthNames[_focusedMonth.month]} ${_focusedMonth.year}',
                style: theme.textTheme.titleLarge?.copyWith(color: FidelisTheme.gold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                    if (_focusedMonth.year != _year) {
                      _year = _focusedMonth.year;
                      _loadCalendar();
                    }
                  });
                },
              ),
            ],
          ),
        ),

        // Day-of-week headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: dayNames.map((name) => Expanded(
              child: Center(
                child: Text(
                  name,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
                  ),
                ),
              ),
            )).toList(),
          ),
        ),

        const SizedBox(height: 4),

        // Calendar grid
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 80),
            child: Column(
              children: List.generate(rows, (row) {
                return Row(
                  children: List.generate(7, (col) {
                    final cellIndex = row * 7 + col;
                    final dayNum = cellIndex - startWeekday + 1;

                    if (dayNum < 1 || dayNum > daysInMonth) {
                      return const Expanded(child: SizedBox.shrink());
                    }

                    final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                    final dayEntry = _getDay(date);
                    final colorCode = dayEntry?.primaryColor ?? 'green';
                    final litColor = Color(MissalService.colorValue(colorCode));
                    final isHighRank = dayEntry != null && dayEntry.rank <= 2;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _showDayDetail(context, date),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isToday
                                ? (isDark ? FidelisTheme.gold.withValues(alpha: 0.2) : FidelisTheme.deepRed.withValues(alpha: 0.1))
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? Border.all(color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed, width: 2)
                                : null,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayNum.toString(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                    color: isToday
                                        ? (isDark ? FidelisTheme.gold : FidelisTheme.deepRed)
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Liturgical color dot
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: litColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? Colors.white24 : Colors.black12,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                // Rank indicator for major feasts
                                if (isHighRank) ...[
                                  const SizedBox(height: 1),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: FidelisTheme.gold,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final today = DateTime.now();

    final filtered = _calendar?.where((day) {
      if (_searchQuery.isEmpty) return true;
      return day.title.toLowerCase().contains(_searchQuery) ||
             day.commemorations.any((c) => c.toLowerCase().contains(_searchQuery));
    }).toList() ?? [];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final day = filtered[index];
        final parts = day.id.split('-');
        final dayNum = parts.length == 3 ? int.tryParse(parts[2]) ?? 0 : 0;
        final isToday = day.id == '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final colorCode = day.primaryColor;

        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        String weekday = '';
        try {
          final date = DateTime.parse(day.id);
          weekday = weekdays[date.weekday - 1];
        } catch (_) {}

        return Card(
          margin: const EdgeInsets.only(bottom: 4),
          color: isToday ? FidelisTheme.gold.withValues(alpha: 0.15) : null,
          child: ListTile(
            leading: SizedBox(
              width: 48,
              child: FittedBox(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(dayNum.toString(), style: theme.textTheme.titleMedium),
                    Text(weekday, style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    day.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    color: Color(MissalService.colorValue(colorCode)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                      width: 1,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: day.commemorations.isNotEmpty
                ? Text(
                    day.commemorations.join(', '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: _rankBadge(day.rank),
            onTap: () {
              final parts = day.id.split('-');
              if (parts.length == 3) {
                final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
                _showDayDetail(context, date);
              }
            },
          ),
        );
      },
    );
  }

  Widget _rankBadge(int rank) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String label;
    switch (rank) {
      case 1: label = 'I'; break;
      case 2: label = 'II'; break;
      case 3: label = 'III'; break;
      default: label = 'IV';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: rank <= 2
            ? (isDark ? FidelisTheme.gold : FidelisTheme.deepRed)
            : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: rank <= 2 ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
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
            Text('Unable to load calendar', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Check your connection and try again.'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadCalendar, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  String _rankName(int rank) {
    switch (rank) {
      case 1: return '1st Class Feast';
      case 2: return '2nd Class Feast';
      case 3: return '3rd Class Feast / Greater Commemoration';
      default: return 'Feria / Commemoration';
    }
  }

  void _showDayDetail(BuildContext context, DateTime date) {
    final day = _getDay(date);
    if (day == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available for this date')),
      );
      return;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorCode = day.primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.2,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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

              // Date header
              Row(
                children: [
                  Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: Color(MissalService.colorValue(colorCode)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${date.month == 1 ? 'Jan' : date.month == 2 ? 'Feb' : date.month == 3 ? 'Mar' : date.month == 4 ? 'Apr' : date.month == 5 ? 'May' : date.month == 6 ? 'Jun' : date.month == 7 ? 'Jul' : date.month == 8 ? 'Aug' : date.month == 9 ? 'Sep' : date.month == 10 ? 'Oct' : date.month == 11 ? 'Nov' : 'Dec'} ${date.day}, ${date.year}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        Text(
                          day.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Info rows
              _infoRow('Rank', _rankName(day.rank)),
              _infoRow('Color', MissalService.colorName(colorCode)),
              if (day.commemorations.isNotEmpty)
                _infoRow('Commemorations', day.commemorations.join(', ')),
              if (day.tags.isNotEmpty)
                _infoRow('Season', day.tags.join(', ')),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/readings', arguments: date);
                      },
                      icon: const Icon(Icons.menu_book),
                      label: const Text('Mass Readings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}