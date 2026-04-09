import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onGetStarted;

  const SplashScreen({super.key, this.onGetStarted});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          Positioned(
            left: -100,
            top: -100,
            child: _AnimatedGlow(
              color: const Color(0xFFFF8A00),
              size: 400,
              duration: 3000,
            ),
          ),
          Positioned(
            right: -150,
            bottom: -100,
            child: _AnimatedGlow(
              color: const Color(0xFFFF6A00),
              size: 500,
              duration: 4000,
            ),
          ),
          Positioned(
            right: -80,
            top: 100,
            child: _AnimatedGlow(
              color: const Color(0xFFFFAA00),
              size: 250,
              duration: 3500,
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF8A00),
                          Color(0xFFFF5000),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8A00).withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logobg.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'FOXCORE',
                    style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFF8A00).withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Built for gamers. By gamers.',
                      style: TextStyle(
                        color: Color(0xFFFF8A00),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFFFF8A00).withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: widget.onGetStarted,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'GET STARTED',
                        style: GoogleFonts.rajdhani(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedGlow extends StatefulWidget {
  final Color color;
  final double size;
  final int duration;

  const _AnimatedGlow({
    required this.color,
    required this.size,
    required this.duration,
  });

  @override
  State<_AnimatedGlow> createState() => _AnimatedGlowState();
}

class _AnimatedGlowState extends State<_AnimatedGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.duration),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withOpacity(0.3 + (_controller.value * 0.2)),
                Colors.transparent,
              ],
              radius: 0.7,
            ),
          ),
        );
      },
    );
  }
}
