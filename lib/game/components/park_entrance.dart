import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../config/game_config.dart';
import '../perspective.dart';

/// Renders the grand park entrance archway and spinning globe water feature.
/// These are fixed-position world landmarks that appear as the player approaches.
class ParkEntrance extends Component {
  final PerspectiveProjection perspective;
  final double Function() getDistanceTraveled;

  double _time = 0;

  // World distances where landmarks are placed
  static const double _globeDistance = 2920.0;
  static const double _archDistance = 2980.0;

  ParkEntrance({
    required this.perspective,
    required this.getDistanceTraveled,
  });

  @override
  int get priority => -50000; // behind obstacles but in front of ground

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final distance = getDistanceTraveled();

    // Only start rendering when approaching
    if (distance < _globeDistance - GameConfig.farPlane) return;

    _renderGlobe(canvas, distance);
    _renderArch(canvas, distance);
  }

  void _renderGlobe(Canvas canvas, double distance) {
    final worldZ = _globeDistance - distance;
    if (worldZ < 1 || worldZ > GameConfig.farPlane) return;

    // Project well to the left of the road
    final projected = perspective.project(-14.0, 0, worldZ);
    if (projected == null) return;

    final scale = projected.scale * 0.08;
    final cx = projected.x;
    final baseY = projected.y;

    if (scale < 0.02) return;

    final globeRadius = 120 * scale;
    final pedestalW = 80 * scale;
    final pedestalH = 35 * scale;
    final globeCenterY = baseY - pedestalH - globeRadius;

    // Water pool at base
    final poolPaint = Paint()
      ..color = const Color(0xFF1565C0).withValues(alpha: 0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseY + 2 * scale),
        width: pedestalW * 2.5,
        height: 14 * scale,
      ),
      poolPaint,
    );

    // Water spray particles
    final sprayPaint = Paint()
      ..color = const Color(0xFF64B5F6).withValues(alpha: 0.5);
    for (int i = 0; i < 8; i++) {
      final angle = (_time * 2 + i * 0.8) % (2 * pi);
      final sprayR = globeRadius * 0.6;
      final sx = cx + cos(angle) * sprayR;
      final sy = baseY - pedestalH * 0.5 +
          sin(angle * 2) * 3 * scale -
          (i % 3) * 2 * scale;
      canvas.drawCircle(Offset(sx, sy), 3 * scale, sprayPaint);
    }

    // Pedestal (3D)
    const pedDark = Color(0xFF757575);
    const pedLight = Color(0xFF9E9E9E);
    const pedFace = Color(0xFF8A8A8A);

    // Pedestal right side
    final pedSideDx = scale * 4;
    final pedSideDy = -scale * 3;
    final pedSidePath = Path()
      ..moveTo(cx + pedestalW / 2, baseY)
      ..lineTo(cx + pedestalW / 2 + pedSideDx, baseY + pedSideDy)
      ..lineTo(cx + pedestalW / 2 + pedSideDx,
          baseY - pedestalH + pedSideDy)
      ..lineTo(cx + pedestalW / 2, baseY - pedestalH)
      ..close();
    canvas.drawPath(pedSidePath, Paint()..color = pedDark);

    // Pedestal top
    final pedTopPath = Path()
      ..moveTo(cx - pedestalW / 2, baseY - pedestalH)
      ..lineTo(
          cx - pedestalW / 2 + pedSideDx, baseY - pedestalH + pedSideDy)
      ..lineTo(
          cx + pedestalW / 2 + pedSideDx, baseY - pedestalH + pedSideDy)
      ..lineTo(cx + pedestalW / 2, baseY - pedestalH)
      ..close();
    canvas.drawPath(pedTopPath, Paint()..color = pedLight);

    // Pedestal front
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, baseY - pedestalH / 2),
        width: pedestalW,
        height: pedestalH,
      ),
      Paint()..color = pedFace,
    );

    // Globe sphere — gradient for 3D effect
    final globeGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      radius: 0.9,
      colors: [
        const Color(0xFF42A5F5),
        const Color(0xFF1565C0),
        const Color(0xFF0D47A1),
      ],
    );
    canvas.drawCircle(
      Offset(cx, globeCenterY),
      globeRadius,
      Paint()
        ..shader = globeGradient.createShader(
          Rect.fromCircle(
              center: Offset(cx, globeCenterY), radius: globeRadius),
        ),
    );

    // Continent shapes (rotating bands)
    final continentPaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.7);
    final rotAngle = _time * 0.4; // slow rotation

    for (int i = 0; i < 5; i++) {
      final bandAngle = rotAngle + i * 1.25;
      final bandX = cx + cos(bandAngle) * globeRadius * 0.6;
      final bandW = globeRadius * 0.35 * (0.5 + 0.5 * cos(bandAngle).abs());
      // Only draw if on the visible hemisphere
      if (cos(bandAngle) > -0.3) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(bandX, globeCenterY - globeRadius * 0.1 +
                i * globeRadius * 0.2 - globeRadius * 0.4),
            width: bandW,
            height: globeRadius * 0.25,
          ),
          continentPaint,
        );
      }
    }

    // Globe highlight
    canvas.drawCircle(
      Offset(cx - globeRadius * 0.25, globeCenterY - globeRadius * 0.25),
      globeRadius * 0.15,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // Label
    if (scale > 0.15) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'WORLD FOUNTAIN',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: (7 * scale).clamp(7, 14),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2,
            baseY - pedestalH - globeRadius * 2 - textPainter.height - 4),
      );
    }
  }

  void _renderArch(Canvas canvas, double distance) {
    final worldZ = _archDistance - distance;
    if (worldZ < 1 || worldZ > GameConfig.farPlane) return;

    final projected = perspective.project(0, 0, worldZ);
    if (projected == null) return;

    final scale = projected.scale * 0.08;
    final baseY = projected.y;
    final screenCenterX = perspective.screenWidth / 2;

    if (scale < 0.02) return;

    final roadHalf = perspective.getRoadHalfWidthAtScreenY(
        baseY, GameConfig.laneWidth * 3);
    final archW = roadHalf * 3.2; // much wider than the road
    final archH = 140 * scale; // very tall
    final pillarW = 16 * scale;
    final depth3D = scale * 14;
    final sideDx = depth3D * 0.6;
    final sideDy = -depth3D * 0.4;

    final leftPillarX = screenCenterX - archW / 2;
    final rightPillarX = screenCenterX + archW / 2;

    const pillarColor = Color(0xFFBFA76A); // golden stone
    const pillarDark = Color(0xFF8B7640);
    const pillarLight = Color(0xFFD4C288);
    const bannerColor = Color(0xFF1B5E20);
    const ornamentColor = Color(0xFFFFD54F);

    // --- Left pillar ---
    // Side face
    final leftSidePath = Path()
      ..moveTo(leftPillarX + pillarW, baseY)
      ..lineTo(leftPillarX + pillarW + sideDx, baseY + sideDy)
      ..lineTo(leftPillarX + pillarW + sideDx, baseY - archH + sideDy)
      ..lineTo(leftPillarX + pillarW, baseY - archH)
      ..close();
    canvas.drawPath(leftSidePath, Paint()..color = pillarDark);
    // Front face
    canvas.drawRect(
      Rect.fromLTWH(leftPillarX, baseY - archH, pillarW, archH),
      Paint()..color = pillarColor,
    );
    // Pillar base (wider)
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(leftPillarX + pillarW / 2, baseY - 3 * scale),
        width: pillarW * 1.5,
        height: 6 * scale,
      ),
      Paint()..color = pillarDark,
    );
    // Pillar capital (wider at top)
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(leftPillarX + pillarW / 2, baseY - archH + 3 * scale),
        width: pillarW * 1.4,
        height: 6 * scale,
      ),
      Paint()..color = pillarLight,
    );

    // --- Right pillar ---
    final rightSidePath = Path()
      ..moveTo(rightPillarX + pillarW, baseY)
      ..lineTo(rightPillarX + pillarW + sideDx, baseY + sideDy)
      ..lineTo(rightPillarX + pillarW + sideDx, baseY - archH + sideDy)
      ..lineTo(rightPillarX + pillarW, baseY - archH)
      ..close();
    canvas.drawPath(rightSidePath, Paint()..color = pillarDark);
    canvas.drawRect(
      Rect.fromLTWH(rightPillarX, baseY - archH, pillarW, archH),
      Paint()..color = pillarColor,
    );
    // Pillar base
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(rightPillarX + pillarW / 2, baseY - 3 * scale),
        width: pillarW * 1.5,
        height: 6 * scale,
      ),
      Paint()..color = pillarDark,
    );
    // Pillar capital
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(
            rightPillarX + pillarW / 2, baseY - archH + 3 * scale),
        width: pillarW * 1.4,
        height: 6 * scale,
      ),
      Paint()..color = pillarLight,
    );

    // --- Top crossbeam (thick, grand) ---
    final beamH = 14 * scale;
    // Top face
    final beamTopPath = Path()
      ..moveTo(leftPillarX, baseY - archH)
      ..lineTo(leftPillarX + sideDx, baseY - archH + sideDy)
      ..lineTo(rightPillarX + pillarW + sideDx, baseY - archH + sideDy)
      ..lineTo(rightPillarX + pillarW, baseY - archH)
      ..close();
    canvas.drawPath(beamTopPath, Paint()..color = pillarLight);
    // Front face
    canvas.drawRect(
      Rect.fromLTWH(
          leftPillarX, baseY - archH, archW + pillarW, beamH),
      Paint()..color = pillarColor,
    );
    // Right side face
    final beamSidePath = Path()
      ..moveTo(rightPillarX + pillarW, baseY - archH)
      ..lineTo(rightPillarX + pillarW + sideDx, baseY - archH + sideDy)
      ..lineTo(rightPillarX + pillarW + sideDx,
          baseY - archH + beamH + sideDy)
      ..lineTo(rightPillarX + pillarW, baseY - archH + beamH)
      ..close();
    canvas.drawPath(beamSidePath, Paint()..color = pillarDark);

    // --- Second decorative beam below ---
    final beam2Y = baseY - archH + beamH + 4 * scale;
    canvas.drawRect(
      Rect.fromLTWH(
          leftPillarX, beam2Y, archW + pillarW, 3 * scale),
      Paint()..color = pillarDark,
    );

    // --- Grand arch curve ---
    final archPaint = Paint()
      ..color = pillarDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * scale;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(screenCenterX, baseY - archH + beamH + 4 * scale),
        width: archW - pillarW * 2,
        height: archH * 0.6,
      ),
      pi,
      pi,
      false,
      archPaint,
    );

    // --- Inner arch (thinner, decorative) ---
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(screenCenterX, baseY - archH + beamH + 4 * scale),
        width: archW - pillarW * 4,
        height: archH * 0.45,
      ),
      pi,
      pi,
      false,
      Paint()
        ..color = ornamentColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale,
    );

    // --- Green banner ---
    final bannerTop = baseY - archH + beamH;
    final bannerH = 18 * scale;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center:
              Offset(screenCenterX, bannerTop + bannerH / 2 + 10 * scale),
          width: archW * 0.55,
          height: bannerH,
        ),
        Radius.circular(3 * scale),
      ),
      Paint()..color = bannerColor,
    );
    // Banner border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center:
              Offset(screenCenterX, bannerTop + bannerH / 2 + 10 * scale),
          width: archW * 0.55,
          height: bannerH,
        ),
        Radius.circular(3 * scale),
      ),
      Paint()
        ..color = ornamentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale,
    );

    // Park name on banner
    if (scale > 0.1) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'WELCOME TO THE PARK',
          style: TextStyle(
            color: ornamentColor,
            fontSize: (9 * scale).clamp(6, 22),
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(screenCenterX - textPainter.width / 2,
            bannerTop + bannerH / 2 + 10 * scale - textPainter.height / 2),
      );
    }

    // --- Finials (larger, ornate) ---
    final finialPaint = Paint()..color = ornamentColor;
    // Left finial — diamond shape
    final leftFinialCx = leftPillarX + pillarW / 2;
    final finialY = baseY - archH - 6 * scale;
    canvas.drawPath(
      Path()
        ..moveTo(leftFinialCx, finialY - 6 * scale)
        ..lineTo(leftFinialCx - 4 * scale, finialY)
        ..lineTo(leftFinialCx, finialY + 4 * scale)
        ..lineTo(leftFinialCx + 4 * scale, finialY)
        ..close(),
      finialPaint,
    );
    // Right finial
    final rightFinialCx = rightPillarX + pillarW / 2;
    canvas.drawPath(
      Path()
        ..moveTo(rightFinialCx, finialY - 6 * scale)
        ..lineTo(rightFinialCx - 4 * scale, finialY)
        ..lineTo(rightFinialCx, finialY + 4 * scale)
        ..lineTo(rightFinialCx + 4 * scale, finialY)
        ..close(),
      finialPaint,
    );

    // --- Center crown ornament ---
    final crownY = baseY - archH - 8 * scale;
    canvas.drawPath(
      Path()
        ..moveTo(screenCenterX - 8 * scale, crownY + 5 * scale)
        ..lineTo(screenCenterX - 6 * scale, crownY - 3 * scale)
        ..lineTo(screenCenterX - 2 * scale, crownY + 2 * scale)
        ..lineTo(screenCenterX, crownY - 5 * scale)
        ..lineTo(screenCenterX + 2 * scale, crownY + 2 * scale)
        ..lineTo(screenCenterX + 6 * scale, crownY - 3 * scale)
        ..lineTo(screenCenterX + 8 * scale, crownY + 5 * scale)
        ..close(),
      finialPaint,
    );
  }
}
