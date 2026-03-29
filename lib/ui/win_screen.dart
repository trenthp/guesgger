import 'dart:math';

import 'package:flutter/material.dart';

import '../config/theme.dart';

class WinScreen extends StatefulWidget {
  final int score;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  const WinScreen({
    super.key,
    required this.score,
    required this.onPlayAgain,
    required this.onMenu,
  });

  @override
  State<WinScreen> createState() => _WinScreenState();
}

class _WinScreenState extends State<WinScreen> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _confettiController;
  late AnimationController _glowController;
  late List<_ConfettiParticle> _confetti;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _confetti = List.generate(60, (_) => _ConfettiParticle(_random));
  }

  @override
  void dispose() {
    _entryController.dispose();
    _confettiController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _confettiController,
        builder: (context, child) {
          return Stack(
            children: [
              // Rich green gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 1.2,
                    colors: [
                      Color(0xFF1A3D1A),
                      GameTheme.winGradientTop,
                      Color(0xFF0A1A0A),
                    ],
                  ),
                ),
              ),
              // Golden rays
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, _) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.5),
                        radius: 0.8 + _glowController.value * 0.2,
                        colors: [
                          const Color(0xFFFFD54F)
                              .withValues(alpha: 0.05 + _glowController.value * 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Confetti
              CustomPaint(
                painter: _ConfettiPainter(
                  confetti: _confetti,
                  time: _confettiController.value * 15,
                ),
                size: Size.infinite,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Trophy with glow
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _entryController,
                        curve: const Interval(0.0, 0.6,
                            curve: Curves.elasticOut),
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD54F).withValues(
                                    alpha: 0.2 + _glowController.value * 0.2),
                                blurRadius: 40 + _glowController.value * 20,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFD54F),
                            Color(0xFFFFA000),
                            Color(0xFFFFD54F),
                          ],
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _entryController,
                      curve: const Interval(0.2, 0.7,
                          curve: Curves.easeOutCubic),
                    )),
                    child: Column(
                      children: [
                        Text(
                          'WELCOME TO',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 18,
                            letterSpacing: 6,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFFFFD54F),
                              Colors.white,
                              Color(0xFFFFD54F),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'THE PARK!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Score card
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _entryController,
                      curve: const Interval(0.3, 0.8,
                          curve: Curves.easeOutCubic),
                    )),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.straighten_rounded,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.score}m traveled',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Through parking, security, shops & ticket booths',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Play again button
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _entryController,
                      curve: const Interval(0.5, 1.0,
                          curve: Curves.easeOutCubic),
                    )),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(35),
                            boxShadow: [
                              BoxShadow(
                                color: GameTheme.entranceAccent
                                    .withValues(alpha: 0.3),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: widget.onPlayAgain,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GameTheme.entranceAccent,
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
                                  'PLAY AGAIN',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  double x, y, size, speed, rotation, rotSpeed;
  Color color;

  _ConfettiParticle(Random random)
      : x = random.nextDouble(),
        y = random.nextDouble(),
        size = 3 + random.nextDouble() * 5,
        speed = 0.02 + random.nextDouble() * 0.04,
        rotation = random.nextDouble() * pi * 2,
        rotSpeed = (random.nextDouble() - 0.5) * 4,
        color = [
          const Color(0xFFFFD54F),
          const Color(0xFF4CAF50),
          const Color(0xFF2196F3),
          const Color(0xFFFF4081),
          const Color(0xFFFF9800),
          const Color(0xFF9C27B0),
          Colors.white,
        ][random.nextInt(7)];
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> confetti;
  final double time;

  _ConfettiPainter({required this.confetti, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in confetti) {
      final px =
          (c.x * size.width + sin(time * c.speed * 3 + c.rotation) * 40) %
              size.width;
      final py = (c.y * size.height + time * c.speed * 30) % size.height;
      final rot = c.rotation + time * c.rotSpeed;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);

      final paint = Paint()
        ..color = c.color.withValues(
            alpha: (0.6 + 0.4 * sin(time + c.x * 5)).clamp(0.0, 1.0));

      // Draw small rectangle confetti
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: c.size,
            height: c.size * 0.6,
          ),
          Radius.circular(c.size * 0.15),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
