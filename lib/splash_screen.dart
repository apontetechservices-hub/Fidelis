import 'package:flutter/material.dart';
import 'dart:async';
import '../config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _iconScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.85,
            colors: [
              Color(0xFFF0E6F6), // Very light lavender center
              Color(0xFFD4B8E8), // Soft purple
              Color(0xFFA87FC7), // Medium purple
              Color(0xFF6A4A8E), // Deep purple edge
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title with calligraphic F
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Big calligraphic F in Great Vibes
                    Text(
                      'F',
                      style: TextStyle(
                        fontFamily: 'GreatVibes',
                        fontSize: 72,
                        color: const Color(0xFF2A1A0A), // Rich dark brown
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            offset: const Offset(1, 2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    // Rest of "idelis" in Cinzel Decorative
                    Text(
                      'idelis',
                      style: TextStyle(
                        fontFamily: 'CinzelDecorative',
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2A1A0A),
                        height: 1.1,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            offset: const Offset(1, 2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                'Catholic Prayer Companion',
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF4A3A2A).withValues(alpha: 0.7),
                  letterSpacing: 1.5,
                ),
              ),

              const Spacer(),

              // Marian icon - centered, ~45% of screen width
              ScaleTransition(
                scale: _iconScale,
                child: Container(
                  width: screenWidth * 0.45,
                  height: screenWidth * 0.45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 25,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/app_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Loading indicator
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF2A1A0A).withValues(alpha: 0.35),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}