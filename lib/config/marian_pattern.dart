import 'package:flutter/material.dart';

/// Marian floral watermark background.
/// Shows a single large rose watermark image centered in the background.
/// Light mode only — dark mode gets a clean background.
class MarianBackground extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const MarianBackground({super.key, required this.child, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return child;

    return Stack(
      children: [
        // Watermark positioned in bottom-right area
        Positioned(
          right: -20,
          bottom: 100,
          child: Opacity(
            opacity: 0.15,
            child: Image.asset(
              'assets/marian_watermark.png',
              width: 280,
              height: 280,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        // Another smaller one top-left
        Positioned(
          left: -30,
          top: 60,
          child: Opacity(
            opacity: 0.08,
            child: Image.asset(
              'assets/marian_watermark.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        child,
      ],
    );
  }
}