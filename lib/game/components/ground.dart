import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../config/game_config.dart';
import '../../config/theme.dart';
import '../perspective.dart';
import '../zones/zone_manager.dart';

/// Renders the perspective ground, road, lane markers, sky, clouds, and scenery.
class Ground extends Component {
  final PerspectiveProjection perspective;
  final ZoneManager zoneManager;
  final double Function() getDistanceTraveled;

  double _walkwayOffset = 0;
  double _time = 0;
  final List<_Cloud> _clouds = [];
  final List<_SceneryItem> _scenery = [];
  final Random _random = Random();

  Ground({
    required this.perspective,
    required this.zoneManager,
    required this.getDistanceTraveled,
  }) {
    // Generate clouds
    for (int i = 0; i < 8; i++) {
      _clouds.add(_Cloud(
        x: _random.nextDouble(),
        y: 0.02 + _random.nextDouble() * 0.12,
        width: 60 + _random.nextDouble() * 120,
        height: 15 + _random.nextDouble() * 25,
        speed: 0.003 + _random.nextDouble() * 0.008,
        opacity: 0.03 + _random.nextDouble() * 0.06,
      ));
    }

    // Generate side scenery (trees, lamps, etc.) at regular intervals
    for (int i = 0; i < 60; i++) {
      final worldZ = 10.0 + i * 15.0;
      final side = (i % 2 == 0) ? -1.0 : 1.0;
      final type = i % 5 == 0
          ? _SceneryType.lamp
          : (i % 3 == 0 ? _SceneryType.bush : _SceneryType.tree);
      _scenery.add(_SceneryItem(
        worldZ: worldZ,
        side: side,
        type: type,
        scale: 0.7 + _random.nextDouble() * 0.6,
      ));
    }
  }

