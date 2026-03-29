import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../perspective.dart';

/// Enhanced speed lines with glow and varying width.
class SpeedLines extends Component {
  final PerspectiveProjection perspective;
  final double Function() getSpeed;
  final Random _random = Random();
  final List<_SpeedLine> _lines = [];

  SpeedLines({required this.perspective, required this.getSpeed});

  @override
  int get priority => -99999;

  @override
  void update(double dt) {
    super.update(dt);
    final speed = getSpeed();
    final spawnRate = (speed / 8).clamp(0, 8).toDouble();

    for (int i = 0; i < spawnRate.toInt(); i++) {
      if (_random.nextDouble() < 0.4) {
        final centerX = perspective.screenWidth / 2;
        final centerY = perspective.horizonY;

        // Spawn from center (vanishing point) and move outward
        final angle = _random.nextDouble() * pi * 2;
        final startR = 20 + _random.nextDouble() * 50;

        _lines.add(_SpeedLine(
          x: centerX + cos(angle) * startR,
          y: centerY + sin(angle) * startR * 0.6,
          angle: angle,
          length: 8 + _random.nextDouble() * 25,
          speed: 150 + _random.nextDouble() * 350,
          alpha: 0.05 + _random.nextDouble() * 0.15,
          width: 0.5 + _random.nextDouble() * 1.5,
        ));
      }
    }

    for (final line in _lines) {
      line.x += cos(line.angle) * line.speed * dt;
      line.y += sin(line.angle) * line.speed * dt * 0.6;
      line.alpha -= dt * 1.5;
      line.length += line.speed * dt * 0.1;
    }
    _lines.removeWhere((l) =>
        l.x < -50 ||
        l.x > perspective.screenWidth + 50 ||
        l.y > perspective.screenHeight + 50 ||
        l.alpha <= 0);
  }

  @override
  void render(Canvas canvas) {
    for (final line in _lines) {
      final endX = line.x + cos(line.angle) * line.length;
      final endY = line.y + sin(line.angle) * line.length * 0.6;

      // Main line
      canvas.drawLine(
        Offset(line.x, line.y),
        Offset(endX, endY),
        Paint()
          ..color = Colors.white
              .withValues(alpha: line.alpha.clamp(0.0, 1.0))
          ..strokeWidth = line.width
          ..strokeCap = StrokeCap.round,
      );

      // Glow
      if (line.width > 1.0) {
        canvas.drawLine(
          Offset(line.x, line.y),
          Offset(endX, endY),
          Paint()
            ..color = GameTheme.hudAccent
                .withValues(alpha: (line.alpha * 0.3).clamp(0.0, 1.0))
            ..strokeWidth = line.width * 3
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
  }
}

class _SpeedLine {
  double x;
  double y;
  double angle;
  double length;
  double speed;
  double alpha;
  double width;

  _SpeedLine({
    required this.x,
    required this.y,
    required this.angle,
    required this.length,
    required this.speed,
    required this.alpha,
    required this.width,
  });
}
