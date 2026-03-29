import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../config/game_config.dart';
import '../obstacles/obstacle_data.dart';
import '../perspective.dart';
import '../sprites/sprite_manager.dart';

Color _darken(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
      .toColor();
}

Color _lighten(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
      .toColor();
}

/// A single obstacle in the game world.
class ObstacleComponent extends Component {
  final ObstacleData data;
  final int lane; // -1, 0, 1
  double worldZ;
  final PerspectiveProjection perspective;
  final SpriteManager? spriteManager;

  /// For securityGate: which lane is walled off (-1, 0, or 1).
  /// The other two lanes have doorways. Null for all other obstacle types.
  final int? blockedLane;

  ObstacleComponent({
    required this.data,
    required this.lane,
    required this.worldZ,
    required this.perspective,
    this.blockedLane,
    this.spriteManager,
  });

  double get worldX => lane * GameConfig.laneWidth;

  bool get isPastCamera => worldZ < GameConfig.nearPlane;

  @override
  int get priority => -(worldZ * 10).toInt();

  void advance(double distance) {
    worldZ -= distance;
  }

  /// Draw a 3D box with top and right side faces.
  void _draw3DBox(
    Canvas canvas, {
    required double cx,
    required double baseY,
    required double w,
    required double h,
    required double depth,
    required Color faceColor,
    double radius = 0,
  }) {
    final sideDx = depth * 0.6;
    final sideDy = -depth * 0.4;

    // Right side face
    final sidePath = Path()
      ..moveTo(cx + w / 2, baseY)
      ..lineTo(cx + w / 2 + sideDx, baseY + sideDy)
      ..lineTo(cx + w / 2 + sideDx, baseY - h + sideDy)
      ..lineTo(cx + w / 2, baseY - h)
      ..close();
    canvas.drawPath(sidePath, Paint()..color = _darken(faceColor, 0.2));

    // Top face
    final topPath = Path()
      ..moveTo(cx - w / 2, baseY - h)
      ..lineTo(cx - w / 2 + sideDx, baseY - h + sideDy)
      ..lineTo(cx + w / 2 + sideDx, baseY - h + sideDy)
      ..lineTo(cx + w / 2, baseY - h)
      ..close();
    canvas.drawPath(topPath, Paint()..color = _lighten(faceColor, 0.15));

    // Front face
    if (radius > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, baseY - h / 2),
            width: w,
            height: h,
          ),
          Radius.circular(radius),
        ),
        Paint()..color = faceColor,
      );
    } else {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(cx, baseY - h / 2),
          width: w,
          height: h,
        ),
        Paint()..color = faceColor,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final projected = perspective.project(worldX, 0, worldZ);
    if (projected == null) return;
    if (worldZ > GameConfig.farPlane) return;

    final scale = projected.scale * 0.08;
    final cx = projected.x;
    final baseY = projected.y;

    final w = data.width * scale * 15;
    final h = data.height * scale * 15;
    final depth3D = scale * 8; // 3D depth offset

    // For obstacles spanning all lanes, compute the full road width
    double renderW = w;
    double renderCx = cx;
    if (data.spansAllLanes) {
      final roadHalf = perspective.getRoadHalfWidthAtScreenY(
          baseY, GameConfig.laneWidth * 3);
      renderW = roadHalf * 2;
      renderCx = perspective.screenWidth / 2;
    }

    // Try sprite rendering first
    if (_tryRenderSprite(canvas, cx, baseY, w, h, scale, renderW, renderCx)) {
      return;
    }

    // Fallback: procedural rendering
    switch (data.type) {
      case ObstacleType.car:
        _draw3DBox(
          canvas,
          cx: cx,
          baseY: baseY,
          w: w,
          h: h,
          depth: depth3D,
          faceColor: data.color,
          radius: 3 * scale,
        );
        // Windshield on front face
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, baseY - h * 0.6),
              width: w * 0.6,
              height: h * 0.3,
            ),
            Radius.circular(2 * scale),
          ),
          Paint()..color = const Color(0xFF81D4FA),
        );
        // Wheels
        final wheelPaint = Paint()..color = data.accentColor;
        canvas.drawCircle(
            Offset(cx - w * 0.35, baseY), 3 * scale, wheelPaint);
        canvas.drawCircle(
            Offset(cx + w * 0.35, baseY), 3 * scale, wheelPaint);
        break;

      case ObstacleType.shoppingCart:
        _draw3DBox(
          canvas,
          cx: cx,
          baseY: baseY,
          w: w,
          h: h,
          depth: depth3D * 0.7,
          faceColor: data.color,
          radius: 2 * scale,
        );
        // Handle
        canvas.drawLine(
          Offset(cx - w * 0.3, baseY - h * 0.8),
          Offset(cx + w * 0.3, baseY - h * 0.8),
          Paint()
            ..color = data.accentColor
            ..strokeWidth = 2 * scale,
        );
        // Wheels
        final cartWheelPaint = Paint()..color = data.accentColor;
        canvas.drawCircle(
            Offset(cx - w * 0.25, baseY), 2 * scale, cartWheelPaint);
        canvas.drawCircle(
            Offset(cx + w * 0.25, baseY), 2 * scale, cartWheelPaint);
        break;

      case ObstacleType.speedBump:
        // Low profile 3D bump spanning full road
        _draw3DBox(
          canvas,
          cx: renderCx,
          baseY: baseY,
          w: renderW,
          h: data.height * scale * 15,
          depth: depth3D * 0.4,
          faceColor: data.color,
        );
        // Stripes across full width
        final stripePaint = Paint()
          ..color = data.accentColor
          ..strokeWidth = 2 * scale;
        for (double x = renderCx - renderW * 0.45;
            x < renderCx + renderW * 0.45;
            x += 6 * scale) {
          canvas.drawLine(
            Offset(x, baseY - data.height * scale * 15),
            Offset(x, baseY),
            stripePaint,
          );
        }
        break;

      case ObstacleType.barricade:
        _draw3DBox(
          canvas,
          cx: cx,
          baseY: baseY,
          w: w,
          h: h,
          depth: depth3D * 0.5,
          faceColor: data.color,
          radius: 2 * scale,
        );
        // White stripe
        canvas.drawLine(
          Offset(cx - w * 0.4, baseY - h * 0.5),
          Offset(cx + w * 0.4, baseY - h * 0.5),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2 * scale,
        );
        break;

      case ObstacleType.metalDetector:
        _draw3DBox(
          canvas,
          cx: cx,
          baseY: baseY,
          w: w,
          h: h,
          depth: depth3D,
          faceColor: data.color,
        );
        // Arch opening
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(cx, baseY - h * 0.3),
            width: w * 0.5,
            height: h * 0.6,
          ),
          Paint()..color = const Color(0xFF263238),
        );
        // Green light
        canvas.drawCircle(
          Offset(cx + w * 0.35, baseY - h * 0.8),
          3 * scale,
          Paint()..color = data.accentColor,
        );
        break;

      case ObstacleType.bagCheckStation:
        _draw3DBox(
          canvas,
          cx: cx,
          baseY: baseY,
          w: w,
          h: h,
          depth: depth3D * 0.8,
          faceColor: data.color,
        );
        // Table top accent
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(cx, baseY - h * 0.7),
            width: w * 0.9,
            height: h * 0.15,
          ),
          Paint()..color = data.accentColor,
        );
        break;

      case ObstacleType.securityGate:
        _renderSecurityGate(canvas, renderCx, baseY, renderW, h, scale,
            depth3D);
        break;

      case ObstacleType.merchandiseRack:
        _draw3DBox(
          canvas,
          cx: cx,
          baseY: baseY,
          w: w,
          h: h,
          depth: depth3D,
          faceColor: data.color,
        );
        // Shelves on front face
        for (int i = 0; i < 3; i++) {
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(cx, baseY - h * (0.25 + i * 0.25)),
              width: w * 0.85,
              height: 1.5 * scale,
            ),
            Paint()..color = data.accentColor,
          );
        }
        break;

      case ObstacleType.foodCart:
        _draw3DBox(
          canvas,
          cx: cx,
          baseY: baseY,
          w: w,
          h: h,
          depth: depth3D * 0.7,
          faceColor: data.color,
          radius: 2 * scale,
        );
        // Umbrella on top
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx, baseY - h * 0.85),
            width: w * 1.2,
            height: h * 0.4,
          ),
          3.14,
          3.14,
          true,
          Paint()..color = const Color(0xFFFF7043),
        );
        break;

      case ObstacleType.bench:
        // Low profile bench spanning full road
        _draw3DBox(
          canvas,
          cx: renderCx,
          baseY: baseY,
          w: renderW,
          h: data.height * scale * 15,
          depth: depth3D * 0.5,
          faceColor: data.color,
        );
        // Seat surface
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(
                renderCx, baseY - data.height * scale * 15 * 0.5),
            width: renderW * 0.9,
            height: data.height * scale * 15 * 0.4,
          ),
          Paint()..color = data.accentColor,
        );
        break;

      case ObstacleType.ropeLine:
        // Posts are 3D
        final postW = 4 * scale;
        final postH = h * 2;
        // Left post
        _draw3DBox(
          canvas,
          cx: renderCx - renderW * 0.45,
          baseY: baseY,
          w: postW,
          h: postH,
          depth: depth3D * 0.3,
          faceColor: data.accentColor,
        );
        // Right post
        _draw3DBox(
          canvas,
          cx: renderCx + renderW * 0.45,
          baseY: baseY,
          w: postW,
          h: postH,
          depth: depth3D * 0.3,
          faceColor: data.accentColor,
        );
        // Rope between posts
        canvas.drawLine(
          Offset(renderCx - renderW * 0.45, baseY - postH * 0.75),
          Offset(renderCx + renderW * 0.45, baseY - postH * 0.6),
          Paint()
            ..color = data.color
            ..strokeWidth = 2.5 * scale,
        );
        break;

      case ObstacleType.turnstile:
        _draw3DBox(
          canvas,
          cx: cx,
          baseY: baseY,
          w: w,
          h: h,
          depth: depth3D * 0.6,
          faceColor: data.color,
        );
        // Rotating bar
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(cx, baseY - h * 0.5),
            width: w * 0.8,
            height: 3 * scale,
          ),
          Paint()..color = data.accentColor,
        );
        // Post
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(cx, baseY - h * 0.25),
            width: 4 * scale,
            height: h * 0.5,
          ),
          Paint()..color = data.accentColor,
        );
        break;

      case ObstacleType.ticketKiosk:
        _draw3DBox(
          canvas,
          cx: cx,
          baseY: baseY,
          w: w,
          h: h,
          depth: depth3D,
          faceColor: data.color,
          radius: 2 * scale,
        );
        // Screen
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, baseY - h * 0.6),
              width: w * 0.5,
              height: h * 0.3,
            ),
            Radius.circular(2 * scale),
          ),
          Paint()..color = data.accentColor,
        );
        break;
    }

    // Label (only show when close enough)
    if (scale > 0.25) {
      final labelY = baseY - h - 4;
      final textPainter = TextPainter(
        text: TextSpan(
          text: data.label,
          style: TextStyle(
            color: Colors.white,
            fontSize: (8 * scale).clamp(8, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
            (data.spansAllLanes ? renderCx : cx) - textPainter.width / 2,
            labelY - textPainter.height),
      );
    }
  }

  /// Attempt to render using a sprite asset. Returns true if sprite was rendered.
  bool _tryRenderSprite(Canvas canvas, double cx, double baseY, double w,
      double h, double scale, double renderW, double renderCx) {
    if (spriteManager == null) return false;
    if (data.spriteAssetName.isEmpty) return false;

    // Security gate is complex (multi-lane), skip sprite for now unless
    // a dedicated sprite exists
    if (data.type == ObstacleType.securityGate) {
      // For security gate, we'd need separate blocked/open lane sprites
      // Fall back to procedural for now
      return false;
    }

    final sprite = spriteManager!.getObstacleSprite(data.spriteAssetName);
    if (sprite == null) return false;

    // Determine render size and position
    final spriteW = data.spansAllLanes ? renderW : w;
    final spriteCx = data.spansAllLanes ? renderCx : cx;

    // Render sprite anchored at bottom-center
    sprite.render(
      canvas,
      position: Vector2(spriteCx - spriteW / 2, baseY - h),
      size: Vector2(spriteW, h),
    );

    // Still show label when close
    if (scale > 0.25) {
      final labelY = baseY - h - 4;
      final textPainter = TextPainter(
        text: TextSpan(
          text: data.label,
          style: TextStyle(
            color: Colors.white,
            fontSize: (8 * scale).clamp(8, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(spriteCx - textPainter.width / 2,
            labelY - textPainter.height),
      );
    }

    return true;
  }

  void _renderSecurityGate(Canvas canvas, double renderCx, double baseY,
      double renderW, double h, double scale, double depth3D) {
    final blocked = blockedLane ?? 0;
    final laneScale = perspective.getScale(worldZ) * 0.08;
    final laneW = GameConfig.laneWidth * laneScale * 15;
    final screenCenterX = perspective.screenWidth / 2;

    // Gate is extra tall — player can clearly see jumping won't work
    final gateH = h * 1.8;

    for (int ln = -1; ln <= 1; ln++) {
      final laneCx = screenCenterX + ln * laneW;

      if (ln == blocked) {
        // Solid wall — can't pass
        _draw3DBox(canvas,
            cx: laneCx,
            baseY: baseY,
            w: laneW,
            h: gateH,
            depth: depth3D,
            faceColor: data.color);

        // Red X to show blocked
        final xPaint = Paint()
          ..color = const Color(0xFFD32F2F)
          ..strokeWidth = 2.5 * scale;
        canvas.drawLine(
          Offset(laneCx - laneW * 0.3, baseY - gateH * 0.15),
          Offset(laneCx + laneW * 0.3, baseY - gateH * 0.85),
          xPaint,
        );
        canvas.drawLine(
          Offset(laneCx + laneW * 0.3, baseY - gateH * 0.15),
          Offset(laneCx - laneW * 0.3, baseY - gateH * 0.85),
          xPaint,
        );

        // "NO ENTRY" stripe
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(laneCx, baseY - gateH * 0.5),
            width: laneW * 0.7,
            height: 3 * scale,
          ),
          Paint()..color = const Color(0xFFD32F2F),
        );
      } else {
        // Doorway frame — passable lane
        final postW = laneW * 0.12;

        // Left post
        _draw3DBox(canvas,
            cx: laneCx - laneW * 0.45,
            baseY: baseY,
            w: postW,
            h: gateH,
            depth: depth3D,
            faceColor: data.color);

        // Right post
        _draw3DBox(canvas,
            cx: laneCx + laneW * 0.45,
            baseY: baseY,
            w: postW,
            h: gateH,
            depth: depth3D,
            faceColor: data.color);

        // Lintel across top of doorway
        final lintelH = gateH * 0.15;
        _draw3DBox(canvas,
            cx: laneCx,
            baseY: baseY - gateH + lintelH,
            w: laneW,
            h: lintelH,
            depth: depth3D,
            faceColor: _darken(data.color, 0.1));

        // Green arrow pointing down into doorway
        final arrowY = baseY - gateH - 4 * scale;
        final arrowPaint = Paint()..color = data.accentColor;
        final arrowPath = Path()
          ..moveTo(laneCx, arrowY + 8 * scale)
          ..lineTo(laneCx - 5 * scale, arrowY)
          ..lineTo(laneCx + 5 * scale, arrowY)
          ..close();
        canvas.drawPath(arrowPath, arrowPaint);
      }
    }

    // Top beam connecting all three sections
    final totalW = laneW * 3;
    final beamH = gateH * 0.08;
    _draw3DBox(canvas,
        cx: screenCenterX,
        baseY: baseY - gateH,
        w: totalW,
        h: beamH,
        depth: depth3D,
        faceColor: _lighten(data.color, 0.1));
  }
}
