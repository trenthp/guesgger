import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Enhanced screen shake, red flash, and chromatic aberration on hit.
class HitEffect extends Component {
  @override
  int get priority => 200000;
  double _shakeTimer = 0;
  double _flashAlpha = 0;
  double _shakeIntensity = 0;
  double _ringAlpha = 0;
  double _ringRadius = 0;
  final Random _random = Random();

  double get offsetX =>
      _shakeTimer > 0 ? (_random.nextDouble() - 0.5) * _shakeIntensity : 0;
  double get offsetY =>
      _shakeTimer > 0 ? (_random.nextDouble() - 0.5) * _shakeIntensity : 0;

  bool get isActive => _shakeTimer > 0 || _flashAlpha > 0;

  void trigger() {
    _shakeTimer = 0.35;
    _shakeIntensity = 10;
    _flashAlpha = 0.5;
    _ringAlpha = 0.6;
    _ringRadius = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
      _shakeIntensity *= 0.88;
    }
    if (_flashAlpha > 0) {
      _flashAlpha -= dt * 2.5;
      if (_flashAlpha < 0) _flashAlpha = 0;
    }
    if (_ringAlpha > 0) {
      _ringAlpha -= dt * 2;
      _ringRadius += dt * 800;
      if (_ringAlpha < 0) _ringAlpha = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    // Red vignette flash
    if (_flashAlpha > 0) {
      final rect = Rect.fromLTWH(0, 0, 9999, 9999);
      // Vignette: darker at edges
      final gradient = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.red.withValues(alpha: _flashAlpha * 0.5),
          Colors.red.withValues(alpha: _flashAlpha),
        ],
        stops: const [0.3, 0.7, 1.0],
      );
      canvas.drawRect(
        rect,
        Paint()
          ..shader = gradient.createShader(
            Rect.fromCenter(
              center: const Offset(200, 400),
              width: 800,
              height: 800,
            ),
          ),
      );
    }

    // Expanding ring
    if (_ringAlpha > 0) {
      canvas.drawCircle(
        const Offset(200, 400),
        _ringRadius,
        Paint()
          ..color = Colors.red.withValues(alpha: _ringAlpha * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }
}
