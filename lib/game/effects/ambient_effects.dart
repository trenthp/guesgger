import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../perspective.dart';
import '../zones/zone.dart';
import '../zones/zone_manager.dart';

/// Zone-specific ambient particle effects.
class AmbientEffects extends Component {
  final PerspectiveProjection perspective;
  final ZoneManager zoneManager;
  final Random _random = Random();
  final List<_AmbientParticle> _particles = [];
  double _spawnTimer = 0;

  AmbientEffects({
    required this.perspective,
    required this.zoneManager,
  });

  @override
  int get priority => -99998;

  @override
  void update(double dt) {
    super.update(dt);

    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer = 0.05 + _random.nextDouble() * 0.1;
      _trySpawn();
    }

    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life -= dt * p.decay;
      p.rotation += p.rotSpeed * dt;
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  void _trySpawn() {
    if (_particles.length > 50) return;

    final zone = zoneManager.currentZone;
    final w = perspective.screenWidth;
    final h = perspective.screenHeight;
    final horizonY = perspective.horizonY;

    Color color;
    double size;
    double vx, vy;
    double decay;

    switch (zone.type) {
      case ZoneType.parkingLot:
        // Yellow headlight dust particles
        color = GameTheme.parkingAccent.withValues(alpha: 0.3);
        size = 1 + _random.nextDouble() * 2;
        vx = (_random.nextDouble() - 0.5) * 20;
        vy = 30 + _random.nextDouble() * 60;
        decay = 1.5;
        break;
      case ZoneType.security:
        // Blue scanner particles rising
        color = GameTheme.securityAccent.withValues(alpha: 0.4);
        size = 1 + _random.nextDouble() * 2;
        vx = (_random.nextDouble() - 0.5) * 15;
        vy = -20 - _random.nextDouble() * 40;
        decay = 2.0;
        break;
      case ZoneType.shops:
        // Warm orange sparkles
        color = GameTheme.shopsAccent.withValues(alpha: 0.35);
        size = 1.5 + _random.nextDouble() * 2;
        vx = (_random.nextDouble() - 0.5) * 30;
        vy = -10 + _random.nextDouble() * 50;
        decay = 1.8;
        break;
      case ZoneType.ticketBooths:
        // Purple ticket confetti
        color = GameTheme.ticketAccent.withValues(alpha: 0.3);
        size = 2 + _random.nextDouble() * 3;
        vx = (_random.nextDouble() - 0.5) * 25;
        vy = 20 + _random.nextDouble() * 40;
        decay = 1.2;
        break;
      case ZoneType.walkway:
        // Subtle gray wisps
        color = GameTheme.walkwayAccent.withValues(alpha: 0.2);
        size = 1 + _random.nextDouble() * 1.5;
        vx = -20 - _random.nextDouble() * 30;
        vy = (_random.nextDouble() - 0.5) * 10;
        decay = 2.5;
        break;
      case ZoneType.parkEntrance:
        // Green sparkles and gold dust
        final isGold = _random.nextBool();
        color = isGold
            ? const Color(0xFFFFD54F).withValues(alpha: 0.4)
            : GameTheme.entranceAccent.withValues(alpha: 0.3);
        size = 1.5 + _random.nextDouble() * 2.5;
        vx = (_random.nextDouble() - 0.5) * 20;
        vy = -30 - _random.nextDouble() * 40;
        decay = 1.0;
        break;
    }

    _particles.add(_AmbientParticle(
      x: _random.nextDouble() * w,
      y: horizonY + _random.nextDouble() * (h - horizonY),
      size: size,
      color: color,
      vx: vx,
      vy: vy,
      life: 1.0,
      decay: decay,
      rotation: _random.nextDouble() * pi * 2,
      rotSpeed: (_random.nextDouble() - 0.5) * 3,
    ));
  }

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      final alpha = (p.life * p.color.a / 255).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha);

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      if (p.size > 2) {
        // Draw as small diamond
        final path = Path()
          ..moveTo(0, -p.size)
          ..lineTo(p.size * 0.6, 0)
          ..lineTo(0, p.size)
          ..lineTo(-p.size * 0.6, 0)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawCircle(Offset.zero, p.size, paint);
      }

      // Subtle glow for larger particles
      if (p.size > 1.5) {
        canvas.drawCircle(
          Offset.zero,
          p.size * 2.5,
          Paint()..color = p.color.withValues(alpha: alpha * 0.15),
        );
      }

      canvas.restore();
    }
  }
}

class _AmbientParticle {
  double x, y, size, vx, vy, life, decay, rotation, rotSpeed;
  Color color;

  _AmbientParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.vx,
    required this.vy,
    required this.life,
    required this.decay,
    required this.rotation,
    required this.rotSpeed,
  });
}
