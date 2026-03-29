import 'dart:math';

import 'package:flutter/material.dart';

import '../config/theme.dart';

class GameOverScreen extends StatefulWidget {
  final int score;
  final String zoneName;
  final VoidCallback onRetry;
  final VoidCallback onMenu;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.zoneName,
    required this.onRetry,
    required this.onMenu,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _particleController;
  late AnimationController _glitchController;
  late List<_FallingEmber> _embers;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _embers = List.generate(30, (_) => _FallingEmber(_random));
  }

  @override
  void dispose() {
    _entryController.dispose();
    _particleController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return Stack(
            children: [
              // Dark dramatic gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.3),
                    radius: 1.2,
                    colors: [
                      Color(0xFF2D0A1E),
                      GameTheme.gameOverGradientTop,
                      Color(0xFF0A0000),
                    ],
                  ),
                ),
              ),
              // Falling ember particles
              CustomPaint(
                painter: _EmberPainter(
                  embers: _embers,
                  time: _particleController.value * 10,
                ),
                size: Size.infinite,
              ),
              // Red vignette
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.transparent,
                      Colors.red.withValues(alpha: 0.1),
                      Colors.red.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
              // Content
              child!,
            ],
          );
        },
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _entryController,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _entryController,
                  curve: Curves.easeOutCubic,
                )),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Skull/X icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: GameTheme.heartFull.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: GameTheme.heartFull.withValues(alpha: 0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 48,
                        color: GameTheme.heartFull,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Glitching title
                    AnimatedBuilder(
                      animation: _glitchController,
                      builder: (context, _) {
                        final glitch = sin(_glitchController.value * pi * 40);
                        final showGlitch = glitch > 0.95;
                        return Transform.translate(
                          offset: showGlitch
                              ? Offset(_random.nextDouble() * 4 - 2, 0)
                              : Offset.zero,
                          child: Text(
                            'GAME OVER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              shadows: [
                                Shadow(
                                  offset: Offset(
                                      showGlitch ? 3 : 0, 0),
                                  blurRadius: showGlitch ? 0 : 20,
                                  color: GameTheme.heartFull
                                      .withValues(alpha: 0.6),
                                ),
                                const Shadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 10,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    // Score display
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${widget.score}m',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stopped at ${widget.zoneName}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Retry button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color:
                                GameTheme.buttonPrimary.withValues(alpha: 0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: widget.onRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GameTheme.buttonPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(35),
                          ),
                          elevation: 8,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.replay_rounded, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'TRY AGAIN',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: widget.onMenu,
                      child: Text(
                        'MAIN MENU',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FallingEmber {
  double x, y, size, speed, opacity;

  _FallingEmber(Random random)
      : x = random.nextDouble(),
        y = random.nextDouble(),
        size = 1 + random.nextDouble() * 2,
        speed = 0.03 + random.nextDouble() * 0.06,
        opacity = 0.2 + random.nextDouble() * 0.4;
}

class _EmberPainter extends CustomPainter {
  final List<_FallingEmber> embers;
  final double time;

  _EmberPainter({required this.embers, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in embers) {
      final px =
          (e.x * size.width + sin(time * e.speed * 2 + e.y * 10) * 20) %
              size.width;
      final py = (e.y * size.height + time * e.speed * 40) % size.height;

      final alpha =
          (e.opacity * (0.3 + 0.7 * sin(time * 2 + e.x * 5))).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = Color.lerp(
          Colors.red,
          Colors.orange,
          sin(time + e.x * 10) * 0.5 + 0.5,
        )!
            .withValues(alpha: alpha);

      canvas.drawCircle(Offset(px, py), e.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmberPainter oldDelegate) => true;
}
