import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// A step-by-step litany reader with auto-scroll to keep current line visible.
/// Used for any litany prayer that has repeated invocations.
class LitanyReaderScreen extends StatefulWidget {
  final String title;
  final List<String> invocations;
  final String? closingPrayer;
  final IconData icon;

  const LitanyReaderScreen({
    super.key,
    required this.title,
    required this.invocations,
    this.closingPrayer,
    this.icon = Icons.auto_awesome,
  });

  @override
  State<LitanyReaderScreen> createState() => _LitanyReaderScreenState();
}

class _LitanyReaderScreenState extends State<LitanyReaderScreen> {
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();

  // GlobalKey per line for precise scroll positioning
  static const int _maxLines = 100;
  final List<GlobalKey> _lineKeys = List.generate(_maxLines, (_) => GlobalKey());

  bool get _isFinished => _currentIndex >= widget.invocations.length;
  bool get _isFirst => _currentIndex == 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _nextLine() {
    if (_currentIndex < widget.invocations.length) {
      setState(() => _currentIndex++);
      _scrollToLine();
    }
  }

  void _previousLine() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _scrollToLine();
    }
  }

  void _scrollToLine() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      if (_isFinished) {
        // Scroll to bottom when litany is complete
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        return;
      }

      final key = _lineKeys[_currentIndex];
      final context = key.currentContext;
      if (context == null) {
        // Fallback: scroll to approximate position
        final lineHeight = 40.0;
        final target = (_currentIndex * lineHeight) - 100;
        _scrollController.jumpTo(target.clamp(0.0, _scrollController.position.maxScrollExtent));
        return;
      }

      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final scrollableBox = _scrollController.position.context.storageContext.findRenderObject() as RenderBox;

      final offset = renderBox.localToGlobal(Offset.zero, ancestor: scrollableBox).dy;
      final currentScroll = _scrollController.offset;
      final viewportHeight = _scrollController.position.viewportDimension;

      // Position line 1/3 from top
      final targetScroll = currentScroll + offset - (viewportHeight / 3);
      final clamped = targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent);

      _scrollController.jumpTo(clamped);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _isFinished ? 1.0 : (_currentIndex + 1) / widget.invocations.length;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.brightness == Brightness.dark
                ? const Color(0xFF243447)
                : FidelisTheme.ivory,
            valueColor: const AlwaysStoppedAnimation<Color>(FidelisTheme.gold),
            minHeight: 3,
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Litany lines
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF1E2D3D)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i <= _currentIndex && i < widget.invocations.length; i++)
                          Padding(
                            key: _lineKeys[i],
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              widget.invocations[i],
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.6,
                                color: i == _currentIndex
                                    ? FidelisTheme.gold
                                    : theme.colorScheme.onSurface.withValues(alpha: i < _currentIndex ? 0.5 : 1.0),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Progress indicator
                  if (!_isFinished)
                    Text(
                      '${_currentIndex + 1} of ${widget.invocations.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),

                  // Closing prayer
                  if (_isFinished && widget.closingPrayer != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: FidelisTheme.deepRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.closingPrayer!,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF14202E)
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isFirst ? null : _previousLine,
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isFinished ? () => Navigator.of(context).pop() : _nextLine,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFinished ? FidelisTheme.gold : FidelisTheme.deepRed,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isFinished ? 'Complete' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}