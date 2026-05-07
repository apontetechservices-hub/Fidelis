import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/notification_service.dart';
import 'novena_data.dart';
import 'novena_storage.dart';

class NovenaDetailScreen extends StatefulWidget {
  final Novena novena;

  const NovenaDetailScreen({super.key, required this.novena});

  @override
  State<NovenaDetailScreen> createState() => _NovenaDetailScreenState();
}

class _NovenaDetailScreenState extends State<NovenaDetailScreen> {
  NovenaProgress? _progress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final all = await NovenaStorage.loadAll();
    setState(() {
      _progress = all[widget.novena.id];
      _loading = false;
    });
  }

  Future<void> _startNovena() async {
    final now = DateTime.now();
    final progress = NovenaProgress(
      novenaId: widget.novena.id,
      startDate: now,
      currentDay: 1,
      completedDays: {},
    );
    await NovenaStorage.save(progress);
    setState(() => _progress = progress);
  }

  Future<void> _completeDay(int day) async {
    if (_progress == null) return;
    final updated = NovenaProgress(
      novenaId: _progress!.novenaId,
      startDate: _progress!.startDate,
      currentDay: day < 9 ? day + 1 : _progress!.currentDay,
      completedDays: {..._progress!.completedDays, day},
      notificationEnabled: _progress!.notificationEnabled,
      notificationHour: _progress!.notificationHour,
      notificationMinute: _progress!.notificationMinute,
    );
    await NovenaStorage.save(updated);

    if (updated.completedDays.length >= 9) {
      // Cancel notification if novena is complete
      await _cancelNotification();
    }

    setState(() => _progress = updated);
  }

  Future<void> _undoDay(int day) async {
    if (_progress == null) return;
    final newCompleted = {..._progress!.completedDays}..remove(day);
    final updated = NovenaProgress(
      novenaId: _progress!.novenaId,
      startDate: _progress!.startDate,
      currentDay: day,
      completedDays: newCompleted,
      notificationEnabled: _progress!.notificationEnabled,
      notificationHour: _progress!.notificationHour,
      notificationMinute: _progress!.notificationMinute,
    );
    await NovenaStorage.save(updated);
    setState(() => _progress = updated);
  }

  Future<void> _resetNovena() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Novena?'),
        content: const Text('This will clear all your progress. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: FidelisTheme.deepRed),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _cancelNotification();
    await NovenaStorage.remove(widget.novena.id);
    setState(() => _progress = null);
  }

  Future<void> _toggleNotification(bool enabled) async {
    if (_progress == null) return;

    if (enabled) {
      // Request notification permission and schedule
      await NotificationService.initialize();
    }

    final updated = NovenaProgress(
      novenaId: _progress!.novenaId,
      startDate: _progress!.startDate,
      currentDay: _progress!.currentDay,
      completedDays: _progress!.completedDays,
      notificationEnabled: enabled,
      notificationHour: _progress!.notificationHour,
      notificationMinute: _progress!.notificationMinute,
    );
    await NovenaStorage.save(updated);

    if (enabled) {
      await _scheduleNotification(updated);
    } else {
      await _cancelNotification();
    }

    setState(() => _progress = updated);
  }

  Future<void> _updateNotificationTime(TimeOfDay time) async {
    if (_progress == null) return;
    final updated = NovenaProgress(
      novenaId: _progress!.novenaId,
      startDate: _progress!.startDate,
      currentDay: _progress!.currentDay,
      completedDays: _progress!.completedDays,
      notificationEnabled: _progress!.notificationEnabled,
      notificationHour: time.hour,
      notificationMinute: time.minute,
    );
    await NovenaStorage.save(updated);

    if (updated.notificationEnabled) {
      await _scheduleNotification(updated);
    }

    setState(() => _progress = updated);
  }

  Future<void> _scheduleNotification(NovenaProgress progress) async {
    // Use a unique ID based on novena hash for notification IDs (offset from 100)
    final notifId = widget.novena.id.hashCode.abs() % 1000 + 100;
    final daysRemaining = 9 - progress.completedDays.length;
    if (daysRemaining <= 0) return;

    await NotificationService.scheduleNovenaReminder(
      id: notifId,
      novenaTitle: widget.novena.title,
      day: progress.currentDay,
      hour: progress.notificationHour,
      minute: progress.notificationMinute,
    );
  }

  Future<void> _cancelNotification() async {
    final notifId = widget.novena.id.hashCode.abs() % 1000 + 100;
    await NotificationService.cancelNotification(notifId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.novena.title),
        actions: [
          if (_progress != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetNovena,
              tooltip: 'Reset novena',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: widget.novena.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(widget.novena.icon, size: 32, color: widget.novena.color),
                          ),
                          const SizedBox(height: 12),
                          Text(widget.novena.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(widget.novena.subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.novena.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(widget.novena.startDateNote,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: widget.novena.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress or Start button
                  if (_progress == null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startNovena,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Begin This Novena'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    // Progress bar
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Your Progress',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                Text(
                                  _progress!.completedDays.length >= 9 ? 'Complete ✓' : '${_progress!.completedDays.length}/9 days',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: _progress!.completedDays.length >= 9 ? Colors.green : FidelisTheme.gold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: _progress!.completedDays.length / 9,
                                backgroundColor: isDark ? Colors.white12 : Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _progress!.completedDays.length >= 9 ? Colors.green : FidelisTheme.gold,
                                ),
                                minHeight: 10,
                              ),
                            ),
                            if (_progress!.completedDays.length < 9) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Started ${_formatDate(_progress!.startDate)} • Day ${_progress!.currentDay} today',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Notification toggle
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Daily Reminder', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                Switch(
                                  value: _progress!.notificationEnabled,
                                  onChanged: _progress!.completedDays.length >= 9 ? null : _toggleNotification,
                                  activeColor: FidelisTheme.gold,
                                ),
                              ],
                            ),
                            if (_progress!.notificationEnabled) ...[
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay(
                                      hour: _progress!.notificationHour,
                                      minute: _progress!.notificationMinute,
                                    ),
                                  );
                                  if (time != null) _updateNotificationTime(time);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Remind at ${_formatTime(_progress!.notificationHour, _progress!.notificationMinute)}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.edit, size: 16, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Day-by-day prayers
                  Text('Daily Prayers', style: theme.textTheme.titleLarge?.copyWith(
                    color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
                    fontWeight: FontWeight.bold,
                  )),
                  const SizedBox(height: 12),

                  ...List.generate(9, (index) {
                    final day = index + 1;
                    final isCompleted = _progress?.completedDays.contains(day) ?? false;
                    final isCurrent = _progress?.currentDay == day && !isCompleted;
                    final canMark = _progress != null && (isCurrent || isCompleted);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isCompleted
                          ? (isDark ? Colors.green.withOpacity(0.1) : Colors.green.withOpacity(0.05))
                          : isCurrent
                              ? (isDark ? FidelisTheme.gold.withOpacity(0.1) : FidelisTheme.gold.withOpacity(0.05))
                              : null,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showDayPrayer(context, day),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: canMark && !isCompleted ? () => _completeDay(day) : (isCompleted ? () => _undoDay(day) : null),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCompleted
                                        ? Colors.green
                                        : isCurrent
                                            ? FidelisTheme.gold
                                            : (isDark ? Colors.white12 : Colors.grey[300]),
                                  ),
                                  child: isCompleted
                                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                                      : isCurrent
                                          ? const Icon(Icons.play_arrow, size: 18, color: Colors.white)
                                          : Center(child: Text('$day', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey))),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Day $day',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: isCurrent || isCompleted ? FontWeight.w600 : FontWeight.normal,
                                    color: _progress == null
                                        ? theme.hintColor
                                        : isCompleted
                                            ? Colors.green
                                            : isCurrent
                                                ? FidelisTheme.gold
                                                : null,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 18),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  void _showDayPrayer(BuildContext context, int day) {
    final prayer = widget.novena.dayPrayers[day - 1];
    final isCompleted = _progress?.completedDays.contains(day) ?? false;
    final isCurrent = _progress?.currentDay == day && !isCompleted;
    final canMark = _progress != null && (isCurrent || isCompleted);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Day $day of 9',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).hintColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(widget.novena.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark ? FidelisTheme.gold : FidelisTheme.deepRed,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(prayer,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8, fontSize: 16),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 32),
                if (canMark && !isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _completeDay(day);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text('Mark Day $day Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                if (isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _undoDay(day);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.undo),
                      label: Text('Undo Day $day'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }
}