  @override
  int get priority => -100000;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    final zone = zoneManager.currentZone;
    if (zone.isWalkway) {
      final dir = zone.reversesDirection ? -1.0 : 1.0;
      _walkwayOffset += dir * dt * 60;
    }
  }

  @override
  void render(Canvas canvas) {
    final w = perspective.screenWidth;
    final h = perspective.screenHeight;
    final horizonY = perspective.horizonY;
    final distance = getDistanceTraveled();

    _renderSky(canvas, w, horizonY);
    _renderClouds(canvas, w, horizonY);
    _renderGround(canvas, w, h, horizonY, distance);
    _renderScenery(canvas, distance);
    _renderZoneBanner(canvas, w, horizonY);
  }

  void _renderSky(Canvas canvas, double w, double horizonY) {
    // Rich gradient sky with horizon glow
    final skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, horizonY),
        [
          GameTheme.skyTop,
          GameTheme.skyMid,
          GameTheme.skyBottom,
          GameTheme.horizonGlow.withValues(alpha: 0.15),
        ],
        [0.0, 0.4, 0.85, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, horizonY), skyPaint);

    // Stars (subtle)
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 30; i++) {
      final sx = (i * 137.5 + _time * 0.5) % w;
      final sy = (i * 89.3) % (horizonY * 0.7);
      final twinkle = (sin(_time * 2 + i * 0.7) * 0.5 + 0.5);
      starPaint.color = Colors.white.withValues(alpha: twinkle * 0.4);
      canvas.drawCircle(Offset(sx, sy), 0.5 + twinkle * 0.5, starPaint);
    }
  }

  void _renderClouds(Canvas canvas, double w, double horizonY) {
    for (final cloud in _clouds) {
      final cx = ((cloud.x + _time * cloud.speed) % 1.3 - 0.15) * w;
      final cy = cloud.y * horizonY;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: cloud.opacity);

      // Multi-ellipse cloud
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: cloud.width,
          height: cloud.height,
        ),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - cloud.width * 0.3, cy + 2),
          width: cloud.width * 0.6,
          height: cloud.height * 0.8,
        ),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + cloud.width * 0.25, cy - 1),
          width: cloud.width * 0.5,
          height: cloud.height * 0.7,
        ),
        paint,
      );
    }
  }

  void _renderGround(Canvas canvas, double w, double h, double horizonY,
      double distance) {
    const roadWorldWidth = GameConfig.laneWidth * 3;
    final centerX = w / 2;

    for (double y = horizonY; y < h; y += 1.0) {
      final z = perspective.screenYToWorldZ(y);
      if (z == double.infinity || z < 0) continue;

      final zoneAtDepth = zoneManager.getZoneAtDistance(distance + z);

      // Ground with subtle gradient based on distance
      final depthFactor = ((y - horizonY) / (h - horizonY)).clamp(0.0, 1.0);
      final groundColor = Color.lerp(
        zoneAtDepth.groundColor.withValues(alpha: 0.6),
        zoneAtDepth.groundColor,
        depthFactor,
      )!;
      canvas.drawLine(
          Offset(0, y), Offset(w, y), Paint()..color = groundColor);

      // Road surface
      final roadHalf =
          perspective.getRoadHalfWidthAtScreenY(y, roadWorldWidth);
      final roadPaint = Paint()..color = zoneAtDepth.roadColor;
      canvas.drawLine(
        Offset(centerX - roadHalf, y),
        Offset(centerX + roadHalf, y),
        roadPaint,
      );

      // Road edge glow
      final edgeGlowAlpha = (0.15 * depthFactor).clamp(0.0, 0.15);
      final edgeGlowPaint = Paint()
        ..color = GameTheme.hudAccent.withValues(alpha: edgeGlowAlpha);
      canvas.drawLine(
        Offset(centerX - roadHalf - 1, y),
        Offset(centerX - roadHalf + 1, y),
        edgeGlowPaint,
      );
      canvas.drawLine(
        Offset(centerX + roadHalf - 1, y),
        Offset(centerX + roadHalf + 1, y),
        edgeGlowPaint,
      );

      // Walkway stripes
      if (zoneAtDepth.isWalkway) {
        final stripeZ = (z + _walkwayOffset) % 20;
        if (stripeZ < 3) {
          final stripePaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.2);
          canvas.drawLine(
            Offset(centerX - roadHalf, y),
            Offset(centerX + roadHalf, y),
            stripePaint,
          );
        }
      }

      // Lane markers (dashed)
      final laneScale = perspective.getScale(z);
      final laneSpacing = GameConfig.laneWidth * laneScale;
      final markerPaint = Paint()
        ..color = GameTheme.laneMarker.withValues(alpha: 0.5 * depthFactor)
        ..strokeWidth = (1.5 * laneScale).clamp(0.5, 3.0);

      final dashZ = (z + distance * 0.5) % 8;
      if (dashZ < 4) {
        canvas.drawLine(
          Offset(centerX - laneSpacing / 3, y),
          Offset(centerX - laneSpacing / 3, y),
          markerPaint,
        );
        canvas.drawLine(
          Offset(centerX + laneSpacing / 3, y),
          Offset(centerX + laneSpacing / 3, y),
          markerPaint,
        );
      }

      // Road edge lines
      final edgePaint = Paint()
        ..color = GameTheme.roadEdge.withValues(alpha: 0.4 * depthFactor)
        ..strokeWidth = (1.5 * laneScale).clamp(0.5, 4.0);
      canvas.drawLine(
        Offset(centerX - roadHalf, y),
        Offset(centerX - roadHalf, y),
        edgePaint,
      );
      canvas.drawLine(
        Offset(centerX + roadHalf, y),
        Offset(centerX + roadHalf, y),
        edgePaint,
      );
    }
  }

  void _renderScenery(Canvas canvas, double distance) {
    const roadWorldWidth = GameConfig.laneWidth * 3;
    final sceneryOffset = distance % (_scenery.length * 15.0);

    for (final item in _scenery) {
      final adjustedZ =
          ((item.worldZ - sceneryOffset) % (_scenery.length * 15.0));
      if (adjustedZ < GameConfig.nearPlane || adjustedZ > GameConfig.farPlane) {
        continue;
      }

      final sideOffset = item.side * (roadWorldWidth * 0.8 + 2.0);
      final projected = perspective.project(sideOffset, 0, adjustedZ);
      if (projected == null) continue;

      final scale = projected.scale * 0.08 * item.scale;
      if (scale < 0.03) continue;

      final cx = projected.x;
      final baseY = projected.y;

      switch (item.type) {
        case _SceneryType.tree:
          _renderTree(canvas, cx, baseY, scale);
          break;
        case _SceneryType.lamp:
          _renderLamp(canvas, cx, baseY, scale);
          break;
        case _SceneryType.bush:
          _renderBush(canvas, cx, baseY, scale);
          break;
      }
    }
  }

  void _renderTree(Canvas canvas, double cx, double baseY, double scale) {
    final trunkW = 6 * scale;
    final trunkH = 30 * scale;
    final canopyR = 18 * scale;

    // Trunk
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, baseY - trunkH / 2),
          width: trunkW,
          height: trunkH,
        ),
        Radius.circular(2 * scale),
      ),
      Paint()..color = GameTheme.treeTrunk,
    );

    // Canopy layers
    final canopyY = baseY - trunkH - canopyR * 0.5;
    canvas.drawCircle(
      Offset(cx, canopyY),
      canopyR,
      Paint()..color = GameTheme.treeLeaves,
    );
    canvas.drawCircle(
      Offset(cx - canopyR * 0.3, canopyY - canopyR * 0.3),
      canopyR * 0.7,
      Paint()..color = GameTheme.treeLeavesLight,
    );
    // Highlight
    canvas.drawCircle(
      Offset(cx - canopyR * 0.2, canopyY - canopyR * 0.4),
      canopyR * 0.3,
      Paint()..color = GameTheme.treeLeavesLight.withValues(alpha: 0.5),
    );
  }

  void _renderLamp(Canvas canvas, double cx, double baseY, double scale) {
    final postW = 3 * scale;
    final postH = 45 * scale;
    final lampR = 5 * scale;

    // Post
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, baseY - postH / 2),
        width: postW,
        height: postH,
      ),
      Paint()..color = GameTheme.lampPost,
    );

    // Lamp head
    canvas.drawCircle(
      Offset(cx, baseY - postH),
      lampR,
      Paint()..color = GameTheme.lampGlow,
    );

    // Glow effect
    final glowBrightness = 0.5 + 0.2 * sin(_time * 3);
    canvas.drawCircle(
      Offset(cx, baseY - postH),
      lampR * 4,
      Paint()..color = GameTheme.lampGlow.withValues(alpha: 0.05 * glowBrightness),
    );
    canvas.drawCircle(
      Offset(cx, baseY - postH),
      lampR * 2,
      Paint()..color = GameTheme.lampGlow.withValues(alpha: 0.1 * glowBrightness),
    );
  }

  void _renderBush(Canvas canvas, double cx, double baseY, double scale) {
    final bushW = 14 * scale;
    final bushH = 10 * scale;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseY - bushH / 2),
        width: bushW,
        height: bushH,
      ),
      Paint()..color = GameTheme.treeLeaves.withValues(alpha: 0.8),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + bushW * 0.25, baseY - bushH * 0.6),
        width: bushW * 0.6,
        height: bushH * 0.7,
      ),
      Paint()..color = GameTheme.treeLeavesLight.withValues(alpha: 0.6),
    );
  }

  void _renderZoneBanner(Canvas canvas, double w, double horizonY) {
    final zone = zoneManager.currentZone;
    final textPainter = TextPainter(
      text: TextSpan(
        text: zone.name.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 6,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((w - textPainter.width) / 2, horizonY + 5),
    );
  }
}

class _Cloud {
  double x, y, width, height, speed, opacity;
  _Cloud({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.speed,
    required this.opacity,
  });
}

enum _SceneryType { tree, lamp, bush }

class _SceneryItem {
  final double worldZ;
  final double side; // -1 or 1
  final _SceneryType type;
  final double scale;

  _SceneryItem({
    required this.worldZ,
    required this.side,
    required this.type,
    required this.scale,
  });
}
