import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../config/game_config.dart';
import '../../config/theme.dart';
import '../perspective.dart';
import '../sprites/sprite_manager.dart';

class Player extends Component {
  final PerspectiveProjection perspective;
  final SpriteManager? spriteManager;

  @override
  int get priority => 100000;

  int currentLane = 0; // -1, 0, 1
  int _targetLane = 0;
  double _laneTransition = 0;
  double _worldX = 0;

  bool isJumping = false;
  double _jumpTimer = 0;
  double _jumpHeight = 0;

  bool isInvulnerable = false;
  bool isStunned = false;
  double _flashTimer = 0;
  double _runTimer = 0;

  // Trail history for motion effect
  final List<_TrailPoint> _trail = [];
  double _trailTimer = 0;

  Player({required this.perspective, this.spriteManager});

  double get worldX => _worldX;
  double get jumpHeight => _jumpHeight;

  void moveLane(int direction) {
    final newLane = (currentLane + direction).clamp(-1, 1);
    if (newLane != currentLane) {
      _targetLane = newLane;
      _laneTransition = 0;
    }
  }

  void jump() {
    if (!isJumping) {
      isJumping = true;
      _jumpTimer = 0;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _runTimer += dt;

    // Lane switching interpolation
    if (currentLane != _targetLane) {
      _laneTransition += dt / GameConfig.laneSwitchDuration;
      if (_laneTransition >= 1.0) {
        _laneTransition = 0;
        currentLane = _targetLane;
      }
    }

    // Calculate world X from lane
    final currentX = currentLane * GameConfig.laneWidth;
    final targetX = _targetLane * GameConfig.laneWidth;
    if (currentLane != _targetLane) {
      final t = Curves.easeOut.transform(_laneTransition.clamp(0.0, 1.0));
      _worldX = currentX + (targetX - currentX) * t;
    } else {
      _worldX = currentX;
    }

    // Jump animation
    if (isJumping) {
      _jumpTimer += dt;
      final t = _jumpTimer / GameConfig.jumpDuration;
      if (t >= 1.0) {
        isJumping = false;
        _jumpTimer = 0;
        _jumpHeight = 0;
      } else {
        _jumpHeight = sin(t * pi) * GameConfig.jumpHeight;
      }
    }

    // Flash timer for invulnerability
    if (isInvulnerable) {
      _flashTimer += dt * 8;
    } else {
      _flashTimer = 0;
    }

    // Update trail
    _trailTimer += dt;
    if (_trailTimer > 0.03) {
      _trailTimer = 0;
      final projected = perspective.project(
        _worldX,
        _jumpHeight,
        GameConfig.playerWorldZ,
      );
      if (projected != null) {
        _trail.add(_TrailPoint(
          x: projected.x,
          y: projected.y,
          life: 1.0,
        ));
      }
    }
    for (final t in _trail) {
      t.life -= dt * 4;
    }
    _trail.removeWhere((t) => t.life <= 0);
  }

  @override
  void render(Canvas canvas) {
    // Skip rendering every other "frame" when invulnerable (but not during stun - show solidly)
    if (isInvulnerable && !isStunned && (sin(_flashTimer * pi) > 0.5)) {
      return;
    }

    final projected = perspective.project(
      _worldX,
      _jumpHeight,
      GameConfig.playerWorldZ,
    );
    if (projected == null) return;

    final scale = projected.scale;
    final cx = projected.x;
    final baseY = projected.y;
    final s = scale * 0.08;

    // Render trail
    _renderTrail(canvas, s);

    // Draw shadow on ground
    if (isJumping) {
      final shadowProjected = perspective.project(
        _worldX,
        0,
        GameConfig.playerWorldZ,
      );
      if (shadowProjected != null) {
        final shadowScale = 1.0 - (_jumpHeight / GameConfig.jumpHeight) * 0.3;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(shadowProjected.x, shadowProjected.y),
            width: 22 * s * shadowScale,
            height: 6 * s * shadowScale,
          ),
          Paint()..color = Colors.black.withValues(alpha: 0.4),
        );
      }
    }

    // Try sprite rendering
    if (_tryRenderSprite(canvas, cx, baseY, s)) {
      return;
    }

    // Fallback: procedural rendering
    // Running bob animation
    final runBob = sin(_runTimer * 12) * 1.5 * s;
    final armSwing = sin(_runTimer * 12) * 0.3;

    final bodyHeight = 28 * s;
    final bodyWidth = 14 * s;
    final headRadius = 7 * s;
    final legLength = 10 * s;
    final legWidth = 4 * s;
    final armLength = 14 * s;
    final armWidth = 3.5 * s;

    final adjustedBaseY = baseY + runBob;

    // Legs with walk cycle
    final legSwing = sin(_runTimer * 12) * legLength * 0.35;
    final legPaint = Paint()..color = GameTheme.playerLegs;

