import 'dart:math';

import 'package:flutter/material.dart';

import '../config/theme.dart';

class MainMenuScreen extends StatefulWidget {
  final VoidCallback onStart;

  const MainMenuScreen({super.key, required this.onStart});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _pulseController;
  late AnimationController _titleController;
  late List<_FloatingParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _particles = List.generate(40, (_) => _FloatingParticle(_random));
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Scale the hero between ~0.55x on tiny phones and 1.0x at tablet width.
    final heroScale = (screenWidth / 600).clamp(0.55, 1.0);
    final iconSize = 64.0 * heroScale;
    final titleFontSize = 64.0 * heroScale;
    final titleLetterSpacing = 12.0 * heroScale;
    final taglineFontSize = (14.0 * heroScale).clamp(11.0, 14.0);
    // Cap the hero block so the title can't grow past the viewport even at
    // max scale, and FittedBox can scale it down further when needed.
    final heroMaxWidth = screenWidth - 32;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Stack(
            children: [
              // Animated gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      GameTheme.menuGradientTop,
                      GameTheme.menuGradientMid,
                      GameTheme.menuGradientBottom,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Floating particles
              CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  time: _bgController.value * 20,
                ),
                size: Size.infinite,
              ),
              // Horizon glow
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 200,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        GameTheme.horizonGlow.withValues(alpha: 0.08),
                        GameTheme.buttonPrimary.withValues(alpha: 0.05),
                      ],
                    ),
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated title
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _titleController,
                      curve: Curves.elasticOut,
                    )),
                    child: FadeTransition(
                      opacity: _titleController,
                      child: Column(
                        children: [
                          // Icon
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                GameTheme.buttonPrimary,
                                GameTheme.hudAccent,
                              ],
                            ).createShader(bounds),
                            child: Icon(
                              Icons.attractions,
                              size: iconSize,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16 * heroScale),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: heroMaxWidth,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    GameTheme.buttonPrimary,
                                    Color(0xFFFFEB3B),
                                    GameTheme.buttonPrimary,
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  'GUESGGER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: titleLetterSpacing,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Navigate from the parking lot to the park entrance!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: taglineFontSize,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 50 * heroScale),
                  // Pulsing start button
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final pulse = _pulseController.value;
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: GameTheme.buttonPrimaryGlow
                                  .withValues(alpha: 0.3 + pulse * 0.3),
                              blurRadius: 20 + pulse * 15,
                              spreadRadius: pulse * 5,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: ElevatedButton(
                      onPressed: widget.onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameTheme.buttonPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 56, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                        elevation: 12,
                        shadowColor: GameTheme.buttonPrimaryGlow,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'START',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Controls card
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'CONTROLS',
                          style: TextStyle(
                            color: GameTheme.hudAccent.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ControlHint(
                                icon: Icons.arrow_back_rounded,
                                label: 'Left'),
                            SizedBox(width: 20),
                            _ControlHint(
                                icon: Icons.arrow_upward_rounded,
                                label: 'Jump'),
                            SizedBox(width: 20),
                            _ControlHint(
                                icon: Icons.arrow_forward_rounded,
                                label: 'Right'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Arrow Keys  /  WASD  /  Swipe',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 11,
                            letterSpacing: 1,
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

class _ControlHint extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ControlHint({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Icon(icon, color: Colors.white70, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FloatingParticle {
  double x, y, size, speed, opacity;
  Color color;

  _FloatingParticle(Random random)
      : x = random.nextDouble(),
        y = random.nextDouble(),
        size = 1 + random.nextDouble() * 3,
        speed = 0.02 + random.nextDouble() * 0.05,
        opacity = 0.1 + random.nextDouble() * 0.3,
        color = [
          GameTheme.hudAccent,
          GameTheme.buttonPrimary,
          Colors.white,
          GameTheme.horizonGlow,
        ][random.nextInt(4)];
}

class _ParticlePainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final double time;

  _ParticlePainter({required this.particles, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final px = (p.x * size.width + sin(time * p.speed * 3) * 30) %
          size.width;
      final py = (p.y * size.height - time * p.speed * 20) %
          size.height;

      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity * (0.5 + 0.5 * sin(time + p.x * 10)));
      canvas.drawCircle(Offset(px, py), p.size, paint);

      // Subtle glow
      if (p.size > 2) {
        canvas.drawCircle(
          Offset(px, py),
          p.size * 3,
          Paint()..color = p.color.withValues(alpha: p.opacity * 0.1),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