    // Left leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(
              cx - bodyWidth * 0.2, adjustedBaseY - legLength / 2 + legSwing),
          width: legWidth,
          height: legLength,
        ),
        Radius.circular(2 * s),
      ),
      legPaint,
    );
    // Right leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(
              cx + bodyWidth * 0.2, adjustedBaseY - legLength / 2 - legSwing),
          width: legWidth,
          height: legLength,
        ),
        Radius.circular(2 * s),
      ),
      legPaint,
    );

    // Body (torso)
    final bodyTop = adjustedBaseY - legLength - bodyHeight;

    // Backpack (behind body)
    final backpackPaint = Paint()..color = GameTheme.playerBackpack;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - bodyWidth * 0.05,
          bodyTop + bodyHeight * 0.15,
          bodyWidth * 0.55,
          bodyHeight * 0.6,
        ),
        Radius.circular(3 * s),
      ),
      backpackPaint,
    );
    // Backpack strap
    canvas.drawLine(
      Offset(cx + bodyWidth * 0.1, bodyTop + bodyHeight * 0.15),
      Offset(cx + bodyWidth * 0.1, bodyTop + bodyHeight * 0.05),
      Paint()
        ..color = GameTheme.playerBackpack
        ..strokeWidth = 1.5 * s,
    );

    // Body
    final bodyPaint = Paint()..color = GameTheme.playerBody;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - bodyWidth / 2,
          bodyTop,
          bodyWidth,
          bodyHeight,
        ),
        Radius.circular(4 * s),
      ),
      bodyPaint,
    );

    // Body highlight (shirt detail)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - bodyWidth / 2 + 1 * s,
          bodyTop + 2 * s,
          bodyWidth * 0.3,
          bodyHeight * 0.7,
        ),
        Radius.circular(3 * s),
      ),
      Paint()..color = GameTheme.playerBodyHighlight.withValues(alpha: 0.3),
    );

    // Arms with swing
    final armPaint = Paint()..color = GameTheme.playerArms;
    // Left arm
    canvas.save();
    canvas.translate(cx - bodyWidth * 0.5, bodyTop + bodyHeight * 0.15);
    canvas.rotate(-armSwing);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-armWidth / 2, 0, armWidth, armLength),
        Radius.circular(2 * s),
      ),
      armPaint,
    );
    canvas.restore();
    // Right arm
    canvas.save();
    canvas.translate(cx + bodyWidth * 0.5, bodyTop + bodyHeight * 0.15);
    canvas.rotate(armSwing);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-armWidth / 2, 0, armWidth, armLength),
        Radius.circular(2 * s),
      ),
      armPaint,
    );
    canvas.restore();

    // Head
    final headCenterY = bodyTop - headRadius * 0.5;
    canvas.drawCircle(
      Offset(cx, headCenterY),
      headRadius,
      Paint()..color = GameTheme.playerHead,
    );

    // Eyes (two small dots)
    final eyeSize = 1.5 * s;
    canvas.drawCircle(
      Offset(cx - headRadius * 0.3, headCenterY - headRadius * 0.1),
      eyeSize,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(cx + headRadius * 0.3, headCenterY - headRadius * 0.1),
      eyeSize,
      Paint()..color = Colors.white,
    );
    // Pupils
    canvas.drawCircle(
      Offset(cx - headRadius * 0.3, headCenterY - headRadius * 0.1),
      eyeSize * 0.5,
      Paint()..color = const Color(0xFF212121),
    );
    canvas.drawCircle(
      Offset(cx + headRadius * 0.3, headCenterY - headRadius * 0.1),
      eyeSize * 0.5,
      Paint()..color = const Color(0xFF212121),
    );

    // Hat/cap
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, headCenterY - headRadius * 0.3),
        width: headRadius * 2.4,
        height: headRadius * 1.0,
      ),
      pi,
      pi,
      true,
      Paint()..color = GameTheme.playerBody,
    );
    // Cap brim
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, headCenterY - headRadius * 0.3),
          width: headRadius * 2.6,
          height: 2.5 * s,
        ),
        Radius.circular(1 * s),
      ),
      Paint()..color = GameTheme.playerLegs,
    );

    // Invulnerability shield glow
    if (isInvulnerable) {
      final shieldAlpha =
          (0.15 + 0.1 * sin(_flashTimer * 2)).clamp(0.0, 0.3);
      final totalH = legLength + bodyHeight + headRadius * 2;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, adjustedBaseY - totalH / 2),
          width: bodyWidth * 2.5,
          height: totalH * 1.2,
        ),
        Paint()
          ..color = GameTheme.hudAccent.withValues(alpha: shieldAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * s,
      );
    }
  }

  bool _tryRenderSprite(Canvas canvas, double cx, double baseY, double s) {
    if (spriteManager == null || !spriteManager!.hasPlayerSprites) return false;

    final sprite = spriteManager!.getPlayerFrame(
      isRunning: !isJumping && !isStunned,
      isJumping: isJumping,
      isHit: isStunned,
      animTime: _runTimer,
    );
    if (sprite == null) return false;

    // Render sprite centered at position, anchored at bottom-center
    final spriteSize = 50 * s;
    sprite.render(
      canvas,
      position: Vector2(cx - spriteSize / 2, baseY - spriteSize),
      size: Vector2(spriteSize, spriteSize),
    );

    // Still show invulnerability shield
    if (isInvulnerable) {
      final shieldAlpha =
          (0.15 + 0.1 * sin(_flashTimer * 2)).clamp(0.0, 0.3);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, baseY - spriteSize / 2),
          width: spriteSize * 1.3,
          height: spriteSize * 1.2,
        ),
        Paint()
          ..color = GameTheme.hudAccent.withValues(alpha: shieldAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * s,
      );
    }

    return true;
  }

  void _renderTrail(Canvas canvas, double s) {
    for (final point in _trail) {
      final alpha = (point.life * 0.15).clamp(0.0, 0.15);
      canvas.drawCircle(
        Offset(point.x, point.y),
        3 * s * point.life,
        Paint()..color = GameTheme.playerTrail.withValues(alpha: alpha),
      );
    }
  }
}

class _TrailPoint {
  double x, y, life;
  _TrailPoint({required this.x, required this.y, required this.life});
}
